import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/api_service.dart';
import '../../../../shared/models/user_model.dart';
import '../../../../shared/widgets/photo_gallery_viewer.dart';

class ProfileViewScreen extends StatefulWidget {
  final String userId;
  final String? userName;

  const ProfileViewScreen({
    super.key,
    required this.userId,
    this.userName,
  });

  @override
  State<ProfileViewScreen> createState() => _ProfileViewScreenState();
}

class _ProfileViewScreenState extends State<ProfileViewScreen> {
  final ApiService _apiService = ApiService.instance;
  final PageController _pageController = PageController();
  
  UserModel? _user;
  bool _isLoading = true;
  int _currentPhotoIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    try {
      final user = await _apiService.getUserProfile(widget.userId);
      setState(() {
        _user = user;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to load profile: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(AmoraTheme.sunsetRose),
              ),
            )
          : _user == null
              ? const Center(
                  child: Text(
                    'Profile not found',
                    style: TextStyle(color: Colors.white, fontSize: 18),
                  ),
                )
              : _buildProfileView(),
    );
  }

  Widget _buildProfileView() {
    final photos = _user!.photos.isNotEmpty ? _user!.photos : [''];
    
    return Stack(
      children: [
        // Photo Gallery
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PhotoGalleryViewer(
                  photos: photos,
                  initialIndex: _currentPhotoIndex,
                  userName: _user!.name,
                ),
              ),
            );
          },
          child: PageView.builder(
            controller: _pageController,
            itemCount: photos.length,
            onPageChanged: (index) {
              setState(() {
                _currentPhotoIndex = index;
              });
            },
            itemBuilder: (context, index) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  image: photos[index].isNotEmpty
                      ? DecorationImage(
                          image: NetworkImage(photos[index]),
                          fit: BoxFit.cover,
                          onError: (error, stackTrace) {
                            // Handle image load error
                          },
                        )
                      : null,
                ),
                child: photos[index].isEmpty
                    ? const Center(
                        child: Icon(
                          Icons.person,
                          size: 120,
                          color: Colors.white54,
                        ),
                      )
                    : null,
              );
            },
          ),
        ),

        // Photo indicators
        if (photos.length > 1)
          Positioned(
            top: 60,
            left: 16,
            right: 16,
            child: Row(
              children: photos.asMap().entries.map((entry) {
                return Expanded(
                  child: Container(
                    height: 3,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      color: _currentPhotoIndex == entry.key
                          ? Colors.white
                          : Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

        // Back button
        Positioned(
          top: 50,
          left: 16,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(
                Icons.arrow_back_ios,
                color: Colors.white,
              ),
            ),
          ),
        ),

        // More options
        Positioned(
          top: 50,
          right: 16,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: PopupMenuButton(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'report',
                  child: Text('Report User'),
                ),
                const PopupMenuItem(
                  value: 'block',
                  child: Text('Block User'),
                ),
              ],
              onSelected: (value) {
                if (value == 'report') {
                  _showReportDialog();
                } else if (value == 'block') {
                  _showBlockDialog();
                }
              },
            ),
          ),
        ),

        // Profile info overlay
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.8),
                  Colors.black,
                ],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Name and age
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${_user!.name}, ${_user!.age}',
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        if (_user!.isVerified)
                          const Icon(
                            Icons.verified,
                            color: AmoraTheme.warmGold,
                            size: 24,
                          ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Job and education
                    if ((_user!.job?.isNotEmpty == true) || 
                        (_user!.education?.isNotEmpty == true))
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_user!.job?.isNotEmpty == true)
                            Row(
                              children: [
                                const Icon(
                                  Icons.work_outline,
                                  color: Colors.white70,
                                  size: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  _user!.job!,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                          if (_user!.education?.isNotEmpty == true)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.school_outlined,
                                    color: Colors.white70,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    _user!.education!,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      color: Colors.white70,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          const SizedBox(height: 12),
                        ],
                      ),

                    // Bio
                    if (_user!.bio.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _user!.bio,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                      ),

                    // Interests
                    if (_user!.interests.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Interests',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _user!.interests.map((interest) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  gradient: AmoraTheme.primaryGradient,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  interest,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Tap areas for photo navigation
        if (photos.length > 1) ...[
          // Left tap area
          Positioned(
            left: 0,
            top: 100,
            bottom: 200,
            width: MediaQuery.of(context).size.width * 0.3,
            child: GestureDetector(
              onTap: () {
                if (_currentPhotoIndex > 0) {
                  _pageController.previousPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
              },
              child: Container(color: Colors.transparent),
            ),
          ),
          // Right tap area
          Positioned(
            right: 0,
            top: 100,
            bottom: 200,
            width: MediaQuery.of(context).size.width * 0.3,
            child: GestureDetector(
              onTap: () {
                if (_currentPhotoIndex < photos.length - 1) {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                  );
                }
              },
              child: Container(color: Colors.transparent),
            ),
          ),
        ],
      ],
    );
  }

  void _showReportDialog() {
    String selectedReason = 'Inappropriate behavior';
    final TextEditingController descriptionController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            'Report User',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Why are you reporting ${_user!.name}?',
                style: const TextStyle(
                  color: AmoraTheme.deepMidnight,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: selectedReason,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
                items: [
                  'Inappropriate behavior',
                  'Fake profile',
                  'Harassment',
                  'Spam',
                  'Inappropriate photos',
                  'Other'
                ].map((reason) => DropdownMenuItem(
                  value: reason,
                  child: Text(reason),
                )).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedReason = value!;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  hintText: 'Additional details (optional)',
                  contentPadding: EdgeInsets.all(12),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  color: AmoraTheme.deepMidnight,
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await _submitReport(selectedReason, descriptionController.text);
                },
                child: const Text(
                  'Report',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _submitReport(String reason, String description) async {
    try {
      await _apiService.reportUser(
        reportedUserId: widget.userId,
        reason: reason,
        description: description.isNotEmpty ? description : null,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Report submitted for ${_user!.name}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit report: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showBlockDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Block User',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        content: Text(
          'Are you sure you want to block ${_user!.name}? You won\'t see their profile anymore and they won\'t be able to contact you.',
          style: const TextStyle(
            color: AmoraTheme.deepMidnight,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: AmoraTheme.deepMidnight,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _blockUser();
              },
              child: const Text(
                'Block',
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
  
  Future<void> _blockUser() async {
    try {
      await _apiService.blockUser(widget.userId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${_user!.name} has been blocked'),
            backgroundColor: Colors.red,
          ),
        );
        Navigator.pop(context); // Go back after blocking
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to block user: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}