import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:health/health.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'offline_emergency_service.dart';

class SmartwatchService {
  static final SmartwatchService _instance = SmartwatchService._internal();
  factory SmartwatchService() => _instance;
  SmartwatchService._internal();

  final OfflineEmergencyService _emergencyService = OfflineEmergencyService();
  final Health _health = Health();
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  
  StreamController<Map<String, dynamic>>? _watchEventController;
  Timer? _healthMonitorTimer;
  bool _isListening = false;
  double? _lastHeartRate;
  DateTime? _lastMovementTime;

  // Initialize smartwatch service
  Future<void> initialize() async {
    if (_isListening) return;
    
    _watchEventController = StreamController<Map<String, dynamic>>.broadcast();
    _isListening = true;
    
    // Request health permissions
    await _requestHealthPermissions();
    
    // Start health monitoring
    await _startHealthMonitoring();
  }

  // Request health permissions
  Future<void> _requestHealthPermissions() async {
    try {
      final types = [
        HealthDataType.HEART_RATE,
        HealthDataType.STEPS,
        HealthDataType.MOVE_MINUTES,
        HealthDataType.DISTANCE_DELTA,
      ];
      
      final permissions = [
        HealthDataAccess.READ,
        HealthDataAccess.READ,
        HealthDataAccess.READ,
        HealthDataAccess.READ,
      ];
      
      await _health.requestAuthorization(types, permissions: permissions);
    } catch (e) {
      print('Error requesting health permissions: $e');
    }
  }

  // Connect to smartwatch (real implementation)
  Future<Map<String, dynamic>> connectWatch() async {
    try {
      // Check if health data is available (indicates smartwatch connection)
      final now = DateTime.now();
      final yesterday = now.subtract(const Duration(days: 1));
      
      final healthData = await _health.getHealthDataFromTypes(
        yesterday,
        now,
        [HealthDataType.HEART_RATE, HealthDataType.STEPS],
      );
      
      if (healthData.isNotEmpty) {
        // Detect device type
        String deviceName = 'Unknown Smartwatch';
        try {
          final androidInfo = await _deviceInfo.androidInfo;
          deviceName = '${androidInfo.brand} ${androidInfo.model}';
        } catch (e) {
          deviceName = 'Connected Smartwatch';
        }
        
        final result = {
          'success': true,
          'device': deviceName,
          'health_data_available': true,
        };
        
        await _saveWatchSettings({
          'connected': true,
          'device': result['device'],
          'connected_at': DateTime.now().toIso8601String(),
        });
        
        // Start monitoring
        await _startHealthMonitoring();
        
        return result;
      } else {
        return {
          'success': false,
          'error': 'No smartwatch detected. Please ensure your watch is connected and health permissions are granted.',
        };
      }
    } catch (e) {
      return {'success': false, 'error': 'Connection failed: ${e.toString()}'};
    }
  }

  // Start health monitoring
  Future<void> _startHealthMonitoring() async {
    _healthMonitorTimer?.cancel();
    
    _healthMonitorTimer = Timer.periodic(const Duration(minutes: 1), (timer) async {
      await _checkHealthData();
    });
  }

  // Check health data for emergency conditions
  Future<void> _checkHealthData() async {
    try {
      final settings = await getConnectionStatus();
      if (!settings['connected'] || !settings['emergency_enabled']) return;
      
      final now = DateTime.now();
      final fiveMinutesAgo = now.subtract(const Duration(minutes: 5));
      
      // Check heart rate
      if (settings['heart_rate_monitoring']) {
        await _checkHeartRate(fiveMinutesAgo, now);
      }
      
      // Check for fall detection (using movement data)
      if (settings['fall_detection']) {
        await _checkFallDetection(fiveMinutesAgo, now);
      }
      
    } catch (e) {
      print('Error checking health data: $e');
    }
  }

