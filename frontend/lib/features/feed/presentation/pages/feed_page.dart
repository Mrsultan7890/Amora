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
      _generateSampleFeed();
    }
  }

  void _generateSampleFeed() {
    _feedItems = [
      {
        'id': '1',
        'user_name': 'Sarah',
        'user_age': 24,
        'photo_url': 'https://picsum.photos/400/600?random=1',
        'timestamp': DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
        'likes_count': 12,
        'is_liked': false,
      },
      {
        'id': '2', 
        'user_name': 'Alex',
        'user_age': 26,
        'photo_url': 'https://picsum.photos/400/600?random=2',
        'timestamp': DateTime.now().subtract(const Duration(hours: 5)).toIso8601String(),
        'likes_count': 8,
        'is_liked': true,
      },
    ];
    setState(() => _isLoading = false);
  }

  Future<void> _toggleLike(String itemId) async {
    final index = _feedItems.indexWhere((item) => item['id'] == itemId);
    if (index == -1) return;

    final isLiked = _feedItems[index]['is_liked'] ?? false;
    
    setState(() {
      _feedItems[index]['is_liked'] = !isLiked;
      _feedItems[index]['likes_count'] += isLiked ? -1 : 1;
    });
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
                  child: Text(item['user_name']?[0] ?? 'U', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Text('${item['user_name']}, ${item['user_age']}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AmoraTheme.deepMidnight)),
              ],
            ),
          ),
          
          AspectRatio(
            aspectRatio: 3/4,
            child: CachedNetworkImage(
              imageUrl: item['photo_url'] ?? '',
              fit: BoxFit.cover,
              placeholder: (context, url) => Container(color: AmoraTheme.offWhite, child: const Center(child: CircularProgressIndicator())),
              errorWidget: (context, url, error) => Container(color: AmoraTheme.offWhite, child: const Icon(Icons.photo, size: 64)),
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
                      Icon(isLiked ? Icons.favorite : Icons.favorite_border, color: isLiked ? AmoraTheme.sunsetRose : AmoraTheme.deepMidnight),
                      const SizedBox(width: 8),
                      Text('$likesCount', style: const TextStyle(fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: (100 * index).ms);
  }
}