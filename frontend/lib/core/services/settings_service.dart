import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class SettingsService {
  static SettingsService? _instance;
  static SettingsService get instance => _instance ??= SettingsService._();
  
  SettingsService._();
  
  final ApiService _apiService = ApiService.instance;
  
  // Settings keys
  static const String _maxDistanceKey = 'max_distance';
  static const String _ageRangeMinKey = 'age_range_min';
  static const String _ageRangeMaxKey = 'age_range_max';
  static const String _interestedInKey = 'interested_in';
  static const String _pushNotificationsKey = 'push_notifications';
  static const String _emailNotificationsKey = 'email_notifications';
  static const String _showOnlineStatusKey = 'show_online_status';
  static const String _showDistanceKey = 'show_distance';
  static const String _showMeOnAmoraKey = 'show_me_on_amora';
  static const String _incognitoModeKey = 'incognito_mode';
  static const String _showInFeedKey = 'show_in_feed';
  static const String _emergencyShakeEnabledKey = 'emergency_shake_enabled';
  static const String _bluetoothSOSEnabledKey = 'bluetooth_sos_enabled';
  
  // Discovery Settings
  Future<double> getMaxDistance() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_maxDistanceKey) ?? 50.0;
  }
  
  Future<void> setMaxDistance(double distance) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_maxDistanceKey, distance);
    await _updateUserSettings({'max_distance': distance});
  }
  
  Future<List<double>> getAgeRange() async {
    final prefs = await SharedPreferences.getInstance();
    final min = prefs.getDouble(_ageRangeMinKey) ?? 18.0;
    final max = prefs.getDouble(_ageRangeMaxKey) ?? 35.0;
    return [min, max];
  }
  
  Future<void> setAgeRange(double min, double max) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_ageRangeMinKey, min);
    await prefs.setDouble(_ageRangeMaxKey, max);
    await _updateUserSettings({
      'age_range_min': min.toInt(),
      'age_range_max': max.toInt(),
    });
  }
  
  Future<String> getInterestedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_interestedInKey) ?? 'Everyone';
  }
  
  Future<void> setInterestedIn(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_interestedInKey, value);
    await _updateUserSettings({'interested_in': value});
  }
  
  // Notification Settings
  Future<bool> getPushNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_pushNotificationsKey) ?? true;
  }
  
  Future<void> setPushNotifications(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_pushNotificationsKey, enabled);
    await _updateUserSettings({'push_notifications': enabled});
  }
  
  Future<bool> getEmailNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_emailNotificationsKey) ?? false;
  }
  
  Future<void> setEmailNotifications(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_emailNotificationsKey, enabled);
    await _updateUserSettings({'email_notifications': enabled});
  }
  
  // Privacy Settings
  Future<bool> getShowOnlineStatus() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_showOnlineStatusKey) ?? true;
  }
  
  Future<void> setShowOnlineStatus(bool show) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showOnlineStatusKey, show);
    await _updateUserSettings({'show_online_status': show});
  }
  
  Future<bool> getShowDistance() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_showDistanceKey) ?? true;
  }
  
  Future<void> setShowDistance(bool show) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showDistanceKey, show);
    await _updateUserSettings({'show_distance': show});
  }
  
  Future<bool> getShowMeOnAmora() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_showMeOnAmoraKey) ?? true;
  }
  
  Future<void> setShowMeOnAmora(bool show) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showMeOnAmoraKey, show);
    await _updateUserSettings({'show_me_on_amora': show});
  }
  
  Future<bool> getIncognitoMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_incognitoModeKey) ?? false;
  }
  
  Future<void> setIncognitoMode(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_incognitoModeKey, enabled);
    await _updateUserSettings({'incognito_mode': enabled});
  }
  
  // Emergency Settings
  Future<bool> getEmergencyShakeEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_emergencyShakeEnabledKey) ?? true;
  }
  
  Future<void> setEmergencyShakeEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_emergencyShakeEnabledKey, enabled);
    await _updateUserSettings({'emergency_shake_enabled': enabled});
  }
  
  // Bluetooth SOS Settings
  Future<bool> getBluetoothSOSEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_bluetoothSOSEnabledKey) ?? false;
  }
  
  Future<void> setBluetoothSOSEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_bluetoothSOSEnabledKey, enabled);
    await _updateUserSettings({'bluetooth_sos_enabled': enabled});
  }
  
  // Feed Settings
  Future<bool> getShowInFeed() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_showInFeedKey) ?? true;
  }
  
  Future<void> setShowInFeed(bool show) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_showInFeedKey, show);
    await _updateUserSettings({'show_in_feed': show});
  }
  
  // Load all settings
  Future<Map<String, dynamic>> loadAllSettings() async {
    return {
      'max_distance': await getMaxDistance(),
      'age_range': await getAgeRange(),
      'interested_in': await getInterestedIn(),
      'push_notifications': await getPushNotifications(),
      'email_notifications': await getEmailNotifications(),
      'show_online_status': await getShowOnlineStatus(),
      'show_distance': await getShowDistance(),
      'show_me_on_amora': await getShowMeOnAmora(),
      'incognito_mode': await getIncognitoMode(),
      'emergency_shake_enabled': await getEmergencyShakeEnabled(),
      'bluetooth_sos_enabled': await getBluetoothSOSEnabled(),
      'show_in_feed': await getShowInFeed(),
    };
  }
  
  // Account Actions
  Future<void> deleteAccount() async {
    try {
      await _apiService.deleteAccount();
      // Clear all local data
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } catch (e) {
      throw Exception('Failed to delete account: $e');
    }
  }
  
  Future<Map<String, dynamic>> getBlockedUsers() async {
    try {
      return await _apiService.getBlockedUsers();
    } catch (e) {
      return {'blocked_users': []};
    }
  }
  
  Future<void> blockUser(String userId) async {
    await _apiService.blockUser(userId);
  }
  
  Future<void> unblockUser(String userId) async {
    await _apiService.unblockUser(userId);
  }
  
  // Private helper
  Future<void> _updateUserSettings(Map<String, dynamic> settings) async {
    try {
      await _apiService.updateProfile(settings);
    } catch (e) {
      print('Failed to sync settings to server: $e');
    }
  }
}