  // Check heart rate for abnormalities
  Future<void> _checkHeartRate(DateTime start, DateTime end) async {
    try {
      final heartRateData = await _health.getHealthDataFromTypes(
        start,
        end,
        [HealthDataType.HEART_RATE],
      );
      
      if (heartRateData.isNotEmpty) {
        final latestHeartRate = heartRateData.last.value as NumericHealthValue;
        final currentRate = latestHeartRate.numericValue.toDouble();
        
        // Check for dangerous heart rate (>150 or <40 BPM)
        if (currentRate > 150 || currentRate < 40) {
          await _onHeartRateAlert({
            'heart_rate': currentRate,
            'timestamp': DateTime.now().toIso8601String(),
          });
        }
        
        _lastHeartRate = currentRate;
      }
    } catch (e) {
      print('Error checking heart rate: $e');
    }
  }

  // Check for fall detection using movement patterns
  Future<void> _checkFallDetection(DateTime start, DateTime end) async {
    try {
      final stepsData = await _health.getHealthDataFromTypes(
        start,
        end,
        [HealthDataType.STEPS],
      );
      
      // If no movement for extended period, might indicate fall
      if (stepsData.isEmpty) {
        final timeSinceLastMovement = _lastMovementTime != null 
            ? DateTime.now().difference(_lastMovementTime!)
            : Duration.zero;
            
        // If no movement for 30 minutes, trigger alert
        if (timeSinceLastMovement.inMinutes > 30) {
          await _onFallDetected({
            'no_movement_duration': timeSinceLastMovement.inMinutes,
            'timestamp': DateTime.now().toIso8601String(),
          });
        }
      } else {
        _lastMovementTime = DateTime.now();
      }
    } catch (e) {
      print('Error checking fall detection: $e');
    }
  }

  // Disconnect smartwatch
  Future<void> disconnectWatch() async {
    try {
      _healthMonitorTimer?.cancel();
      await _saveWatchSettings({
        'connected': false,
        'device': '',
        'disconnected_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      print('Error disconnecting watch: $e');
    }
  }

  // Get connection status
  Future<Map<String, dynamic>> getConnectionStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settings = prefs.getString('watch_settings');
      if (settings != null) {
        return json.decode(settings);
      }
      return {
        'connected': false,
        'device': '',
        'emergency_enabled': true,
        'fall_detection': true,
        'heart_rate_monitoring': false,
      };
    } catch (e) {
      return {
        'connected': false,
        'device': '',
        'emergency_enabled': true,
        'fall_detection': true,
        'heart_rate_monitoring': false,
      };
    }
  }

  // Update emergency settings
  Future<void> updateEmergencySettings(bool enabled) async {
    try {
      final settings = await getConnectionStatus();
      settings['emergency_enabled'] = enabled;
      await _saveWatchSettings(settings);
      
      if (enabled && settings['connected']) {
        await _startHealthMonitoring();
      } else {
        _healthMonitorTimer?.cancel();
      }
    } catch (e) {
      print('Error updating emergency settings: $e');
    }
  }

  // Update fall detection
  Future<void> updateFallDetection(bool enabled) async {
    try {
      final settings = await getConnectionStatus();
      settings['fall_detection'] = enabled;
      await _saveWatchSettings(settings);
    } catch (e) {
      print('Error updating fall detection: $e');
    }
  }

  // Update heart rate monitoring
  Future<void> updateHeartRateMonitoring(bool enabled) async {
    try {
      final settings = await getConnectionStatus();
      settings['heart_rate_monitoring'] = enabled;
      await _saveWatchSettings(settings);
    } catch (e) {
      print('Error updating heart rate monitoring: $e');
    }
  }

  // Test emergency system
  Future<void> testEmergencySystem() async {
    await _triggerEmergency({
      'type': 'test',
      'source': 'manual_test',
      'message': 'This is a test of the emergency system from your smartwatch.',
    });
  }

