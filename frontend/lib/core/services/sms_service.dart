import 'package:flutter/services.dart';

class SmsService {
  static const MethodChannel _channel = MethodChannel('amora/sms');
  
  static Future<bool> sendSms(String phoneNumber, String message) async {
    try {
      final result = await _channel.invokeMethod('sendSms', {
        'phoneNumber': phoneNumber,
        'message': message,
      });
      return result == true;
    } catch (e) {
      return false;
    }
  }
  
  static Future<bool> makeCall(String phoneNumber) async {
    try {
      final result = await _channel.invokeMethod('makeCall', {
        'phoneNumber': phoneNumber,
      });
      return result == true;
    } catch (e) {
      return false;
    }
  }
  
  static Future<void> requestSpecialPermissions() async {
    try {
      await _channel.invokeMethod('requestSpecialPermissions');
    } catch (e) {
      // Handle error
    }
  }
  
  static Future<bool> checkPermissions() async {
    try {
      final result = await _channel.invokeMethod('checkPermissions');
      return result == true;
    } catch (e) {
      return false;
    }
  }
}