import 'package:pocketbase/pocketbase.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PocketBaseService {
  static PocketBaseService? _instance;
  static PocketBaseService get instance => _instance ??= PocketBaseService._();
  
  PocketBaseService._();
  
  late PocketBase pb;
  
  // Replace with your PocketBase URL
  static const String baseUrl = 'YOUR_POCKETBASE_URL_HERE';
  
  Future<void> initialize() async {
    pb = PocketBase(baseUrl);
    
    // Load saved auth state
    final prefs = await SharedPreferences.getInstance();
    final authData = prefs.getString('auth_data');
    if (authData != null) {
      pb.authStore.loadFromJson(authData);
    }
    
    // Listen to auth changes
    pb.authStore.onChange.listen((token, model) async {
      if (token.isNotEmpty) {
        await prefs.setString('auth_data', pb.authStore.exportToCookieHeader());
      } else {
        await prefs.remove('auth_data');
      }
    });
  }
  
  // Auth Methods
  Future<RecordModel> signUp({
    required String email,
    required String password,
    required String name,
    required int age,
  }) async {
    final record = await pb.collection('users').create(body: {
      'email': email,
      'password': password,
      'passwordConfirm': password,
      'name': name,
      'age': age,
      'verified': false,
    });
    
    await pb.collection('users').authWithPassword(email, password);
    return record;
  }
  
  Future<RecordModel> signIn({
    required String email,
    required String password,
  }) async {
    final authData = await pb.collection('users').authWithPassword(email, password);
    return authData.record;
  }
  
  Future<void> signOut() async {
    pb.authStore.clear();
  }
  
  // Profile Methods
  Future<RecordModel> updateProfile({
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    return await pb.collection('users').update(userId, body: data);
  }
  
  Future<List<RecordModel>> getProfiles({
    int page = 1,
    int perPage = 10,
    String? filter,
  }) async {
    final result = await pb.collection('users').getList(
      page: page,
      perPage: perPage,
      filter: filter,
    );
    return result.items;
  }
  
  // Swipe Methods
  Future<RecordModel> createSwipe({
    required String swiperId,
    required String swipedId,
    required bool isLike,
  }) async {
    return await pb.collection('swipes').create(body: {
      'swiper': swiperId,
      'swiped': swipedId,
      'is_like': isLike,
      'created': DateTime.now().toIso8601String(),
    });
  }
  
  Future<bool> checkMatch({
    required String userId1,
    required String userId2,
  }) async {
    final result = await pb.collection('swipes').getList(
      filter: '(swiper = "$userId1" && swiped = "$userId2" && is_like = true) || (swiper = "$userId2" && swiped = "$userId1" && is_like = true)',
    );
    return result.items.length == 2;
  }
  
  // Chat Methods
  Future<RecordModel> createMatch({
    required String user1Id,
    required String user2Id,
  }) async {
    return await pb.collection('matches').create(body: {
      'user1': user1Id,
      'user2': user2Id,
      'created': DateTime.now().toIso8601String(),
    });
  }
  
  Future<RecordModel> sendMessage({
    required String matchId,
    required String senderId,
    required String message,
  }) async {
    return await pb.collection('messages').create(body: {
      'match': matchId,
      'sender': senderId,
      'message': message,
      'created': DateTime.now().toIso8601String(),
    });
  }
  
  Future<List<RecordModel>> getMessages({
    required String matchId,
    int page = 1,
    int perPage = 50,
  }) async {
    final result = await pb.collection('messages').getList(
      page: page,
      perPage: perPage,
      filter: 'match = "$matchId"',
      sort: '-created',
    );
    return result.items;
  }
  
  // Real-time subscriptions
  Stream<RecordSubscriptionEvent> subscribeToMessages(String matchId) {
    return pb.collection('messages').subscribe(
      filter: 'match = "$matchId"',
    );
  }
  
  // File upload
  Future<String> uploadFile(String filePath, String collection, String recordId) async {
    final record = await pb.collection(collection).update(recordId, files: [
      http.MultipartFile.fromPath('avatar', filePath),
    ]);
    return record.getStringValue('avatar');
  }
  
  // Get current user
  RecordModel? get currentUser => pb.authStore.model;
  bool get isAuthenticated => pb.authStore.isValid;
}