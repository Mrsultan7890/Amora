import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../profile/presentation/pages/profile_view_screen.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final ApiService _apiService = ApiService.instance;
  final NotificationService _notificationService = NotificationService.instance;
  List<Map<String, dynamic>> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      print('Loading notifications...');
      
      // Try to load from backend first
      try {
        final response = await _apiService.getNotifications();
        print('Backend notifications response: $response');
        setState(() {
          _notifications = List<Map<String, dynamic>>.from(response['notifications'] ?? []);
          _isLoading = false;
        });
        print('Loaded ${_notifications.length} notifications from backend');
        return;
      } catch (e) {
        print('Backend notifications failed: $e');
        // Fall back to local notifications
      }
      
      // Load from local notification service as fallback
      await _notificationService.initialize();
      final localNotifications = _notificationService.notifications;
      
      setState(() {
        _notifications = localNotifications.map((n) => {
          'id': n.id,
          'type': n.type.name,
          'title': n.title,
          'message': n.message,
          'timestamp': n.timestamp.toIso8601String(),
          'read': n.isRead,
        }).toList();
        _isLoading = false;
      });
      print('Loaded ${_notifications.length} local notifications');
      
    } catch (e) {
      print('Error loading notifications: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleNotificationTap(Map<String, dynamic> notification) async {
    final isUnread = !(notification['read'] ?? false);
    
    // Mark as read if unread
    if (isUnread) {
      await _markAsRead(notification['id']);
    }
    
    // Navigate to profile for all notification types
    _navigateToProfile(notification);
  }
  
  void _navigateToProfile(Map<String, dynamic> notification) {
    // Extract user_id from notification for feed_like type
    String? userId;
    
    if (notification['type'] == 'feed_like') {
      // For feed likes, extract user_id from notification id or message
      final notificationId = notification['id'] ?? '';
      if (notificationId.contains('feed_like_')) {
        final parts = notificationId.split('_');
        if (parts.length >= 3) {
          userId = parts[2]; // feed_like_{sender_id}_{photo_id}_{timestamp}
        }
      }
    }
    
    if (userId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProfileViewScreen(
            userId: userId!,
            userName: null, // Will be loaded by ProfileViewScreen
          ),
        ),
      );
    } else {
      // Fallback dialog for other notification types
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(notification['title'] ?? 'Notification'),
          content: Text(notification['message'] ?? ''),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    }
  }
  

  Future<void> _markAsRead(String notificationId) async {
    try {
      // Try backend first
      try {
        await _apiService.markNotificationRead(notificationId);
        print('Marked notification as read on backend');
      } catch (e) {
        print('Backend mark read failed: $e');
        // Fall back to local
        await _notificationService.markAsRead(notificationId);
        print('Marked notification as read locally');
      }
      
      _loadNotifications();
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      onPopInvoked: (didPop) async {
        if (didPop) {
          // Mark all as read when leaving page
          await _notificationService.markAllAsRead();
        }
      },
      child: Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AmoraTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () async {
                        await _notificationService.markAllAsRead();
                        Navigator.pop(context, true);
                      },
                      icon: const Icon(
                        Icons.arrow_back,
                        color: AmoraTheme.deepMidnight,
                      ),
                    ),
                    const Expanded(
                      child: Text(
                        'Notifications',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AmoraTheme.deepMidnight,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AmoraTheme.sunsetRose,
                          ),
                        ),
                      )
                    : _notifications.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.notifications_none,
                                  size: 64,
                                  color: AmoraTheme.deepMidnight,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'No notifications yet',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: AmoraTheme.deepMidnight,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'We\'ll notify you when something happens',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: AmoraTheme.deepMidnight.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _notifications.length,
                            itemBuilder: (context, index) {
                              final notification = _notifications[index];
                              return _buildNotificationItem(notification);
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> notification) {
    final isUnread = !(notification['read'] ?? false);
    final type = notification['type'] ?? 'general';
    
    IconData icon;
    Color iconColor;
    
    switch (type) {
      case 'feed_like':
        icon = Icons.favorite;
        iconColor = AmoraTheme.sunsetRose;
        break;
      case 'match':
        icon = Icons.favorite;
        iconColor = AmoraTheme.sunsetRose;
        break;
      case 'message':
        icon = Icons.message;
        iconColor = AmoraTheme.warmGold;
        break;
      case 'super_like':
        icon = Icons.star;
        iconColor = AmoraTheme.warmGold;
        break;
      default:
        icon = Icons.notifications;
        iconColor = AmoraTheme.deepMidnight;
    }

    return GestureDetector(
      onTap: () => _handleNotificationTap(notification),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isUnread ? AmoraTheme.offWhite : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isUnread 
                ? AmoraTheme.sunsetRose.withOpacity(0.2) 
                : Colors.grey.withOpacity(0.2),
          ),
          boxShadow: isUnread ? AmoraTheme.softShadow : null,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification['title'] ?? 'Notification',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isUnread ? FontWeight.bold : FontWeight.w500,
                      color: AmoraTheme.deepMidnight,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification['message'] ?? '',
                    style: TextStyle(
                      fontSize: 14,
                      color: AmoraTheme.deepMidnight.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatTime(notification['timestamp']),
                  style: TextStyle(
                    fontSize: 12,
                    color: AmoraTheme.deepMidnight.withOpacity(0.5),
                  ),
                ),
                if (isUnread) ...[
                  const SizedBox(height: 4),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AmoraTheme.sunsetRose,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: (100 * _notifications.indexOf(notification)).ms);
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return '';
    
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else {
        return '${difference.inDays}d ago';
      }
    } catch (e) {
      return '';
    }
  }
}