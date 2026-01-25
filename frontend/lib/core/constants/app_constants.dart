import 'package:flutter/foundation.dart';

class AppConstants {
  // API Configuration - Use localhost for emulator, change for production
  static const String apiBaseUrl = kDebugMode 
      ? 'http://10.0.2.2:8000/api'  // Debug/Emulator
      : 'http://10.0.2.2:8000/api'; // Release - same for now
      
  static const String wsBaseUrl = kDebugMode
      ? 'ws://10.0.2.2:8000/ws'     // Debug/Emulator  
      : 'ws://10.0.2.2:8000/ws';    // Release - same for now
  
  // App Configuration
  static const String appName = 'Amora';
  static const String appVersion = '1.0.0';
  static const bool debugMode = true;
  
  // Network Configuration
  static const int connectTimeout = 30; // seconds
  static const int receiveTimeout = 30; // seconds
  
  // Feature Flags
  static const bool enablePushNotifications = false;
  static const bool enableVideoCalls = false;
  static const bool enablePremiumFeatures = false;
  
  // Pagination
  static const int defaultPageSize = 10;
  static const int maxProfilesPerLoad = 20;
}