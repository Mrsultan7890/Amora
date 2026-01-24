import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/api_service.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final ApiService _apiService = ApiService.instance;
  
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _jobController = TextEditingController();
  final _educationController = TextEditingController();
  
  List<String> _photos = [];
  List<String> _selectedInterests = [];
  bool _isLoading = false;
  bool _isUploadingPhoto = false;

  final List<String> _availableInterests = [
    'Travel', 'Music', 'Movies', 'Sports', 'Reading', 'Cooking',
    'Photography', 'Art', 'Gaming', 'Fitness', 'Dancing', 'Nature',
    'Technology', 'Fashion', 'Food', 'Animals', 'Adventure', 'Yoga'
  ];

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  void _loadUserData() {
    // Load current user data
    _nameController.text = 'Your Name';
    _bioController.text = 'Tell us about yourself...';
    _jobController.text = 'Software Developer';
    _educationController.text = 'University Graduate';
    _selectedInterests = ['Travel', 'Music', 'Photography'];
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _jobController.dispose();
    _educationController.dispose();
    super.dispose();
  }

  Future<void> _addPhoto() async {
    if (_photos.length >= 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum 6 photos allowed'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isUploadingPhoto = true;
    });

    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        final imageUrl = await _apiService.uploadImage(image.path);
        setState(() {
          _photos.add(imageUrl);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to upload photo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isUploadingPhoto = false;
      });
    }
  }

  void _removePhoto(int index) {
    setState(() {
      _photos.removeAt(index);
    });
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;
    
    setState(() {
      _isLoading = true;
    });

    try {
      await _apiService.updateProfile({
        'name': _nameController.text.trim(),
        'bio': _bioController.text.trim(),
        'job': _jobController.text.trim(),
        'education': _educationController.text.trim(),
        'photos': _photos,
        'interests': _selectedInterests,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/profile');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
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
                  children: [
                    IconButton(
                      onPressed: () => context.pop(),
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: AmoraTheme.deepMidnight,
                      ),
                    ),
                    
                    const Expanded(
                      child: Text(
                        'Edit Profile',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AmoraTheme.deepMidnight,
                        ),
                      ),
                    ),
                    
                    TextButton(
                      onPressed: _isLoading ? null : _saveProfile,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  AmoraTheme.sunsetRose,
                                ),
                              ),
                            )
                          : const Text(
                              'Save',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AmoraTheme.sunsetRose,
                              ),
                            ),
                    ),
                  ],
                ),
              ),
              
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Photos section
                        const Text(
                          'Photos',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AmoraTheme.deepMidnight,
                          ),
                        ).animate()
                          .fadeIn(duration: 600.ms),
                        
                        const SizedBox(height: 12),
                        
                        SizedBox(
                          height: 120,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _photos.length + 1,
                            itemBuilder: (context, index) {
                              if (index == _photos.length) {
                                // Add photo button
                                return GestureDetector(
                                  onTap: _isUploadingPhoto ? null : _addPhoto,
                                  child: Container(
                                    width: 100,
                                    margin: const EdgeInsets.only(right: 12),
                                    decoration: AmoraTheme.glassmorphism(
                                      color: Colors.white,
                                      borderRadius: 16,
                                    ),
                                    child: _isUploadingPhoto
                                        ? const Center(
                                            child: CircularProgressIndicator(
                                              valueColor: AlwaysStoppedAnimation<Color>(
                                                AmoraTheme.sunsetRose,
                                              ),
                                            ),
                                          )
                                        : const Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                Icons.add_photo_alternate,
                                                size: 32,
                                                color: AmoraTheme.sunsetRose,
                                              ),
                                              SizedBox(height: 4),
                                              Text(
                                                'Add Photo',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: AmoraTheme.sunsetRose,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                );
                              }
                              
                              // Photo item
                              return Container(
                                width: 100,
                                margin: const EdgeInsets.only(right: 12),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: AmoraTheme.softShadow,
                                  color: Colors.grey[300],
                                ),
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(16),
                                      child: Container(
                                        width: 100,
                                        height: 120,
                                        color: Colors.grey[300],
                                        child: const Icon(
                                          Icons.image,
                                          size: 40,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                    
                                    // Remove button
                                    Positioned(
                                      top: 4,
                                      right: 4,
                                      child: GestureDetector(
                                        onTap: () => _removePhoto(index),
                                        child: Container(
                                          padding: const EdgeInsets.all(4),
                                          decoration: const BoxDecoration(
                                            color: Colors.red,
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(
                                            Icons.close,
                                            color: Colors.white,
                                            size: 16,
                                          ),
                                        ),
                                      ),
                                    ),
                                    
                                    // Primary photo indicator
                                    if (index == 0)
                                      Positioned(
                                        bottom: 4,
                                        left: 4,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: AmoraTheme.warmGold,
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: const Text(
                                            'Main',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.white,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ).animate()
                                .fadeIn(delay: (index * 100).ms, duration: 600.ms)
                                .slideX(begin: 0.3, end: 0);
                            },
                          ),
                        ).animate()
                          .fadeIn(delay: 200.ms, duration: 600.ms),
                        
                        const SizedBox(height: 32),
                        
                        // Basic info
                        const Text(
                          'Basic Information',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AmoraTheme.deepMidnight,
                          ),
                        ).animate()
                          .fadeIn(delay: 400.ms, duration: 600.ms),
                        
                        const SizedBox(height: 16),
                        
                        _buildTextField(
                          controller: _nameController,
                          label: 'Name',
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter your name';
                            }
                            return null;
                          },
                        ).animate()
                          .fadeIn(delay: 600.ms, duration: 600.ms)
                          .slideY(begin: 0.3, end: 0),
                        
                        const SizedBox(height: 16),
                        
                        _buildTextField(
                          controller: _bioController,
                          label: 'Bio',
                          maxLines: 3,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please write something about yourself';
                            }
                            return null;
                          },
                        ).animate()
                          .fadeIn(delay: 800.ms, duration: 600.ms)
                          .slideY(begin: 0.3, end: 0),
                        
                        const SizedBox(height: 16),
                        
                        _buildTextField(
                          controller: _jobController,
                          label: 'Job Title',
                        ).animate()
                          .fadeIn(delay: 1000.ms, duration: 600.ms)
                          .slideY(begin: 0.3, end: 0),
                        
                        const SizedBox(height: 16),
                        
                        _buildTextField(
                          controller: _educationController,
                          label: 'Education',
                        ).animate()
                          .fadeIn(delay: 1200.ms, duration: 600.ms)
                          .slideY(begin: 0.3, end: 0),
                        
                        const SizedBox(height: 32),
                        
                        // Interests
                        const Text(
                          'Interests',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AmoraTheme.deepMidnight,
                          ),
                        ).animate()
                          .fadeIn(delay: 1400.ms, duration: 600.ms),
                        
                        const SizedBox(height: 12),
                        
                        Text(
                          'Select at least 3 interests',
                          style: TextStyle(
                            fontSize: 14,
                            color: AmoraTheme.deepMidnight.withOpacity(0.7),
                          ),
                        ).animate()
                          .fadeIn(delay: 1500.ms, duration: 600.ms),
                        
                        const SizedBox(height: 16),
                        
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: List.generate(_availableInterests.length, (index) {
                            final interest = _availableInterests[index];
                            final isSelected = _selectedInterests.contains(interest);
                            
                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  if (isSelected) {
                                    _selectedInterests.remove(interest);
                                  } else {
                                    _selectedInterests.add(interest);
                                  }
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: isSelected
                                    ? BoxDecoration(
                                        gradient: AmoraTheme.primaryGradient,
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: AmoraTheme.softShadow,
                                      )
                                    : AmoraTheme.glassmorphism(
                                        color: Colors.white,
                                        borderRadius: 20,
                                      ),
                                child: Text(
                                  interest,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: isSelected 
                                        ? Colors.white 
                                        : AmoraTheme.deepMidnight,
                                  ),
                                ),
                              ),
                            ).animate()
                              .fadeIn(delay: (1600 + index * 50).ms, duration: 400.ms)
                              .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1));
                          }),
                        ),
                        
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: AmoraTheme.glassmorphism(
        color: Colors.white,
        borderRadius: 16,
      ),
      child: TextFormField(
        controller: controller,
        maxLines: maxLines,
        validator: validator,
        decoration: InputDecoration(
          labelText: label,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(20),
          labelStyle: TextStyle(
            color: AmoraTheme.deepMidnight.withOpacity(0.7),
          ),
        ),
        style: const TextStyle(
          color: AmoraTheme.deepMidnight,
        ),
      ),
    );
  }
}