import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/api_service.dart';
import '../../../../shared/models/match_model.dart';

class MatchesPage extends StatefulWidget {
  const MatchesPage({super.key});

  @override
  State<MatchesPage> createState() => _MatchesPageState();
}

class _MatchesPageState extends State<MatchesPage> {
  final ApiService _apiService = ApiService.instance;
  List<MatchModel> _matches = [];
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
      final matches = await _apiService.getMatches();
      setState(() {
        _matches = matches;
        _isLoading = false;
      });
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
                              return _buildMatchCard(match, index);
                            },
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMatchCard(MatchModel match, int index) {
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
            const CircleAvatar(
              radius: 28,
              child: Icon(Icons.person, size: 28),
            ),
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
              'Match ${match.id.substring(0, 8)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AmoraTheme.deepMidnight,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.verified,
              color: AmoraTheme.warmGold,
              size: 16,
            ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              match.lastMessage ?? 'Say hello to start the conversation!',
              style: TextStyle(
                fontSize: 14,
                color: match.lastMessage != null 
                    ? AmoraTheme.deepMidnight.withOpacity(0.7)
                    : AmoraTheme.sunsetRose,
                fontWeight: match.lastMessage != null 
                    ? FontWeight.normal 
                    : FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
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
          decoration: const BoxDecoration(
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
          _openChat(match);
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

  void _openChat(MatchModel match) {
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
                      const CircleAvatar(
                        radius: 20,
                        child: Icon(Icons.person),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Match ${match.id.substring(0, 8)}',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const Text(
                              'Online',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green,
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
                
                // Chat messages
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
                          'Start a conversation',
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
                            // Send message functionality
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