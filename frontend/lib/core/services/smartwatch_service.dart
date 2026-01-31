import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'offline_emergency_service.dart';

class SmartwatchService {
  static final SmartwatchService _instance = SmartwatchService._internal();
  factory SmartwatchService() => _instance;
  SmartwatchService._internal();

  static const MethodChannel _channel = MethodChannel('amora/smartwatch');
  final OfflineEmergencyService _emergencyService = OfflineEmergencyService();
  
  StreamController<Map<String, dynamic>>? _watchEventController;
  bool _isListening = false;

  // Initialize smartwatch service
  Future<void> initialize() async {
    if (_isListening) return;
    
    _watchEventController = StreamController<Map<String, dynamic>>.broadcast();
    _isListening = true;
    
    // Set up method call handler for watch events
    _channel.setMethodCallHandler(_handleWatchEvents);
    
    // Start listening for watch connections
    await _startWatchListener();
  }

  // Handle incoming watch events
  Future<dynamic> _handleWatchEvents(MethodCall call) async {
    switch (call.method) {
      case 'onWatchConnected':
        _onWatchConnected(call.arguments);
        break;
      case 'onWatchDisconnected':
        _onWatchDisconnected();
        break;
      case 'onEmergencyTriggered':
        await _onEmergencyTriggered(call.arguments);
        break;
      case 'onFallDetected':
        await _onFallDetected(call.arguments);
        break;
      case 'onHeartRateAlert':
        await _onHeartRateAlert(call.arguments);
        break;
      case 'onSOSButtonPressed':
        await _onSOSButtonPressed(call.arguments);
        break;
    }
  }

  // Connect to smartwatch
  Future<Map<String, dynamic>> connectWatch() async {
    try {
      final result = await _channel.invokeMethod('connectWatch');
      if (result['success']) {
        await _saveWatchSettings({
          'connected': true,
          'device': result['device'],
          'connected_at': DateTime.now().toIso8601String(),
        });
      }
      return result;
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Disconnect smartwatch
  Future<void> disconnectWatch() async {
    try {
      await _channel.invokeMethod('disconnectWatch');
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
        final data = json.decode(settings);
        
        // Check if watch is actually connected
        final isConnected = await _channel.invokeMethod('isWatchConnected');
        data['connected'] = isConnected ?? false;
        
        return data;
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
      await _channel.invokeMethod('updateEmergencySettings', {'enabled': enabled});
      final settings = await getConnectionStatus();
      settings['emergency_enabled'] = enabled;
      await _saveWatchSettings(settings);
    } catch (e) {
      print('Error updating emergency settings: $e');
    }
  }

  // Update fall detection
  Future<void> updateFallDetection(bool enabled) async {
    try {
      await _channel.invokeMethod('updateFallDetection', {'enabled': enabled});
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
      await _channel.invokeMethod('updateHeartRateMonitoring', {'enabled': enabled});
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

  // Event handlers
  void _onWatchConnected(dynamic arguments) {
    _watchEventController?.add({
      'event': 'connected',
      'device': arguments['device'],
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  void _onWatchDisconnected() {
    _watchEventController?.add({
      'event': 'disconnected',
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

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
      'message': 'Fall detected by smartwatch! Please check on me.',
      'data': arguments,
    });
  }

  Future<void> _onHeartRateAlert(dynamic arguments) async {
    await _triggerEmergency({
      'type': 'heart_rate_alert',
      'source': 'watch_heart_sensor',
      'message': 'Abnormal heart rate detected by smartwatch. Need assistance.',
      'data': arguments,
    });
  }

  Future<void> _onSOSButtonPressed(dynamic arguments) async {
    await _triggerEmergency({
      'type': 'sos_button',
      'source': 'watch_sos_button',
      'message': 'SOS button pressed on smartwatch! Emergency assistance needed.',
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
      
    } catch (e) {
      print('Error triggering emergency from watch: $e');
    }
  }

  // Start listening for watch events
  Future<void> _startWatchListener() async {
    try {
      await _channel.invokeMethod('startWatchListener');
    } catch (e) {
      print('Error starting watch listener: $e');
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

  // Dispose
  void dispose() {
    _watchEventController?.close();
    _isListening = false;
  }
}