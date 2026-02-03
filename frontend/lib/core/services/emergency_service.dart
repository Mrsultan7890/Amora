import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'dart:math';
import 'api_service.dart';
import 'location_service.dart';
import 'offline_emergency_service.dart';

class EmergencyService {
  static EmergencyService? _instance;
  static EmergencyService get instance => _instance ??= EmergencyService._();
  
  EmergencyService._();
  
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  bool _isEmergencyEnabled = true;
  bool _isShakeDetected = false;
  DateTime? _lastShakeTime;
  
  // Settings key
  static const String _emergencyEnabledKey = 'emergency_shake_enabled';
  
  // Shake detection parameters
  static const double _shakeThreshold = 15.0; // Increased threshold
  static const int _shakeCooldown = 30000; // 30 seconds cooldown
  
  Future<void> initialize() async {
    print('🚨 EmergencyService: Initializing...');
    await _loadEmergencySettings();
    print('🚨 EmergencyService: Emergency enabled: $_isEmergencyEnabled');
    if (_isEmergencyEnabled) {
      _startShakeDetection();
      print('🚨 EmergencyService: Shake detection started');
    }
    print('🚨 EmergencyService: Initialization complete');
  }
  
  Future<void> _loadEmergencySettings() async {
    final prefs = await SharedPreferences.getInstance();
    _isEmergencyEnabled = prefs.getBool(_emergencyEnabledKey) ?? true;
    print('🚨 EmergencyService: Loaded settings - enabled: $_isEmergencyEnabled');
  }
  
  Future<void> setEmergencyEnabled(bool enabled) async {
    print('🚨 EmergencyService: Setting emergency enabled to: $enabled');
    _isEmergencyEnabled = enabled;
    
    // Save to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_emergencyEnabledKey, enabled);
    
    if (enabled) {
      _startShakeDetection();
      // Start background service for when app is closed
      await SmsService.startBackgroundService();
      print('🚨 EmergencyService: Shake detection STARTED + Background service STARTED');
    } else {
      _stopShakeDetection();
      // Stop background service
      await SmsService.stopBackgroundService();
      print('🚨 EmergencyService: Shake detection STOPPED + Background service STOPPED');
    }
  }
  
  void _startShakeDetection() {
    print('🚨 EmergencyService: Starting shake detection...');
    _accelerometerSubscription = accelerometerEventStream().listen((event) {
      _detectShake(event);
    }, onError: (error) {
      print('🚨 EmergencyService: Accelerometer error: $error');
    });
    print('🚨 EmergencyService: Accelerometer stream subscribed');
  }
  
  void _stopShakeDetection() {
    print('🚨 EmergencyService: Stopping shake detection...');
    _accelerometerSubscription?.cancel();
    _accelerometerSubscription = null;
    print('🚨 EmergencyService: Shake detection stopped');
  }
  
  void _detectShake(AccelerometerEvent event) {
    if (!_isEmergencyEnabled) {
      // Debug: Show when shake is detected but disabled
      double acceleration = sqrt(
        event.x * event.x + event.y * event.y + event.z * event.z
      );
      if (acceleration > _shakeThreshold) {
        print('🚨 SHAKE DETECTED BUT EMERGENCY DISABLED! Acceleration: ${acceleration.toStringAsFixed(2)}');
      }
      return;
    }
    
    // Calculate shake intensity
    double acceleration = sqrt(
      event.x * event.x + event.y * event.y + event.z * event.z
    );
    
    // Debug: Print acceleration values occasionally
    if (DateTime.now().millisecondsSinceEpoch % 1000 < 50) {
      print('🚨 Acceleration: ${acceleration.toStringAsFixed(2)} (threshold: $_shakeThreshold)');
    }
    
    if (acceleration > _shakeThreshold) {
      print('🚨 SHAKE DETECTED! Acceleration: ${acceleration.toStringAsFixed(2)}');
      final now = DateTime.now();
      
      // Check cooldown period
      if (_lastShakeTime != null && 
          now.difference(_lastShakeTime!).inMilliseconds < _shakeCooldown) {
        print('🚨 Shake ignored - cooldown active');
        return;
      }
      
      _lastShakeTime = now;
      print('🚨 Triggering emergency!');
      _triggerEmergency();
    }
  }
  
  Future<void> _triggerEmergency() async {
    if (_isShakeDetected) {
      print('🚨 Emergency already in progress, ignoring');
      return;
    }

    _isShakeDetected = true;
    print('🚨 EMERGENCY TRIGGERED!');

    try {
      // Vibrate phone immediately
      HapticFeedback.heavyImpact();
      
      // Try online emergency first
      bool onlineSuccess = false;
      try {
        print('🚨 Attempting online emergency...');
        // Get current location
        final location = await LocationService.instance.getCurrentLocation();
        
        // Send emergency alert to all matches
        final result = await ApiService.instance.sendEmergencyAlert(
          latitude: location?.latitude,
          longitude: location?.longitude,
        );
        
        print('🚨 Online emergency alert sent successfully: $result');
        _showEmergencyConfirmation(result);
        onlineSuccess = true;
        
      } catch (e) {
        print('🚨 Online emergency failed: $e');
        onlineSuccess = false;
      }
      
      // ALWAYS trigger offline emergency (as backup or primary)
      print('🚨 Triggering offline emergency...');
      try {
        await OfflineEmergencyService.instance.triggerOfflineEmergency();
        _showOfflineEmergencyConfirmation();
        print('🚨 Offline emergency triggered successfully');
      } catch (e) {
        print('🚨 Offline emergency failed: $e');
      }
      
      if (!onlineSuccess) {
        _showEmergencyError('Online emergency failed, offline emergency activated');
      }
      
    } catch (e) {
      print('🚨 Failed to send emergency alert: $e');
      _showEmergencyError(e.toString());
    } finally {
      // Reset after 10 seconds
      Timer(const Duration(seconds: 10), () {
        print('🚨 Emergency detection reset');
        _isShakeDetected = false;
      });
    }
  }
  
  bool get isEmergencyEnabled => _isEmergencyEnabled;
  
  // Manual test function
  Future<void> testEmergencyTrigger() async {
    print('🚨 MANUAL EMERGENCY TEST TRIGGERED');
    await _triggerEmergency();
  }
  
  void dispose() {
    _stopShakeDetection();
  }
  
  void _showEmergencyConfirmation(Map<String, dynamic> result) {
    final alertsSent = result['alerts_sent'] ?? 0;
    print('🚨 EMERGENCY ALERT SENT TO $alertsSent MATCHES');
    
    // You can add a toast/snackbar here if you have context
    // For now, just vibrate again to confirm
    HapticFeedback.mediumImpact();
  }
  
  void _showEmergencyError(String error) {
    print('❌ EMERGENCY ALERT FAILED: $error');
    
    // Triple vibration to indicate error
    HapticFeedback.heavyImpact();
    Timer(const Duration(milliseconds: 200), () => HapticFeedback.heavyImpact());
    Timer(const Duration(milliseconds: 400), () => HapticFeedback.heavyImpact());
  }
  
  void _showOfflineEmergencyConfirmation() {
    print('📱 OFFLINE EMERGENCY ACTIVATED - SMS & CALLS SENT');
    
    // Different vibration pattern for offline
    HapticFeedback.mediumImpact();
    Timer(const Duration(milliseconds: 100), () => HapticFeedback.mediumImpact());
    Timer(const Duration(milliseconds: 200), () => HapticFeedback.heavyImpact());
  }
}