import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:async';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/api_service.dart';
import '../../../../shared/models/match_model.dart';
import '../../../../shared/models/message_model.dart';
import '../../../profile/presentation/pages/profile_view_screen.dart';

class ChatScreen extends StatefulWidget {
  final MatchModel match;

  const ChatScreen({
    super.key,
    required this.match,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<MessageModel> _messages = [];
  final ApiService _apiService = ApiService.instance;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadMessages();
    
    // Refresh messages every 5 seconds to catch emergency alerts
    Timer.periodic(const Duration(seconds: 5), (timer) {
      if (mounted) {
        _loadMessages();
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _loadCurrentUser() async {
    try {
      final user = await _apiService.getCurrentUser();
      setState(() {
        _currentUserId = user.id;
      });
    } catch (e) {
      print('Error loading current user: $e');
    }
  }

  Future<void> _loadMessages() async {
    try {
      final messages = await _apiService.getMessages(
        matchId: widget.match.id,
        skip: 0,
        limit: 50,
      );
      setState(() {
        _messages.clear();
        _messages.addAll(messages);
      });
      _scrollToBottom();
    } catch (e) {
      print('Error loading messages: $e');
      // Keep dummy messages for now
      setState(() {
        _messages.addAll([
          MessageModel(
            id: '1',
            matchId: widget.match.id,
            senderId: widget.match.otherUser?.id ?? '',
            senderName: widget.match.otherUser?.name ?? 'Unknown',
            content: 'Hey! Nice to match with you 😊',
            type: MessageType.text,
            isRead: true,
            createdAt: DateTime.now().subtract(const Duration(hours: 2)),
          ),
        ]);
      });
    }
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    final messageContent = _messageController.text.trim();
    _messageController.clear();

    // Send message via API
    _apiService.sendMessage(
      matchId: widget.match.id,
      content: messageContent,
      messageType: 'text',
    ).then((sentMessage) {
      setState(() {
        _messages.add(sentMessage);
      });
      _scrollToBottom();
    }).catchError((error) {
      print('Error sending message: $error');
      // Add message locally for now
      final message = MessageModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        matchId: widget.match.id,
        senderId: _currentUserId ?? 'unknown',
        senderName: 'You',
        content: messageContent,
        type: MessageType.text,
        isRead: false,
        createdAt: DateTime.now(),
      );

      setState(() {
        _messages.add(message);
      });
      _scrollToBottom();
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AmoraTheme.offWhite,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(
            Icons.arrow_back_ios,
            color: AmoraTheme.deepMidnight,
          ),
        ),
        title: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProfileViewScreen(
                  userId: widget.match.otherUser?.id ?? '',
                  userName: widget.match.otherUser?.name,
                ),
              ),
            );
          },
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: widget.match.otherUser?.photos.isNotEmpty == true
                        ? NetworkImage(widget.match.otherUser!.photos.first)
                        : null,
                    child: widget.match.otherUser?.photos.isEmpty != false
                        ? const Icon(Icons.person)
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: Colors.green,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.match.otherUser?.name ?? 'Unknown User',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AmoraTheme.deepMidnight,
                      ),
                    ),
                    const Text(
                      'Tap to view profile',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              // Video call functionality
            },
            icon: const Icon(
              Icons.videocam,
              color: AmoraTheme.sunsetRose,
            ),
          ),
          IconButton(
            onPressed: () {
              // Voice call functionality
            },
            icon: const Icon(
              Icons.call,
              color: AmoraTheme.sunsetRose,
            ),
          ),
          PopupMenuButton(
            icon: const Icon(
              Icons.more_vert,
              color: AmoraTheme.deepMidnight,
            ),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'profile',
                child: Text('View Profile'),
              ),
              const PopupMenuItem(
                value: 'block',
                child: Text('Block User'),
              ),
              const PopupMenuItem(
                value: 'report',
                child: Text('Report'),
              ),
            ],
            onSelected: (value) {
              if (value == 'profile') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfileViewScreen(
                      userId: widget.match.otherUser?.id ?? '',
                      userName: widget.match.otherUser?.name,
                    ),
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages
          Expanded(
            child: _messages.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: AmoraTheme.sunsetRose,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Start a conversation',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AmoraTheme.deepMidnight,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Say something nice to ${widget.match.otherUser?.name ?? 'your match'}!',
                          style: TextStyle(
                            fontSize: 14,
                            color: AmoraTheme.deepMidnight.withOpacity(0.7),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: _messages.length,
                    itemBuilder: (context, index) {
                      final message = _messages[index];
                      final isMe = _currentUserId != null && message.senderId == _currentUserId;
                      return _buildMessageBubble(message, isMe, index);
                    },
                  ),
          ),
          
          // Message input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      // Image picker functionality
                    },
                    icon: const Icon(
                      Icons.add,
                      color: AmoraTheme.sunsetRose,
                    ),
                  ),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AmoraTheme.offWhite,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _messageController,
                        decoration: const InputDecoration(
                          hintText: 'Type a message...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                        ),
                        maxLines: null,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      gradient: AmoraTheme.primaryGradient,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      onPressed: _sendMessage,
                      icon: const Icon(
                        Icons.send,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(MessageModel message, bool isMe, int index) {
    // Check if it's an emergency message
    final isEmergency = message.type == MessageType.emergency || 
                       message.senderId == 'system';
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: isEmergency 
          ? _buildEmergencyMessage(message, index)
          : Row(
              mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!isMe) ...[
                  CircleAvatar(
                    radius: 16,
                    backgroundImage: widget.match.otherUser?.photos.isNotEmpty == true
                        ? NetworkImage(widget.match.otherUser!.photos.first)
                        : null,
                    child: widget.match.otherUser?.photos.isEmpty != false
                        ? const Icon(Icons.person, size: 16)
                        : null,
                  ),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: isMe ? AmoraTheme.primaryGradient : null,
                      color: isMe ? null : Colors.white,
                      borderRadius: BorderRadius.circular(20).copyWith(
                        bottomLeft: isMe ? const Radius.circular(20) : const Radius.circular(4),
                        bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(20),
                      ),
                      boxShadow: AmoraTheme.softShadow,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          message.content,
                          style: TextStyle(
                            fontSize: 14,
                            color: isMe ? Colors.white : AmoraTheme.deepMidnight,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatTime(message.createdAt),
                          style: TextStyle(
                            fontSize: 10,
                            color: isMe 
                                ? Colors.white.withOpacity(0.7)
                                : AmoraTheme.deepMidnight.withOpacity(0.5),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 8),
                  const CircleAvatar(
                    radius: 16,
                    child: Icon(Icons.person, size: 16),
                  ),
                ],
              ],
            ),
    ).animate()
      .fadeIn(delay: (index * 50).ms, duration: 300.ms)
      .slideY(begin: 0.3, end: 0);
  }
  
  Widget _buildEmergencyMessage(MessageModel message, int index) {
    // Extract location from message content
    final locationMatch = RegExp(r'location (-?\d+\.\d+), (-?\d+\.\d+)')
        .firstMatch(message.content);
    final hasLocation = locationMatch != null;
    final latitude = hasLocation ? double.tryParse(locationMatch.group(1) ?? '') : null;
    final longitude = hasLocation ? double.tryParse(locationMatch.group(2) ?? '') : null;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border.all(color: Colors.red.shade200, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.warning,
                color: Colors.red.shade600,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'EMERGENCY ALERT',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            message.content,
            style: TextStyle(
              fontSize: 14,
              color: Colors.red.shade800,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (hasLocation && latitude != null && longitude != null) ...[
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => _openLocationInMap(latitude, longitude),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.location_on,
                      color: Colors.red.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'View Location on Map',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.open_in_new,
                      color: Colors.red.shade700,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            _formatTime(message.createdAt),
            style: TextStyle(
              fontSize: 12,
              color: Colors.red.shade600,
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }
  
  Future<void> _openLocationInMap(double latitude, double longitude) async {
    // Try different map URLs in order of preference
    final mapUrls = [
      // Google Maps (works on all platforms)
      'https://maps.google.com/?q=$latitude,$longitude',
      // Alternative Google Maps URL
      'https://www.google.com/maps/@$latitude,$longitude,15z',
      // OpenStreetMap (web fallback)
      'https://www.openstreetmap.org/?mlat=$latitude&mlon=$longitude&zoom=15',
    ];
    
    for (String mapUrl in mapUrls) {
      try {
        final uri = Uri.parse(mapUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return;
        }
      } catch (e) {
        print('Failed to open $mapUrl: $e');
        continue;
      }
    }
    
    // If all map URLs fail, show coordinates in a dialog
    if (mounted) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('📍 Emergency Location'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Location coordinates:'),
              const SizedBox(height: 8),
              SelectableText(
                'Latitude: $latitude\nLongitude: $longitude',
                style: const TextStyle(fontFamily: 'monospace'),
              ),
              const SizedBox(height: 12),
              const Text(
                'Copy these coordinates and paste in any map app.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}