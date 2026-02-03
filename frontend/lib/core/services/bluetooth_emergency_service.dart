import 'package:flutter/services.dart';

class BluetoothEmergencyService {
  static BluetoothEmergencyService? _instance;
  static BluetoothEmergencyService get instance => _instance ??= BluetoothEmergencyService._();
  
  BluetoothEmergencyService._();
  
  static const MethodChannel _channel = MethodChannel('amora/bluetooth_emergency');
  
  Future<bool> isBluetoothEnabled() async {
    try {
      final result = await _channel.invokeMethod('isBluetoothEnabled');
      return result == true;
    } catch (e) {
      print('Error checking Bluetooth: $e');
      return false;
    }
  }
  
  Future<bool> enableBluetooth() async {
    try {
      final result = await _channel.invokeMethod('enableBluetooth');
      return result == true;
    } catch (e) {
      print('Error enabling Bluetooth: $e');
      return false;
    }
  }
  
  Future<void> broadcastEmergency({
    required String phoneNumber,
    required double latitude,
    required double longitude,
    String? customMessage,
  }) async {
    try {
      final emergencyData = {
        'type': 'EMERGENCY_SOS',
        'phone': phoneNumber,
        'latitude': latitude,
        'longitude': longitude,
        'message': customMessage ?? 'EMERGENCY! Please call this number or contact police!',
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      await _channel.invokeMethod('broadcastEmergency', emergencyData);
      print('🚨 Emergency broadcast sent via Bluetooth');
    } catch (e) {
      print('Error broadcasting emergency: $e');
    }
  }
  
  Future<void> startEmergencyListener() async {
    try {
      await _channel.invokeMethod('startEmergencyListener');
      print('📡 Bluetooth emergency listener started');
    } catch (e) {
      print('Error starting listener: $e');
    }
  }
  
  Future<void> stopEmergencyListener() async {
    try {
      await _channel.invokeMethod('stopEmergencyListener');
      print('📡 Bluetooth emergency listener stopped');
    } catch (e) {
      print('Error stopping listener: $e');
    }
  }
}