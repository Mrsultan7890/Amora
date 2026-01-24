import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/database_service.dart';
import '../../../../shared/models/match_model.dart';
import '../../../../shared/models/user_model.dart';

class MatchesPage extends StatefulWidget {
  const MatchesPage({super.key});

  @override
  State<MatchesPage> createState() => _MatchesPageState();
}

class _MatchesPageState extends State<MatchesPage> {
  final DatabaseService _databaseService = DatabaseService.instance;
  List<MatchModel> _matches = [];
  Map<String, UserModel> _users = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMatches();
  }

  Future<void> _loadMatches() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = _databaseService.currentUser;
      if (currentUser != null) {
        final matches = await _databaseService.getMatches(currentUser.id);
        
        // Load user data for each match
        final Map<String, UserModel> users = {};
        for (final match in matches) {
          final otherUserId = match.getOtherUserId(currentUser.id);
          // In a real app, you'd fetch user data from database
          // For now, creating mock data
          users[otherUserId] = UserModel(
            id: otherUserId,
            email: 'user@example.com',
            name: 'Match ${otherUserId.substring(0, 5)}',
            age: 25,
            gender: 'Woman',
            photos: ['https://via.placeholder.com/300'],
            bio: 'Hello there!',
            interests: ['Travel', 'Music'],
            isVerified: true,
            isOnline: true,
            lastSeen: DateTime.now(),
            createdAt: DateTime.now(),
          );
        }
        
        setState(() {
          _matches = matches;
          _users = users;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
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
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: AmoraTheme.glassmorphism(
                        color: Colors.white,
                        borderRadius: 16,
                      ),
                      child: const Icon(
                        Icons.search,
                        color: AmoraTheme.deepMidnight,
                      ),
                    ),
                    
                    const Text(
                      'Matches',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AmoraTheme.deepMidnight,
                      ),
                    ),
                    
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: AmoraTheme.glassmorphism(
                        color: Colors.white,
                        borderRadius: 16,
                      ),
                      child: const Icon(
                        Icons.filter_list,
                        color: AmoraTheme.deepMidnight,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Content
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AmoraTheme.sunsetRose,
                          ),
                        ),
                      )
                    : _matches.isEmpty
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
                                  'No matches yet',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: AmoraTheme.deepMidnight,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Start swiping to find your perfect match',
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
                            itemCount: _matches.length,
                            itemBuilder: (context, index) {
                              final match = _matches[index];
                              final currentUser = _databaseService.currentUser!;
                              final otherUserId = match.getOtherUserId(currentUser.id);
                              final otherUser = _users[otherUserId];
                              
                              if (otherUser == null) return const SizedBox.shrink();
                              
                              return _buildMatchCard(match, otherUser, index);
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMatchCard(MatchModel match, UserModel user, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: AmoraTheme.glassmorphism(
        color: Colors.white,
        borderRadius: 20,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Stack(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundImage: user.primaryPhoto.isNotEmpty
                  ? CachedNetworkImageProvider(user.primaryPhoto)
                  : null,
              child: user.primaryPhoto.isEmpty
                  ? const Icon(Icons.person, size: 28)
                  : null,
            ),
            if (user.isOnline)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 16,
                  height: 16,
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
        title: Row(
          children: [
            Text(
              user.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AmoraTheme.deepMidnight,
              ),
            ),
            if (user.isVerified) ...[
              const SizedBox(width: 4),
              const Icon(
                Icons.verified,
                color: AmoraTheme.warmGold,
                size: 16,
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (match.lastMessage != null) ...[
              const SizedBox(height: 4),
              Text(
                match.lastMessage!,
                style: TextStyle(
                  fontSize: 14,
                  color: AmoraTheme.deepMidnight.withOpacity(0.7),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ] else ...[
              const SizedBox(height: 4),
              Text(
                'Say hello to ${user.name}!',
                style: const TextStyle(
                  fontSize: 14,
                  color: AmoraTheme.sunsetRose,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
            const SizedBox(height: 4),
            Text(
              _getTimeText(match.lastMessageAt),
              style: TextStyle(
                fontSize: 12,
                color: AmoraTheme.deepMidnight.withOpacity(0.5),
              ),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: AmoraTheme.primaryGradient,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.chat_bubble,
            color: Colors.white,
            size: 20,
          ),
        ),
        onTap: () {
          // Navigate to chat screen
          _openChat(match, user);
        },
      ),
    ).animate()
      .fadeIn(delay: (index * 100).ms, duration: 600.ms)
      .slideX(begin: 0.3, end: 0);
  }

  String _getTimeText(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'Now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${(difference.inDays / 7).floor()}w ago';
    }
  }

  void _openChat(MatchModel match, UserModel user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Column(
              children: [
                // Handle
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                
                // Chat header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey.withOpacity(0.2),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 20,
                        backgroundImage: user.primaryPhoto.isNotEmpty
                            ? CachedNetworkImageProvider(user.primaryPhoto)
                            : null,
                        child: user.primaryPhoto.isEmpty
                            ? const Icon(Icons.person)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            Text(
                              user.isOnline ? 'Online' : 'Last seen ${_getTimeText(user.lastSeen)}',
                              style: TextStyle(
                                fontSize: 12,
                                color: user.isOnline ? Colors.green : Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                
                // Chat messages (placeholder)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.chat_bubble_outline,
                          size: 48,
                          color: AmoraTheme.sunsetRose,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Start a conversation with ${user.name}',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: AmoraTheme.deepMidnight,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Say something nice!',
                          style: TextStyle(
                            fontSize: 14,
                            color: AmoraTheme.deepMidnight.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Message input
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: Colors.grey.withOpacity(0.2),
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: const TextField(
                            decoration: InputDecoration(
                              hintText: 'Type a message...',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Container(
                        decoration: const BoxDecoration(
                          gradient: AmoraTheme.primaryGradient,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: () {
                            // Send message
                          },
                          icon: const Icon(
                            Icons.send,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}