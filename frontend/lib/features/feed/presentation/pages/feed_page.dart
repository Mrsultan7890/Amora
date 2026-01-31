import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/api_service.dart';

class FeedPage extends StatefulWidget {
  const FeedPage({super.key});

  @override
  State<FeedPage> createState() => _FeedPageState();
}

class _FeedPageState extends State<FeedPage> {
  final ApiService _apiService = ApiService.instance;
  List<Map<String, dynamic>> _feedItems = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFeed();
  }

  Future<void> _loadFeed() async {
    setState(() => _isLoading = true);
    
    try {
      final response = await _apiService.getFeedPhotos();
      setState(() {
        _feedItems = List<Map<String, dynamic>>.from(response['feed_items'] ?? []);
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading feed: $e');
      setState(() {
        _feedItems = [];
        _isLoading = false;
      });
    }
  }



  Future<void> _toggleLike(String itemId) async {
    final index = _feedItems.indexWhere((item) => item['id'] == itemId);
    if (index == -1) return;

    final isLiked = _feedItems[index]['is_liked'] ?? false;
    final currentLikes = _feedItems[index]['likes_count'] ?? 0;
    
    // Optimistic update
    setState(() {
      _feedItems[index]['is_liked'] = !isLiked;
      _feedItems[index]['likes_count'] = isLiked ? currentLikes - 1 : currentLikes + 1;
    });

    try {
      final response = await _apiService.likeFeedPhoto(itemId, !isLiked);
      
      // Update with real count from server
      if (response['success'] == true && response['likes_count'] != null) {
        setState(() {
          _feedItems[index]['likes_count'] = response['likes_count'];
        });
      }
    } catch (e) {
      // Revert on error
      setState(() {
        _feedItems[index]['is_liked'] = isLiked;
        _feedItems[index]['likes_count'] = currentLikes;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to update like. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
                    const Text(
                      'Feed',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AmoraTheme.deepMidnight,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: _loadFeed,
                      icon: const Icon(Icons.refresh, color: AmoraTheme.deepMidnight),
                    ),
                  ],
                ),
              ),
              
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AmoraTheme.sunsetRose)))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: _feedItems.length,
                        itemBuilder: (context, index) => _buildFeedItem(_feedItems[index], index),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeedItem(Map<String, dynamic> item, int index) {
    final isLiked = item['is_liked'] ?? false;
    final likesCount = item['likes_count'] ?? 0;
    final compatibilityScore = item['compatibility_score'] ?? 0;
    final commonInterests = item['common_interests'] ?? 0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: AmoraTheme.glassmorphism(color: Colors.white, borderRadius: 20),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AmoraTheme.sunsetRose,
                  child: Text(
                    item['user_name']?[0]?.toUpperCase() ?? 'U', 
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${item['user_name']}, ${item['user_age']}', 
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AmoraTheme.deepMidnight)
                      ),
                      if (item['location'] != null)
                        Text(
                          '📍 ${item['location']}',
                          style: TextStyle(fontSize: 12, color: AmoraTheme.deepMidnight.withOpacity(0.6))
                        ),
                    ],
                  ),
                ),
                if (commonInterests > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AmoraTheme.sunsetRose.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$commonInterests common',
                      style: const TextStyle(fontSize: 10, color: AmoraTheme.sunsetRose, fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
          ),
          
          AspectRatio(
            aspectRatio: 3/4,
            child: CachedNetworkImage(
              imageUrl: item['photo_url'] ?? '',
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(
                color: AmoraTheme.offWhite, 
                child: const Center(child: CircularProgressIndicator(color: AmoraTheme.sunsetRose))
              ),
              errorWidget: (context, url, error) => Container(
                color: AmoraTheme.offWhite, 
                child: const Icon(Icons.photo, size: 64, color: AmoraTheme.deepMidnight)
              ),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _toggleLike(item['id']),
                  child: Row(
                    children: [
                      Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border, 
                        color: isLiked ? AmoraTheme.sunsetRose : AmoraTheme.deepMidnight,
                        size: 24,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$likesCount', 
                        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16)
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                if (compatibilityScore > 50)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: AmoraTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      '✨ Great Match',
                      style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: (100 * index).ms).slideY(begin: 0.3, end: 0);
  }
}