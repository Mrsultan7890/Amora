import 'package:flutter/foundation.dart';

class AppConstants {
  // API Configuration
  static const String apiBaseUrl = 'http://127.0.0.1:8000/api'; // Localhost for same device
  static const String wsBaseUrl = 'ws://127.0.0.1:8000/ws';
  
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