  // Manual emergency trigger (can be called from watch app)
  Future<void> triggerManualEmergency() async {
    await _onEmergencyTriggered({
      'type': 'manual',
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  // Event handlers
  Future<void> _onEmergencyTriggered(dynamic arguments) async {
    await _triggerEmergency({
      'type': 'emergency',
      'source': 'watch_emergency_button',
      'message': 'Emergency triggered from smartwatch!',
      'data': arguments,
    });
  }

  Future<void> _onFallDetected(dynamic arguments) async {
    await _triggerEmergency({
      'type': 'fall_detection',
      'source': 'watch_fall_sensor',
      'message': 'Possible fall detected by smartwatch! No movement for ${arguments['no_movement_duration']} minutes.',
      'data': arguments,
    });
  }

  Future<void> _onHeartRateAlert(dynamic arguments) async {
    await _triggerEmergency({
      'type': 'heart_rate_alert',
      'source': 'watch_heart_sensor',
      'message': 'Abnormal heart rate detected: ${arguments['heart_rate']} BPM. Need assistance.',
      'data': arguments,
    });
  }

  // Trigger emergency using existing emergency service
  Future<void> _triggerEmergency(Map<String, dynamic> emergencyData) async {
    try {
      // Use existing emergency service
      await _emergencyService.triggerEmergency(
        emergencyType: emergencyData['type'],
        customMessage: emergencyData['message'],
        source: 'smartwatch',
      );
      
      // Log emergency event
      await _logEmergencyEvent(emergencyData);
      
      // Notify listeners
      _watchEventController?.add({
        'event': 'emergency_triggered',
        'data': emergencyData,
        'timestamp': DateTime.now().toIso8601String(),
      });
      
    } catch (e) {
      print('Error triggering emergency from watch: $e');
    }
  }

  // Save watch settings
  Future<void> _saveWatchSettings(Map<String, dynamic> settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('watch_settings', json.encode(settings));
    } catch (e) {
      print('Error saving watch settings: $e');
    }
  }

  // Log emergency event
  Future<void> _logEmergencyEvent(Map<String, dynamic> eventData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final logs = prefs.getStringList('watch_emergency_logs') ?? [];
      
      logs.add(json.encode({
        ...eventData,
        'timestamp': DateTime.now().toIso8601String(),
      }));
      
      // Keep only last 50 logs
      if (logs.length > 50) {
        logs.removeRange(0, logs.length - 50);
      }
      
      await prefs.setStringList('watch_emergency_logs', logs);
    } catch (e) {
      print('Error logging emergency event: $e');
    }
  }

  // Get emergency logs
  Future<List<Map<String, dynamic>>> getEmergencyLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final logs = prefs.getStringList('watch_emergency_logs') ?? [];
      
      return logs.map((log) => json.decode(log) as Map<String, dynamic>).toList();
    } catch (e) {
      return [];
    }
  }

  // Get current health stats
  Future<Map<String, dynamic>> getCurrentHealthStats() async {
    try {
      final now = DateTime.now();
      final oneHourAgo = now.subtract(const Duration(hours: 1));
      
      final heartRateData = await _health.getHealthDataFromTypes(
        oneHourAgo,
        now,
        [HealthDataType.HEART_RATE],
      );
      
      final stepsData = await _health.getHealthDataFromTypes(
        DateTime(now.year, now.month, now.day),
        now,
        [HealthDataType.STEPS],
      );
      
      double? currentHeartRate;
      int todaySteps = 0;
      
      if (heartRateData.isNotEmpty) {
        final latest = heartRateData.last.value as NumericHealthValue;
        currentHeartRate = latest.numericValue.toDouble();
      }
      
      if (stepsData.isNotEmpty) {
        final latest = stepsData.last.value as NumericHealthValue;
        todaySteps = latest.numericValue.toInt();
      }
      
      return {
        'heart_rate': currentHeartRate,
        'steps_today': todaySteps,
        'last_updated': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'heart_rate': null,
        'steps_today': 0,
        'last_updated': DateTime.now().toIso8601String(),
        'error': e.toString(),
      };
    }
  }

  // Dispose
  void dispose() {
    _watchEventController?.close();
    _healthMonitorTimer?.cancel();
    _isListening = false;
  }
}