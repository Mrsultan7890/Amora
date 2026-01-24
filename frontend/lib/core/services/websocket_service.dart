import 'dart:convert';
import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../shared/models/message_model.dart';

class WebSocketService {
  static WebSocketService? _instance;
  static WebSocketService get instance => _instance ??= WebSocketService._();
  
  WebSocketService._();
  
  WebSocketChannel? _channel;
  StreamController<Map<String, dynamic>>? _messageController;
  String? _currentUserId;
  
  String get wsBaseUrl => dotenv.env['WS_BASE_URL'] ?? 'ws://localhost:8000/ws';
  
  Stream<Map<String, dynamic>>? get messageStream => _messageController?.stream;
  
  Future<void> connect(String userId) async {
    if (_channel != null) {
      await disconnect();
    }
    
    try {
      _currentUserId = userId;
      _messageController = StreamController<Map<String, dynamic>>.broadcast();
      
      _channel = WebSocketChannel.connect(
        Uri.parse('$wsBaseUrl/$userId'),
      );
      
      _channel!.stream.listen(
        (data) {
          try {
            final message = json.decode(data);
            _messageController?.add(message);
          } catch (e) {
            print('Error parsing WebSocket message: $e');
          }
        },
        onError: (error) {
          print('WebSocket error: $error');
          _handleConnectionError();
        },
        onDone: () {
          print('WebSocket connection closed');
          _handleConnectionClosed();
        },
      );
      
      print('WebSocket connected for user: $userId');
    } catch (e) {
      print('Failed to connect WebSocket: $e');
      throw Exception('Failed to connect to chat server');
    }
  }
  
  Future<void> disconnect() async {
    await _channel?.sink.close();
    _channel = null;
    await _messageController?.close();
    _messageController = null;
    _currentUserId = null;
    print('WebSocket disconnected');
  }
  
  void sendMessage({
    required String matchId,
    required String content,
    String messageType = 'text',
    String? imageUrl,
  }) {
    if (_channel == null) {
      throw Exception('WebSocket not connected');
    }
    
    final message = {
      'type': 'message',
      'match_id': matchId,
      'content': content,
      'message_type': messageType,
      'image_url': imageUrl,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    _channel!.sink.add(json.encode(message));
  }
  
  void sendTypingIndicator({
    required String matchId,
    required bool isTyping,
  }) {
    if (_channel == null) return;
    
    final message = {
      'type': 'typing',
      'match_id': matchId,
      'is_typing': isTyping,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    _channel!.sink.add(json.encode(message));
  }
  
  void sendReadReceipt({
    required String matchId,
    required String messageId,
  }) {
    if (_channel == null) return;
    
    final message = {
      'type': 'read_receipt',
      'match_id': matchId,
      'message_id': messageId,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    _channel!.sink.add(json.encode(message));
  }
  
  void _handleConnectionError() {
    if (_currentUserId != null) {
      Timer(const Duration(seconds: 5), () {
        connect(_currentUserId!);
      });
    }
  }
  
  void _handleConnectionClosed() {
    _messageController?.close();
    _messageController = null;
  }
  
  bool get isConnected => _channel != null;
  
  // Listen for specific message types
  Stream<MessageModel> get newMessages {
    return messageStream?.where((data) => data['type'] == 'message')
        .map((data) => MessageModel.fromWebSocket(data)) ?? const Stream.empty();
  }
  
  Stream<Map<String, dynamic>> get typingIndicators {
    return messageStream?.where((data) => data['type'] == 'typing') ?? const Stream.empty();
  }
  
  Stream<Map<String, dynamic>> get matchNotifications {
    return messageStream?.where((data) => data['type'] == 'new_match') ?? const Stream.empty();
  }
  
  Stream<Map<String, dynamic>> get userStatusUpdates {
    return messageStream?.where((data) => data['type'] == 'user_status') ?? const Stream.empty();
  }
}