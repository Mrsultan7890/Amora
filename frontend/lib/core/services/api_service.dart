import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';
import '../../shared/models/user_model.dart';
import '../../shared/models/match_model.dart';
import '../../shared/models/message_model.dart';

class ApiService {
  static ApiService? _instance;
  static ApiService get instance => _instance ??= ApiService._();
  
  ApiService._();
  
  late Dio _dio;
  String? _token;
  
  String get baseUrl => AppConstants.apiBaseUrl;
  
  Future<void> initialize() async {
    print('Initializing API service with base URL: $baseUrl');
    
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: Duration(seconds: AppConstants.connectTimeout),
      receiveTimeout: Duration(seconds: AppConstants.receiveTimeout),
      headers: {
        'Content-Type': 'application/json',
      },
    ));
    
    // Add interceptors
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        print('API Request: ${options.method} ${options.uri}');
        if (_token != null) {
          options.headers['Authorization'] = 'Bearer $_token';
        }
        handler.next(options);
      },
      onResponse: (response, handler) {
        print('API Response: ${response.statusCode} ${response.requestOptions.uri}');
        handler.next(response);
      },
      onError: (error, handler) {
        print('API Error: ${error.response?.statusCode} ${error.requestOptions.uri}');
        print('Error data: ${error.response?.data}');
        if (error.response?.statusCode == 401) {
          _clearToken();
        }
        handler.next(error);
      },
    ));
    
    await _loadToken();
    print('API service initialized successfully');
  }
  
  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    print('Loaded token: ${_token != null ? "Found" : "Not found"}');
  }
  
  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    _token = token;
    print('Token saved successfully');
  }
  
  Future<void> _clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    _token = null;
    print('Token cleared');
  }
  
  // Auth Methods
  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    required String name,
    required int age,
    required String gender,
    required List<String> interests,
  }) async {
    try {
      final response = await _dio.post('/auth/register', data: {
        'email': email,
        'password': password,
        'name': name,
        'age': age,
        'gender': gender,
        'interests': interests,
      });
      
      final token = response.data['access_token'];
      await _saveToken(token);
      
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      print('Login attempt for: $email');
      print('API URL: $baseUrl/auth/login');
      
      final formData = FormData.fromMap({
        'username': email,
        'password': password,
      });
      
      print('Sending login request...');
      final response = await _dio.post('/auth/login', data: formData);
      print('Login response: ${response.statusCode}');
      print('Login data: ${response.data}');
      
      final token = response.data['access_token'];
      await _saveToken(token);
      
      return response.data;
    } catch (e) {
      print('Login error: $e');
      if (e is DioException) {
        print('DioException type: ${e.type}');
        print('DioException message: ${e.message}');
        print('DioException response: ${e.response?.data}');
      }
      throw _handleError(e);
    }
  }
  
  Future<void> logout() async {
    try {
      await _dio.post('/auth/logout');
    } catch (e) {
      // Continue with logout even if API call fails
    } finally {
      await _clearToken();
    }
  }
  
  // User Methods
  Future<UserModel> getCurrentUser() async {
    try {
      final response = await _dio.get('/auth/me');
      return UserModel.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<UserModel> getUserProfile(String userId) async {
    try {
      final response = await _dio.get('/users/$userId');
      return UserModel.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<UserModel> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await _dio.put('/users/profile', data: data);
      return UserModel.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<List<UserModel>> getDiscoverProfiles({
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final response = await _dio.get('/swipes/discover', queryParameters: {
        'page': page,
        'limit': limit,
      });
      
      return (response.data as List)
          .map((json) => UserModel.fromJson(json))
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  // Swipe Methods
  Future<Map<String, dynamic>> createSwipe({
    required String swipedUserId,
    required bool isLike,
    bool isSuperLike = false,
  }) async {
    try {
      final response = await _dio.post('/swipes/', data: {
        'swiped_user_id': swipedUserId,
        'is_like': isLike,
        'is_super_like': isSuperLike,
      });
      
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  // Match Methods
  Future<List<MatchModel>> getMatches({String? search}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (search != null && search.isNotEmpty) {
        queryParams['search'] = search;
      }
      
      final response = await _dio.get('/matches/', queryParameters: queryParams);
      
      return (response.data as List)
          .map((json) => MatchModel.fromJson(json))
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<List<UserModel>> searchUsers(String query) async {
    try {
      final response = await _dio.get('/users/search', queryParameters: {
        'query': query,
      });
      
      return (response.data as List)
          .map((json) => UserModel.fromJson(json))
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<List<Map<String, dynamic>>> getUserLikes() async {
    try {
      final response = await _dio.get('/users/likes');
      return List<Map<String, dynamic>>.from(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  // Message Methods
  Future<MessageModel> sendMessage({
    required String matchId,
    required String content,
    String messageType = 'text',
    String? imageUrl,
  }) async {
    try {
      final response = await _dio.post('/messages/', data: {
        'match_id': matchId,
        'content': content,
        'message_type': messageType,
        'image_url': imageUrl,
      });
      
      return MessageModel.fromJson(response.data);
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<List<MessageModel>> getMessages({
    required String matchId,
    int skip = 0,
    int limit = 50,
  }) async {
    try {
      final response = await _dio.get('/messages/$matchId', queryParameters: {
        'skip': skip,
        'limit': limit,
      });
      
      return (response.data as List)
          .map((json) => MessageModel.fromJson(json))
          .toList();
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<void> markMessageRead(String messageId) async {
    try {
      await _dio.put('/messages/$messageId/read');
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<int> getUnreadCount(String matchId) async {
    try {
      final response = await _dio.get('/messages/$matchId/unread-count');
      return response.data['unread_count'];
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  // Upload Methods
  Future<String> uploadImage(String filePath) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
      });
      
      final response = await _dio.post('/upload/image', data: formData);
      return response.data['url'];
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  // Notification Methods
  Future<Map<String, dynamic>> getNotifications() async {
    try {
      final response = await _dio.get('/notifications');
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<void> markNotificationRead(String notificationId) async {
    try {
      await _dio.put('/notifications/$notificationId/read');
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<int> getNotificationUnreadCount() async {
    try {
      final response = await _dio.get('/notifications/unread-count');
      return response.data['unread_count'];
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  // Account Actions
  Future<void> deleteAccount() async {
    try {
      await _dio.delete('/users/account');
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<Map<String, dynamic>> getBlockedUsers() async {
    try {
      final response = await _dio.get('/users/blocked');
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<void> blockUser(String userId) async {
    try {
      await _dio.post('/users/block', data: {'user_id': userId});
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<void> unblockUser(String userId) async {
    try {
      await _dio.delete('/users/block/$userId');
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  // Emergency Methods
  Future<Map<String, dynamic>> sendEmergencyAlert({
    double? latitude,
    double? longitude,
  }) async {
    try {
      final response = await _dio.post('/emergency/alert', data: {
        'latitude': latitude,
        'longitude': longitude,
        'timestamp': DateTime.now().toIso8601String(),
      });
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  // Report & Support Methods
  Future<void> reportUser({
    required String reportedUserId,
    required String reason,
    String? description,
  }) async {
    try {
      await _dio.post('/support/report', data: {
        'reported_user_id': reportedUserId,
        'reason': reason,
        'description': description,
      });
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<void> sendSupportRequest({
    required String subject,
    required String message,
  }) async {
    try {
      await _dio.post('/support/support', data: {
        'subject': subject,
        'message': message,
      });
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<List<Map<String, dynamic>>> getFAQ() async {
    try {
      final response = await _dio.get('/support/faq');
      return List<Map<String, dynamic>>.from(response.data['faq']);
    } catch (e) {
      throw _handleError(e);
    }
  }
  // Feed Methods
  Future<Map<String, dynamic>> getFeedPhotos() async {
    try {
      final response = await _dio.get('/feed/photos');
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<void> likeFeedPhoto(String photoId, bool isLike) async {
    try {
      await _dio.post('/feed/photos/$photoId/like', data: {'is_like': isLike});
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  // Signaling Methods
  Future<void> sendSignalingMessage(Map<String, dynamic> message) async {
    try {
      await _dio.post('/calls/signaling', data: message);
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<void> saveCallHistory(Map<String, dynamic> callData) async {
    try {
      await _dio.post('/calls/history', data: callData);
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<List<Map<String, dynamic>>> getCallHistory() async {
    try {
      final response = await _dio.get('/calls/history');
      return List<Map<String, dynamic>>.from(response.data['calls'] ?? []);
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  // Features Methods
  Future<Map<String, dynamic>> activateBoost({
    int durationMinutes = 30,
    String boostType = 'free',
  }) async {
    try {
      final response = await _dio.post('/features/boost', data: {
        'duration_minutes': durationMinutes,
        'boost_type': boostType,
      });
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<Map<String, dynamic>> getBoostStatus() async {
    try {
      final response = await _dio.get('/features/boost/status');
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  Future<Map<String, dynamic>> getSortedMatches(String sortBy) async {
    try {
      final response = await _dio.get('/features/matches/sorted', queryParameters: {
        'sort_by': sortBy,
      });
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  // Verification Methods
  Future<Map<String, dynamic>> checkVerificationEligibility() async {
    try {
      final response = await _dio.get('/verification/check-eligibility');
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> requestVerification(String badgeColor) async {
    try {
      final response = await _dio.post('/verification/request', data: {
        'badge_color': badgeColor,
      });
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }

  Future<Map<String, dynamic>> getVerificationStatus() async {
    try {
      final response = await _dio.get('/verification/status');
      return response.data;
    } catch (e) {
      throw _handleError(e);
    }
  }
  
  String _handleError(dynamic error) {
    if (error is DioException) {
      if (error.response != null) {
        final data = error.response!.data;
        if (data is Map && data.containsKey('detail')) {
          return data['detail'];
        }
        return 'Server error: ${error.response!.statusCode}';
      }
      return 'Network error: ${error.message}';
    }
    return 'Unexpected error: $error';
  }
  
  bool get isAuthenticated => _token != null;
}