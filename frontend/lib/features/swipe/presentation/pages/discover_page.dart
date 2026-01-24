import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/database_service.dart';
import '../../../../shared/models/user_model.dart';

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> {
  final CardSwiperController _cardController = CardSwiperController();
  final DatabaseService _databaseService = DatabaseService.instance;
  
  List<UserModel> _profiles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfiles();
  }

  Future<void> _loadProfiles() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = _databaseService.currentUser;
      if (currentUser != null) {
        final profiles = await _databaseService.getDiscoverProfiles(
          currentUserId: currentUser.id,
          limit: 20,
        );
        
        setState(() {
          _profiles = profiles;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleSwipe(int index, CardSwiperDirection direction) async {
    if (index >= _profiles.length) return;
    
    final currentUser = _databaseService.currentUser;
    if (currentUser == null) return;
    
    final swipedUser = _profiles[index];
    final isLike = direction == CardSwiperDirection.right;
    
    try {
      await _databaseService.createSwipe(
        swiperId: currentUser.id,
        swipedId: swipedUser.id,
        isLike: isLike,
      );
      
      // Check for match
      if (isLike) {
        final isMatch = await _databaseService.checkMatch(
          userId1: currentUser.id,
          userId2: swipedUser.id,
        );
        
        if (isMatch && mounted) {
          _showMatchDialog(swipedUser);
        }
      }
    } catch (e) {
      print('Error handling swipe: $e');
    }
  }

  void _showMatchDialog(UserModel matchedUser) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: AmoraTheme.glassmorphism(
            color: Colors.white,
            borderRadius: 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "It's a Match! 💕",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AmoraTheme.sunsetRose,
                ),
              ).animate()
                .scale(duration: 600.ms, curve: Curves.elasticOut),
              
              const SizedBox(height: 16),
              
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: _databaseService.currentUser?.primaryPhoto.isNotEmpty == true
                        ? CachedNetworkImageProvider(_databaseService.currentUser!.primaryPhoto)
                        : null,
                    child: _databaseService.currentUser?.primaryPhoto.isEmpty == true
                        ? const Icon(Icons.person, size: 40)
                        : null,
                  ),
                  
                  const SizedBox(width: 16),
                  
                  const Icon(
                    Icons.favorite,
                    color: AmoraTheme.sunsetRose,
                    size: 32,
                  ).animate()
                    .scale(duration: 800.ms, curve: Curves.elasticOut)
                    .then()
                    .shimmer(duration: 1000.ms),
                  
                  const SizedBox(width: 16),
                  
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: matchedUser.primaryPhoto.isNotEmpty
                        ? CachedNetworkImageProvider(matchedUser.primaryPhoto)
                        : null,
                    child: matchedUser.primaryPhoto.isEmpty
                        ? const Icon(Icons.person, size: 40)
                        : null,
                  ),
                ],
              ).animate()
                .fadeIn(delay: 300.ms, duration: 800.ms),
              
              const SizedBox(height: 24),
              
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text(
                        'Keep Swiping',
                        style: TextStyle(
                          color: AmoraTheme.deepMidnight,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: AmoraTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          // Navigate to chat
                        },
                        child: const Text(
                          'Say Hello',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ).animate()
                .fadeIn(delay: 600.ms, duration: 800.ms),
            ],
          ),
        ),
      ),
    );
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
                        Icons.tune,
                        color: AmoraTheme.deepMidnight,
                      ),
                    ),
                    
                    const Text(
                      'Discover',
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
                        Icons.notifications_outlined,
                        color: AmoraTheme.deepMidnight,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Cards
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AmoraTheme.sunsetRose,
                          ),
                        ),
                      )
                    : _profiles.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.favorite_outline,
                                  size: 64,
                                  color: AmoraTheme.sunsetRose,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  'No more profiles',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w600,
                                    color: AmoraTheme.deepMidnight,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Check back later for new matches',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: AmoraTheme.deepMidnight.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: CardSwiper(
                              controller: _cardController,
                              cardsCount: _profiles.length,
                              onSwipe: _handleSwipe,
                              cardBuilder: (context, index, percentThresholdX, percentThresholdY) {
                                return _buildProfileCard(_profiles[index]);
                              },
                            ),
                          ),
              ),
              
              // Action buttons
              if (!_isLoading && _profiles.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Pass button
                      GestureDetector(
                        onTap: () => _cardController.swipe(CardSwiperDirection.left),
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: AmoraTheme.glassmorphism(
                            color: Colors.white,
                            borderRadius: 28,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.red,
                            size: 28,
                          ),
                        ),
                      ).animate()
                        .scale(delay: 200.ms, duration: 600.ms, curve: Curves.elasticOut),
                      
                      // Super like button
                      GestureDetector(
                        onTap: () {
                          // TODO: Implement super like
                        },
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: AmoraTheme.glassmorphism(
                            color: Colors.white,
                            borderRadius: 24,
                          ),
                          child: const Icon(
                            Icons.star,
                            color: AmoraTheme.warmGold,
                            size: 24,
                          ),
                        ),
                      ).animate()
                        .scale(delay: 400.ms, duration: 600.ms, curve: Curves.elasticOut),
                      
                      // Like button
                      GestureDetector(
                        onTap: () => _cardController.swipe(CardSwiperDirection.right),
                        child: Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            gradient: AmoraTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: AmoraTheme.softShadow,
                          ),
                          child: const Icon(
                            Icons.favorite,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                      ).animate()
                        .scale(delay: 600.ms, duration: 600.ms, curve: Curves.elasticOut),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileCard(UserModel user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: AmoraTheme.softShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            // Background image
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                gradient: AmoraTheme.primaryGradient,
              ),
              child: user.primaryPhoto.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: user.primaryPhoto,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: AmoraTheme.offWhite,
                        child: const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AmoraTheme.sunsetRose,
                            ),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: AmoraTheme.offWhite,
                        child: const Icon(
                          Icons.person,
                          size: 100,
                          color: AmoraTheme.deepMidnight,
                        ),
                      ),
                    )
                  : const Center(
                      child: Icon(
                        Icons.person,
                        size: 100,
                        color: Colors.white,
                      ),
                    ),
            ),
            
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.7),
                  ],
                ),
              ),
            ),
            
            // User info
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${user.name}, ${user.age}',
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        if (user.isVerified)
                          const Icon(
                            Icons.verified,
                            color: AmoraTheme.warmGold,
                            size: 24,
                          ),
                      ],
                    ),
                    
                    if (user.job != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        user.job!,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                    
                    if (user.bio.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        user.bio,
                        style: const TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    
                    if (user.interests.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: user.interests.take(3).map((interest) {
                          return Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.white.withOpacity(0.3),
                              ),
                            ),
                            child: Text(
                              interest,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}