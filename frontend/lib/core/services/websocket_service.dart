import 'package:web_socket_channel/web_socket_channel.dart';
import 'dart:convert';
import '../constants/app_constants.dart';

class WebSocketService {
  static WebSocketService? _instance;
  static WebSocketService get instance => _instance ??= WebSocketService._();
  
  WebSocketService._();
  
  WebSocketChannel? _channel;
  String? _userId;
  
  // Callbacks
  Function(Map<String, dynamic>)? onSignalingMessage;
  Function(Map<String, dynamic>)? onNewMessage;
  
  String get wsUrl => AppConstants.wsBaseUrl;
  
  Future<void> connect(String userId) async {
    try {
      _userId = userId;
      final uri = Uri.parse('$wsUrl/$userId');
      print('Connecting to WebSocket: $uri');
      
      _channel = WebSocketChannel.connect(uri);
      
      _channel!.stream.listen(
        (data) {
          try {
            final message = jsonDecode(data);
            _handleMessage(message);
          } catch (e) {
            print('Error parsing WebSocket message: $e');
          }
        },
        onError: (error) {
          print('WebSocket error: $error');
          _reconnect();
        },
        onDone: () {
          print('WebSocket connection closed');
          _reconnect();
        },
      );
      
      print('WebSocket connected for user: $_userId');
    } catch (e) {
      print('Failed to connect WebSocket: $e');
      _reconnect();
    }
  }
  
  void _handleMessage(Map<String, dynamic> message) {
    print('Received message: $message');
    
    switch (message['type']) {
      case 'signaling':
        onSignalingMessage?.call(message['data']);
        break;
      case 'new_message':
        onNewMessage?.call(message);
        break;
      default:
        print('Unknown message type: ${message['type']}');
    }
  }
  
  void sendMessage(Map<String, dynamic> message) {
    if (_channel != null && isConnected) {
      try {
        _channel!.sink.add(jsonEncode(message));
      } catch (e) {
        print('Error sending WebSocket message: $e');
      }
    } else {
      print('WebSocket not connected, cannot send message');
    }
  }
  
  void _reconnect() {
    if (_userId != null) {
      Future.delayed(const Duration(seconds: 5), () {
        print('Attempting to reconnect WebSocket...');
        connect(_userId!);
      });
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