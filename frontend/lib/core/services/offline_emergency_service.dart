import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:async';
import 'dart:convert';
import 'location_service.dart';
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
    final contactsJson = prefs.getString(_contactsKey);
    
    if (contactsJson != null) {
      final List<dynamic> contactsList = jsonDecode(contactsJson);
      _contacts = contactsList.map((json) => EmergencyContact.fromJson(json)).toList();
    } else {
      // Load default contacts
      _contacts = DefaultEmergencyContacts.getDefaults();
      await _saveContacts();
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
      
      // Send SMS to all contacts
      if (_autoSmsEnabled) {
        await _sendEmergencySMS(location?.latitude, location?.longitude);
      }
      
      // Start call sequence
      await _startEmergencyCallSequence();
      
      // Trigger alarm and flash
      await _triggerAlarmAndFlash();
      
      // Store emergency locally
      await _storeEmergencyLocally(location?.latitude, location?.longitude);
      
    } catch (e) {
      // Continue even if some parts fail
    } finally {
      // Reset after 1 minute (shorter for testing)
      Timer(const Duration(minutes: 1), () {
        _isEmergencyActive = false;
      });
    }
  }
  
  Future<void> _sendEmergencySMS(double? latitude, double? longitude) async {
    final enabledContacts = _contacts.where((c) => c.isEnabled).toList();
    
    if (enabledContacts.isEmpty) {
      return;
    }
    
    String locationText = '';
    if (latitude != null && longitude != null) {
      locationText = '\nLocation: $latitude, $longitude\nMaps: https://maps.google.com/?q=$latitude,$longitude';
    }
    
    final message = 'EMERGENCY ALERT\nI need immediate help!$locationText\nTime: ${DateTime.now().toString().substring(0, 19)}\n- Amora Emergency';
    
    for (final contact in enabledContacts) {
      try {
        // Try SENDTO first (more reliable)
        final sendtoUri = Uri(
          scheme: 'sms',
          path: contact.phoneNumber,
          queryParameters: {'body': message},
        );
        
        bool launched = false;
        if (await canLaunchUrl(sendtoUri)) {
          launched = await launchUrl(
            sendtoUri,
            mode: LaunchMode.externalApplication,
          );
        }
        
        if (!launched) {
          // Fallback: try with different scheme
          final fallbackUri = Uri.parse('sms:${contact.phoneNumber}?body=${Uri.encodeComponent(message)}');
          if (await canLaunchUrl(fallbackUri)) {
            await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
          }
        }
        
        // Small delay between SMS
        await Future.delayed(const Duration(milliseconds: 1000));
      } catch (e) {
        // Continue with next contact
      }
    }
  }
  
  Future<void> _startEmergencyCallSequence() async {
    final enabledContacts = _contacts.where((c) => c.isEnabled).toList();
    
    if (enabledContacts.isEmpty) {
      return;
    }
    
    for (final contact in enabledContacts) {
      try {
        // Try direct call
        final callUri = Uri(scheme: 'tel', path: contact.phoneNumber);
        
        bool launched = false;
        if (await canLaunchUrl(callUri)) {
          launched = await launchUrl(
            callUri,
            mode: LaunchMode.externalApplication,
          );
        }
        
        if (!launched) {
          // Fallback: try with different format
          final fallbackUri = Uri.parse('tel:${contact.phoneNumber}');
          if (await canLaunchUrl(fallbackUri)) {
            await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
          }
        }
        
        // Wait 10 seconds before next call (shorter for testing)
        await Future.delayed(const Duration(seconds: 10));
      } catch (e) {
        // Continue with next contact
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