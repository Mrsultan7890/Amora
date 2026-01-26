import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/api_service.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/models/match_model.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with TickerProviderStateMixin {
  final ApiService _apiService = ApiService.instance;
  late TabController _tabController;
  UserModel? _currentUser;
  List<Map<String, dynamic>> _likes = [];
  List<MatchModel> _matches = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = await _apiService.getCurrentUser();
      
      // Load likes and matches separately with error handling
      List<Map<String, dynamic>> likes = [];
      List<MatchModel> matches = [];
      
      try {
        likes = await _apiService.getUserLikes();
      } catch (e) {
        print('Error loading likes: $e');
        // Continue without likes data
      }
      
      try {
        matches = await _apiService.getMatches();
      } catch (e) {
        print('Error loading matches: $e');
        // Continue without matches data
      }
      
      setState(() {
        _currentUser = user;
        _likes = likes;
        _matches = matches;
        _isLoading = false;
      });
      print('Profile loaded: ${user.photos.length} photos, ${likes.length} likes, ${matches.length} matches');
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error loading user data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AmoraTheme.sunsetRose),
          ),
        ),
      );
    }

    if (_currentUser == null) {
      return const Scaffold(
        body: Center(
          child: Text('Failed to load profile'),
        ),
      );
    }

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AmoraTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () => context.go('/settings'),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: AmoraTheme.glassmorphism(
                            color: Colors.white,
                            borderRadius: 16,
                          ),
                          child: const Icon(
                            Icons.settings,
                            color: AmoraTheme.deepMidnight,
                          ),
                        ),
                      ),
                      
                      const Text(
                        'Profile',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AmoraTheme.deepMidnight,
                        ),
                      ),
                      
                      GestureDetector(
                        onTap: () => context.go('/edit-profile'),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: AmoraTheme.glassmorphism(
                            color: Colors.white,
                            borderRadius: 16,
                          ),
                          child: const Icon(
                            Icons.edit,
                            color: AmoraTheme.deepMidnight,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Profile card
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: AmoraTheme.glassmorphism(
                    color: Colors.white,
                    borderRadius: 24,
                  ),
                  child: Column(
                    children: [
                      // Profile image and basic info
                      Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          children: [
                            Stack(
                              children: [
                                Container(
                                  width: 120,
                                  height: 120,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: AmoraTheme.primaryGradient,
                                  ),
                                  child: _currentUser!.photos.isNotEmpty
                                      ? ClipOval(
                                          child: CachedNetworkImage(
                                            imageUrl: _currentUser!.photos.first,
                                            width: 120,
                                            height: 120,
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) => Container(
                                              width: 120,
                                              height: 120,
                                              decoration: const BoxDecoration(
                                                shape: BoxShape.circle,
                                                gradient: AmoraTheme.primaryGradient,
                                              ),
                                              child: const Center(
                                                child: CircularProgressIndicator(
                                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                                ),
                                              ),
                                            ),
                                            errorWidget: (context, url, error) {
                                              print('Profile image error: $error');
                                              print('Image URL: $url');
                                              return const Icon(
                                                Icons.person,
                                                size: 60,
                                                color: Colors.white,
                                              );
                                            },
                                          ),
                                        )
                                      : const Icon(
                                          Icons.person,
                                          size: 60,
                                          color: Colors.white,
                                        ),
                                ),
                                Positioned(
                                  bottom: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: AmoraTheme.warmGold,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.verified,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ],
                            ).animate()
                              .scale(duration: 800.ms, curve: Curves.elasticOut),
                            
                            const SizedBox(height: 16),
                            
                            Text(
                              '${_currentUser!.name}, ${_currentUser!.age}',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: AmoraTheme.deepMidnight,
                              ),
                            ).animate()
                              .fadeIn(delay: 200.ms, duration: 800.ms),
                            
                            const SizedBox(height: 4),
                            Text(
                              _currentUser!.job ?? 'No job specified',
                              style: const TextStyle(
                                fontSize: 16,
                                color: AmoraTheme.deepMidnight,
                              ),
                            ).animate()
                              .fadeIn(delay: 400.ms, duration: 800.ms),
                            
                            const SizedBox(height: 16),
                            
                            // Stats
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildStatItem('Photos', '${_currentUser!.photos.length}'),
                                _buildStatItem('Matches', '${_matches.length}'),
                                _buildStatItem('Likes', '${_likes.length}'),
                              ],
                            ).animate()
                              .fadeIn(delay: 600.ms, duration: 800.ms),
                          ],
                        ),
                      ),
                      
                      // Bio section
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AmoraTheme.offWhite,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'About Me',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AmoraTheme.deepMidnight,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _currentUser!.bio.isEmpty ? 'No bio added yet' : _currentUser!.bio,
                              style: const TextStyle(
                                fontSize: 16,
                                color: AmoraTheme.deepMidnight,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ).animate()
                        .fadeIn(delay: 800.ms, duration: 800.ms)
                        .slideY(begin: 0.3, end: 0),
                      
                      const SizedBox(height: 16),
                      
                      // Interests
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'My Interests',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AmoraTheme.deepMidnight,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _currentUser!.interests.isEmpty 
                                  ? [Text('No interests added yet', style: TextStyle(color: AmoraTheme.deepMidnight))]
                                  : _currentUser!.interests.map((interest) {
                                return Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: AmoraTheme.primaryGradient,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AmoraTheme.sunsetRose.withOpacity(0.3),
                                        blurRadius: 8,
                                        offset: const Offset(0, 4),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    interest,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: Colors.white,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      ).animate()
                        .fadeIn(delay: 1000.ms, duration: 800.ms),
                      
                      const SizedBox(height: 24),
                      
                      // Tabs
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          indicator: BoxDecoration(
                            gradient: AmoraTheme.primaryGradient,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          labelColor: Colors.white,
                          unselectedLabelColor: AmoraTheme.deepMidnight,
                          tabs: const [
                            Tab(text: 'Photos'),
                            Tab(text: 'Matches'),
                            Tab(text: 'Likes'),
                          ],
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Tab Content
                      SizedBox(
                        height: 300,
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildPhotosTab(),
                            _buildMatchesTab(),
                            _buildLikesTab(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Action buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: [
                      _buildActionButton(
                        icon: Icons.photo_library,
                        title: 'Manage Photos',
                        subtitle: 'Add or remove photos',
                        onTap: () async {
                          await context.push('/edit-profile');
                          _loadUserData(); // Refresh data when returning
                        },
                      ).animate()
                        .fadeIn(delay: 1200.ms, duration: 600.ms)
                        .slideX(begin: -0.3, end: 0),
                      
                      const SizedBox(height: 12),
                      
                      _buildActionButton(
                        icon: Icons.location_on,
                        title: 'Discovery Settings',
                        subtitle: 'Distance, age range, and more',
                        onTap: () => context.go('/settings'),
                      ).animate()
                        .fadeIn(delay: 1400.ms, duration: 600.ms)
                        .slideX(begin: -0.3, end: 0),
                      
                      const SizedBox(height: 12),
                      
                      _buildActionButton(
                        icon: Icons.logout,
                        title: 'Sign Out',
                        subtitle: 'Sign out of your account',
                        onTap: () {
                          _showSignOutDialog();
                        },
                        isDestructive: true,
                      ).animate()
                        .fadeIn(delay: 1600.ms, duration: 600.ms)
                        .slideX(begin: -0.3, end: 0),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AmoraTheme.sunsetRose,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: AmoraTheme.deepMidnight.withOpacity(0.7),
          ),
        ),
      ],
    );
  }

  Widget _buildPhotosTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: _currentUser!.photos.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.photo_library, size: 48, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No photos uploaded yet'),
                  Text('Add up to 6 photos to your profile'),
                ],
              ),
            )
          : GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _currentUser!.photos.length,
              itemBuilder: (context, index) {
                return Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    image: DecorationImage(
                      image: NetworkImage(_currentUser!.photos[index]),
                      fit: BoxFit.cover,
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildMatchesTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: _matches.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite, size: 48, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No matches yet'),
                  Text('Start swiping to find matches'),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _matches.length,
              itemBuilder: (context, index) {
                final match = _matches[index];
                return ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.person),
                  ),
                  title: Text(match.otherUser?.name ?? 'Unknown'),
                  subtitle: Text('Matched ${_formatDate(match.createdAt)}'),
                  trailing: const Icon(Icons.chat),
                );
              },
            ),
    );
  }

  Widget _buildLikesTab() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: _likes.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.thumb_up, size: 48, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No likes yet'),
                  Text('Keep swiping to get more likes'),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _likes.length,
              itemBuilder: (context, index) {
                final like = _likes[index];
                final user = UserModel.fromJson(like['user']);
                return ListTile(
                  leading: Stack(
                    children: [
                      const CircleAvatar(
                        child: Icon(Icons.person),
                      ),
                      if (like['is_super_like'] == true)
                        const Positioned(
                          bottom: 0,
                          right: 0,
                          child: Icon(
                            Icons.star,
                            color: Colors.amber,
                            size: 16,
                          ),
                        ),
                    ],
                  ),
                  title: Text(user.name),
                  subtitle: Text('Liked you ${_formatDate(DateTime.parse(like['created_at']))}'),
                  trailing: const Icon(Icons.favorite, color: Colors.red),
                );
              },
            ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inMinutes}m ago';
    }
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: AmoraTheme.glassmorphism(
          color: Colors.white,
          borderRadius: 16,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDestructive 
                    ? Colors.red.withOpacity(0.1)
                    : AmoraTheme.sunsetRose.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isDestructive ? Colors.red : AmoraTheme.sunsetRose,
                size: 24,
              ),
            ),
            
            const SizedBox(width: 16),
            
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDestructive ? Colors.red : AmoraTheme.deepMidnight,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: AmoraTheme.deepMidnight.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            
            Icon(
              Icons.arrow_forward_ios,
              color: AmoraTheme.deepMidnight.withOpacity(0.3),
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Sign Out',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AmoraTheme.deepMidnight,
          ),
        ),
        content: const Text(
          'Are you sure you want to sign out?',
          style: TextStyle(
            color: AmoraTheme.deepMidnight,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: AmoraTheme.deepMidnight,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: AmoraTheme.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                context.read<AuthBloc>().add(AuthSignOutRequested());
                context.go('/onboarding');
              },
              child: const Text(
                'Sign Out',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}