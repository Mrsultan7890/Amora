import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'api_service.dart';

enum NotificationType {
  newMatch,
  newMessage,
  profileLike,
  emergencyAlert,
}

class NotificationModel {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic>? data;

  NotificationModel({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.data,
  });

  NotificationModel copyWith({bool? isRead}) {
    return NotificationModel(
      id: id,
      type: type,
      title: title,
      message: message,
      timestamp: timestamp,
      isRead: isRead ?? this.isRead,
      data: data,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'title': title,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'data': data,
    };
  }

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      type: NotificationType.values.firstWhere((e) => e.name == json['type']),
      title: json['title'],
      message: json['message'],
      timestamp: DateTime.parse(json['timestamp']),
      isRead: json['isRead'] ?? false,
      data: json['data'],
    );
  }
}

class NotificationService {
  static NotificationService? _instance;
  static NotificationService get instance => _instance ??= NotificationService._();
  
  NotificationService._();
  
  static const String _notificationsKey = 'notifications';
  List<NotificationModel> _notifications = [];
  
  List<NotificationModel> get notifications => List.unmodifiable(_notifications);
  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  Future<void> initialize() async {
    await _loadNotifications();
    await _createSampleNotifications();
  }

  Future<void> _loadNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final notificationsJson = prefs.getString(_notificationsKey);
    
    if (notificationsJson != null) {
      final List<dynamic> notificationsList = jsonDecode(notificationsJson);
      _notifications = notificationsList
          .map((json) => NotificationModel.fromJson(json))
          .toList();
      _notifications.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    }
  }

  Future<void> _saveNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final notificationsJson = jsonEncode(
      _notifications.map((n) => n.toJson()).toList(),
    );
    await prefs.setString(_notificationsKey, notificationsJson);
  }

  Future<void> _createSampleNotifications() async {
    if (_notifications.isEmpty) {
      await addNotification(
        type: NotificationType.newMatch,
        title: 'New Match! 💕',
        message: 'You matched with Sarah',
      );
      
      await addNotification(
        type: NotificationType.newMessage,
        title: 'New Message',
        message: 'Alex sent you a message',
      );
      
      await addNotification(
        type: NotificationType.profileLike,
        title: 'Someone likes you! ❤️',
        message: 'Emma liked your profile',
      );
    }
  }

  Future<void> addNotification({
    required NotificationType type,
    required String title,
    required String message,
    Map<String, dynamic>? data,
  }) async {
    final notification = NotificationModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      type: type,
      title: title,
      message: message,
      timestamp: DateTime.now(),
      data: data,
    );

    _notifications.insert(0, notification);
    
    if (_notifications.length > 50) {
      _notifications = _notifications.take(50).toList();
    }
    
    await _saveNotifications();
  }

  Future<void> markAsRead(String notificationId) async {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
      await _saveNotifications();
    }
  }

  Future<void> markAllAsRead() async {
    _notifications = _notifications
        .map((n) => n.copyWith(isRead: true))
        .toList();
    await _saveNotifications();
  }
}