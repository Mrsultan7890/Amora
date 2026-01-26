import 'package:flutter/services.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'dart:async';
import 'dart:math';
import 'api_service.dart';
import 'location_service.dart';

class EmergencyService {
  static EmergencyService? _instance;
  static EmergencyService get instance => _instance ??= EmergencyService._();
  
  EmergencyService._();
  
  StreamSubscription<AccelerometerEvent>? _accelerometerSubscription;
  bool _isEmergencyEnabled = false;
  bool _isShakeDetected = false;
  DateTime? _lastShakeTime;
  
  // Shake detection parameters
  static const double _shakeThreshold = 12.0;
  static const int _shakeCooldown = 5000; // 5 seconds
  
  Future<void> initialize() async {
    await _loadEmergencySettings();
    if (_isEmergencyEnabled) {
      _startShakeDetection();
    }
  }
  
  Future<void> _loadEmergencySettings() async {
    // Load from shared preferences
    _isEmergencyEnabled = true; // Default enabled
  }
  
  Future<void> setEmergencyEnabled(bool enabled) async {
    _isEmergencyEnabled = enabled;
    
    if (enabled) {
      _startShakeDetection();
    } else {
      _stopShakeDetection();
    }
    
    // Save to shared preferences
  }
  
  void _startShakeDetection() {
    _accelerometerSubscription = accelerometerEvents.listen((event) {
      _detectShake(event);
    });
  }
  
  void _stopShakeDetection() {
    _accelerometerSubscription?.cancel();
    _accelerometerSubscription = null;
  }
  
  void _detectShake(AccelerometerEvent event) {
    if (!_isEmergencyEnabled) return;
    
    // Calculate shake intensity
    double acceleration = sqrt(
      event.x * event.x + event.y * event.y + event.z * event.z
    );
    
    if (acceleration > _shakeThreshold) {
      final now = DateTime.now();
      
      // Check cooldown period
      if (_lastShakeTime != null && 
          now.difference(_lastShakeTime!).inMilliseconds < _shakeCooldown) {
        return;
      }
      
      _lastShakeTime = now;
      _triggerEmergency();
    }
  }
  
  Future<void> _triggerEmergency() async {
    if (_isShakeDetected) return;
    
    _isShakeDetected = true;
    
    try {
      // Vibrate phone
      HapticFeedback.heavyImpact();
      
      // Get current location
      final location = await LocationService.instance.getCurrentLocation();
      
      // Send emergency alert to all matches
      await ApiService.instance.sendEmergencyAlert(
        latitude: location?.latitude,
        longitude: location?.longitude,
      );
      
      print('Emergency alert sent successfully');
      
    } catch (e) {
      print('Failed to send emergency alert: $e');
    } finally {
      // Reset after 10 seconds
      Timer(const Duration(seconds: 10), () {
        _isShakeDetected = false;
      });
    }
  }
  
  bool get isEmergencyEnabled => _isEmergencyEnabled;
  
  void dispose() {
    _stopShakeDetection();
  }
}