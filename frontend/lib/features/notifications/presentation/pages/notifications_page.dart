import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/api_service.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final ApiService _apiService = ApiService.instance;
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
      final response = await _apiService.getNotifications();
      print('Notifications response: $response');
      setState(() {
        _notifications = List<Map<String, dynamic>>.from(response['notifications'] ?? []);
        _isLoading = false;
      });
      print('Loaded ${_notifications.length} notifications');
    } catch (e) {
      print('Error loading notifications: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      await _apiService.markNotificationRead(notificationId);
      _loadNotifications();
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                      onPressed: () => Navigator.pop(context),
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
    );
  }

  Widget _buildNotificationItem(Map<String, dynamic> notification) {
    final isUnread = !(notification['read'] ?? false);
    final type = notification['type'] ?? 'general';
    
    IconData icon;
    Color iconColor;
    
    switch (type) {
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
      onTap: () {
        if (isUnread) {
          _markAsRead(notification['id']);
        }
      },
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