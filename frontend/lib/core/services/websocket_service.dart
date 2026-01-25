import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'dart:convert';

class WebSocketService {
  static WebSocketService? _instance;
  static WebSocketService get instance => _instance ??= WebSocketService._();
  
  WebSocketService._();
  
  WebSocketChannel? _channel;
  String? _userId;
  
  String get wsUrl => dotenv.env['WS_BASE_URL'] ?? 'ws://localhost:8000/ws';
  
  Future<void> connect(String userId) async {
    try {
      _userId = userId;
      _channel = WebSocketChannel.connect(
        Uri.parse('$wsUrl/$userId'),
      );
      
      _channel!.stream.listen(
        (data) {
          final message = jsonDecode(data);
          _handleMessage(message);
        },
        onError: (error) {
          print('WebSocket error: $error');
        },
        onDone: () {
          print('WebSocket connection closed');
        },
      );
      
      print('WebSocket connected for user: $userId');
    } catch (e) {
      print('Failed to connect WebSocket: $e');
    }
  }
  
  void _handleMessage(Map<String, dynamic> message) {
    // Handle incoming messages
    print('Received message: $message');
  }
  
  void sendMessage(Map<String, dynamic> message) {
    if (_channel != null) {
      _channel!.sink.add(jsonEncode(message));
    }
  }
  
  Future<void> disconnect() async {
    await _channel?.sink.close();
    _channel = null;
    _userId = null;
    print('WebSocket disconnected');
  }
  
  bool get isConnected => _channel != null;
}