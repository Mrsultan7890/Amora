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
    if (!_isEnabled || _isEmergencyActive) return;
    
    _isEmergencyActive = true;
    
    try {
      print('🚨 OFFLINE EMERGENCY TRIGGERED');
      
      // 1. Get current location
      final location = await LocationService.instance.getCurrentLocation();
      
      // 2. Send SMS to all contacts
      if (_autoSmsEnabled) {
        await _sendEmergencySMS(location?.latitude, location?.longitude);
      }
      
      // 3. Start call sequence
      await _startEmergencyCallSequence();
      
      // 4. Trigger alarm and flash
      await _triggerAlarmAndFlash();
      
      // 5. Store emergency locally
      await _storeEmergencyLocally(location?.latitude, location?.longitude);
      
    } catch (e) {
      print('Error in offline emergency: $e');
    } finally {
      // Reset after 5 minutes
      Timer(const Duration(minutes: 5), () {
        _isEmergencyActive = false;
      });
    }
  }
  
  Future<void> _sendEmergencySMS(double? latitude, double? longitude) async {
    final enabledContacts = _contacts.where((c) => c.isEnabled).toList();
    
    String locationText = '';
    if (latitude != null && longitude != null) {
      locationText = '\\nLocation: $latitude, $longitude\\nGoogle Maps: https://maps.google.com/?q=$latitude,$longitude';
    }
    
    final message = '''🚨 EMERGENCY ALERT 🚨
I need immediate help!$locationText
Time: ${DateTime.now().toString()}
Please call or come immediately!
- Sent from Amora Emergency''';
    
    for (final contact in enabledContacts) {
      try {
        final smsUri = Uri(
          scheme: 'sms',
          path: contact.phoneNumber,
          queryParameters: {'body': message},
        );
        
        if (await canLaunchUrl(smsUri)) {
          await launchUrl(smsUri);
          print('SMS sent to ${contact.name}');
        }
      } catch (e) {
        print('Failed to send SMS to ${contact.name}: $e');
      }
    }
  }
  
  Future<void> _startEmergencyCallSequence() async {
    final enabledContacts = _contacts.where((c) => c.isEnabled).toList();
    
    for (final contact in enabledContacts) {
      try {
        print('Calling ${contact.name} at ${contact.phoneNumber}');
        
        final callUri = Uri(scheme: 'tel', path: contact.phoneNumber);
        if (await canLaunchUrl(callUri)) {
          await launchUrl(callUri);
          
          // Wait for call timeout before next call
          await Future.delayed(Duration(seconds: _callTimeout));
        }
      } catch (e) {
        print('Failed to call ${contact.name}: $e');
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
      // Check permissions
      final smsPermission = await Permission.sms.status;
      final phonePermission = await Permission.phone.status;
      
      if (!smsPermission.isGranted || !phonePermission.isGranted) {
        return false;
      }
      
      // Check if contacts are configured
      if (_contacts.where((c) => c.isEnabled).isEmpty) {
        return false;
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }
  
  Future<void> requestPermissions() async {
    await [
      Permission.sms,
      Permission.phone,
      Permission.location,
    ].request();
  }
}