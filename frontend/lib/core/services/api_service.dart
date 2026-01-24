import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../shared/models/user_model.dart';
import '../../shared/models/match_model.dart';
import '../../shared/models/message_model.dart';

class ApiService {
  static ApiService? _instance;
  static ApiService get instance => _instance ??= ApiService._();
  
  ApiService._();
  
  late Dio _dio;
  String? _token;
  
  String get baseUrl => dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000/api';
  
  Future<void> initialize() async {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
      },
    ));
    
    // Add interceptors
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        if (_token != null) {
          options.headers['Authorization'] = 'Bearer $_token';
        }
        handler.next(options);
      },
      onError: (error, handler) {
        if (error.response?.statusCode == 401) {
          _clearToken();
        }
        handler.next(error);
      },
    ));
    
    await _loadToken();
  }
  
  Future<void> _loadToken() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
  }
  
  Future<void> _saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    _token = token;
  }
  
  Future<void> _clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    _token = null;
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
      final formData = FormData.fromMap({
        'username': email,
        'password': password,
      });
      
      final response = await _dio.post('/auth/login', data: formData);
      
      final token = response.data['access_token'];
      await _saveToken(token);
      
      return response.data;
    } catch (e) {
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
      final response = await _dio.get('/users/discover', queryParameters: {
        'page': page,
        'limit': limit,
      });
      
      return (response.data['users'] as List)
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
  Future<List<MatchModel>> getMatches() async {
    try {
      final response = await _dio.get('/matches/');
      
      return (response.data as List)
          .map((json) => MatchModel.fromJson(json))
          .toList();
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
  
  // Error handling
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