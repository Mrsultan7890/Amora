import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'dart:convert';
import 'location_service.dart';
import 'sms_service.dart';
import 'emergency_voice_service.dart';
import '../../shared/models/emergency_contact_model.dart';

class OfflineEmergencyService {
  static OfflineEmergencyService? _instance;
  static OfflineEmergencyService get instance => _instance ??= OfflineEmergencyService._();
  
  OfflineEmergencyService._();
  
  static const String _contactsKey = 'emergency_contacts';
  static const String _enabledKey = 'offline_emergency_enabled';
  static const String _callTimeoutKey = 'emergency_call_timeout';
  static const String _autoSmsKey = 'emergency_auto_sms';
  
  List<EmergencyContact> _contacts = [];
  bool _isEnabled = true;
  int _callTimeout = 30; // seconds
  bool _autoSmsEnabled = true;
  bool _isEmergencyActive = false;
  
  Future<void> initialize() async {
    await _loadSettings();
    await _loadContacts();
  }
  
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isEnabled = prefs.getBool(_enabledKey) ?? true;
    _callTimeout = prefs.getInt(_callTimeoutKey) ?? 30;
    _autoSmsEnabled = prefs.getBool(_autoSmsKey) ?? true;
  }
  
  Future<void> _loadContacts() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Load contacts from storage only
    final contactsJson = prefs.getString(_contactsKey);
    if (contactsJson != null && contactsJson.isNotEmpty) {
      try {
        final List<dynamic> contactsList = jsonDecode(contactsJson);
        _contacts = contactsList.map((json) => EmergencyContact.fromJson(json)).toList();
      } catch (e) {
        _contacts = [];
      }
    } else {
      _contacts = [];
    }
  }
  
  Future<void> _saveContacts() async {
    final prefs = await SharedPreferences.getInstance();
    final contactsJson = jsonEncode(_contacts.map((c) => c.toJson()).toList());
    await prefs.setString(_contactsKey, contactsJson);
  }
  
  // Getters
  List<EmergencyContact> get contacts => List.unmodifiable(_contacts);
  bool get isEnabled => _isEnabled;
  int get callTimeout => _callTimeout;
  bool get autoSmsEnabled => _autoSmsEnabled;
  bool get isEmergencyActive => _isEmergencyActive;
  
  // Settings
  Future<void> setEnabled(bool enabled) async {
    _isEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enabledKey, enabled);
  }
  
  Future<void> setCallTimeout(int seconds) async {
    _callTimeout = seconds;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_callTimeoutKey, seconds);
  }
  
  Future<void> setAutoSmsEnabled(bool enabled) async {
    _autoSmsEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoSmsKey, enabled);
  }
  
  // Contact management
  Future<void> addContact(EmergencyContact contact) async {
    _contacts.add(contact);
    await _saveContacts();
  }
  
  Future<void> updateContact(EmergencyContact contact) async {
    final index = _contacts.indexWhere((c) => c.id == contact.id);
    if (index != -1) {
      _contacts[index] = contact;
      await _saveContacts();
    }
  }
  
  Future<void> removeContact(String contactId) async {
    _contacts.removeWhere((c) => c.id == contactId);
    await _saveContacts();
  }
  
  // Main emergency trigger
  Future<void> triggerOfflineEmergency() async {
    if (!_isEnabled || _isEmergencyActive) {
      return;
    }
    
    _isEmergencyActive = true;
    
    try {
      // Get current location
      final location = await LocationService.instance.getCurrentLocation();
      
      // Send SMS to all contacts first (faster)
      if (_autoSmsEnabled) {
        await _sendEmergencySMS(location?.latitude, location?.longitude);
      }
      
      // Then start call sequence
      await _startEmergencyCallSequence();
      
      // Trigger alarm and flash
      await _triggerAlarmAndFlash();
      
      // Store emergency locally
      await _storeEmergencyLocally(location?.latitude, location?.longitude);
      
    } catch (e) {
      // Continue even if some parts fail
    } finally {
      // Reset after 2 minutes to allow for multiple emergency attempts if needed
      Timer(const Duration(minutes: 2), () {
        _isEmergencyActive = false;
      });
    }
  }
  
  Future<void> _sendEmergencySMS(double? latitude, double? longitude) async {
    final enabledContacts = _contacts.where((c) => c.isEnabled).toList();
    
    if (enabledContacts.isEmpty) return;
    
    String locationText = '';
    if (latitude != null && longitude != null) {
      locationText = '\nLocation: https://maps.google.com/?q=$latitude,$longitude';
    }
    
    // Check if voice message exists
    final voiceService = EmergencyVoiceService.instance;
    String voiceInfo = '';
    
    if (voiceService.hasRecording) {
      final duration = await voiceService.getRecordingDuration();
      voiceInfo = '\n🎤 Voice message: ${duration}s - Will call you to play it';
    }
    
    final message = 'EMERGENCY ALERT\nI need immediate help!$locationText$voiceInfo\nTime: ${DateTime.now().toString().substring(0, 19)}\n- Amora Emergency';
    
    // Send SMS to all contacts
    for (final contact in enabledContacts) {
      try {
        await SmsService.sendSms(contact.phoneNumber, message);
        print('✅ SMS sent to ${contact.name}');
        await Future.delayed(const Duration(milliseconds: 500));
      } catch (e) {
        print('❌ Failed to send SMS to ${contact.name}: $e');
      }
    }
  }
  
  Future<void> _startEmergencyCallSequence() async {
    final enabledContacts = _contacts.where((c) => c.isEnabled).toList();
    final voiceService = EmergencyVoiceService.instance;
    
    if (enabledContacts.isEmpty) return;
    
    // Make automatic calls to all contacts
    for (int i = 0; i < enabledContacts.length; i++) {
      final contact = enabledContacts[i];
      try {
        print('📞 Calling ${contact.name}...');
        bool callMade = await SmsService.makeCall(contact.phoneNumber);
        
        if (callMade) {
          print('✅ Call initiated to ${contact.name}');
          
          // If voice message exists, play it during call
          if (voiceService.hasRecording) {
            // Wait 3 seconds for call to connect, then play voice message
            await Future.delayed(const Duration(seconds: 3));
            try {
              await voiceService.playRecording();
              print('🎤 Playing voice message during call to ${contact.name}');
            } catch (e) {
              print('❌ Failed to play voice during call: $e');
            }
          }
          
          // Wait 15 seconds before next call
          if (i < enabledContacts.length - 1) {
            await Future.delayed(const Duration(seconds: 15));
          }
        }
      } catch (e) {
        print('❌ Call failed to ${contact.name}: $e');
      }
    }
  }
  
  Future<void> _triggerAlarmAndFlash() async {
    // Continuous vibration
    for (int i = 0; i < 10; i++) {
      HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 500));
    }
    
    // Flash light (if available)
    try {
      // This would require a flashlight plugin
      print('Flashing SOS pattern');
    } catch (e) {
      print('Flashlight not available: $e');
    }
  }
  
  Future<void> _storeEmergencyLocally(double? latitude, double? longitude) async {
    final prefs = await SharedPreferences.getInstance();
    final emergency = {
      'timestamp': DateTime.now().toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'contacts_notified': _contacts.where((c) => c.isEnabled).length,
      'synced': false,
    };
    
    final emergencies = prefs.getStringList('stored_emergencies') ?? [];
    emergencies.add(jsonEncode(emergency));
    await prefs.setStringList('stored_emergencies', emergencies);
    
    print('Emergency stored locally for later sync');
  }
  
  // Test emergency system
  Future<bool> testEmergencySystem() async {
    try {
      print('Testing emergency system...');
      
      // Check permissions
      final smsPermission = await Permission.sms.status;
      final phonePermission = await Permission.phone.status;
      final locationPermission = await Permission.location.status;
      
      print('SMS permission: $smsPermission');
      print('Phone permission: $phonePermission');
      print('Location permission: $locationPermission');
      
      if (!smsPermission.isGranted) {
        print('SMS permission not granted');
        return false;
      }
      
      if (!phonePermission.isGranted) {
        print('Phone permission not granted');
        return false;
      }
      
      // Check if contacts are configured
      final enabledContacts = _contacts.where((c) => c.isEnabled).toList();
      print('Enabled contacts: ${enabledContacts.length}');
      
      if (enabledContacts.isEmpty) {
        print('No enabled emergency contacts');
        return false;
      }
      
      print('Emergency system test passed!');
      return true;
    } catch (e) {
      print('Emergency system test failed: $e');
      return false;
    }
  }
  
  Future<void> requestPermissions() async {
    try {
      print('Requesting permissions...');
      
      // Request SMS permission
      final smsStatus = await Permission.sms.request();
      print('SMS permission: $smsStatus');
      
      // Request Phone permission
      final phoneStatus = await Permission.phone.request();
      print('Phone permission: $phoneStatus');
      
      // Request Location permission
      final locationStatus = await Permission.location.request();
      print('Location permission: $locationStatus');
      
      // If any permission is permanently denied, open settings
      if (smsStatus.isPermanentlyDenied || 
          phoneStatus.isPermanentlyDenied || 
          locationStatus.isPermanentlyDenied) {
        print('Some permissions permanently denied, opening settings');
        await openAppSettings();
      }
      
    } catch (e) {
      print('Error requesting permissions: $e');
    }
  }
}