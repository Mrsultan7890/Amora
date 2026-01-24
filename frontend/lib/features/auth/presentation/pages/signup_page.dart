import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/auth_bloc.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final PageController _pageController = PageController();
  final _formKey = GlobalKey<FormState>();
  
  // Form controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _ageController = TextEditingController();
  
  // Form data
  String _selectedGender = '';
  List<String> _selectedInterests = [];
  bool _isPasswordVisible = false;
  int _currentStep = 0;

  final List<String> _genders = ['Man', 'Woman', 'Non-binary'];
  
  final List<String> _interests = [
    'Travel', 'Music', 'Movies', 'Sports', 'Reading', 'Cooking',
    'Photography', 'Art', 'Gaming', 'Fitness', 'Dancing', 'Nature',
    'Technology', 'Fashion', 'Food', 'Animals', 'Adventure', 'Yoga'
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _handleSignup();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _handleSignup() {
    if (_formKey.currentState!.validate() && 
        _selectedGender.isNotEmpty && 
        _selectedInterests.isNotEmpty) {
      context.read<AuthBloc>().add(
        AuthSignUpRequested(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          name: _nameController.text.trim(),
          age: int.parse(_ageController.text),
          gender: _selectedGender,
          interests: _selectedInterests,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            context.go('/discover');
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        child: Container(
          decoration: const BoxDecoration(
            gradient: AmoraTheme.backgroundGradient,
          ),
          child: SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Row(
                    children: [
                      if (_currentStep > 0)
                        IconButton(
                          onPressed: _previousStep,
                          icon: const Icon(
                            Icons.arrow_back_ios,
                            color: AmoraTheme.deepMidnight,
                          ),
                        )
                      else
                        IconButton(
                          onPressed: () => context.go('/onboarding'),
                          icon: const Icon(
                            Icons.close,
                            color: AmoraTheme.deepMidnight,
                          ),
                        ),
                      
                      Expanded(
                        child: LinearProgressIndicator(
                          value: (_currentStep + 1) / 3,
                          backgroundColor: Colors.grey.withOpacity(0.3),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AmoraTheme.sunsetRose,
                          ),
                        ),
                      ),
                      
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                
                // Content
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: (index) {
                        setState(() {
                          _currentStep = index;
                        });
                      },
                      children: [
                        _buildBasicInfoStep(),
                        _buildGenderStep(),
                        _buildInterestsStep(),
                      ],
                    ),
                  ),
                ),
                
                // Continue button
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      return Container(
                        width: double.infinity,
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: AmoraTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: AmoraTheme.softShadow,
                        ),
                        child: ElevatedButton(
                          onPressed: state is AuthLoading ? null : _nextStep,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          child: state is AuthLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text(
                                  _currentStep == 2 ? 'Create Account' : 'Continue',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBasicInfoStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Basic Information',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AmoraTheme.deepMidnight,
            ),
          ).animate()
            .fadeIn(duration: 800.ms)
            .slideY(begin: 0.3, end: 0),
          
          const SizedBox(height: 8),
          
          Text(
            'Tell us about yourself',
            style: TextStyle(
              fontSize: 16,
              color: AmoraTheme.deepMidnight.withOpacity(0.7),
            ),
          ).animate()
            .fadeIn(delay: 200.ms, duration: 800.ms),
          
          const SizedBox(height: 32),
          
          // Name field
          Container(
            decoration: AmoraTheme.glassmorphism(
              color: Colors.white,
              borderRadius: 16,
            ),
            child: TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(Icons.person_outlined),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(20),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your name';
                }
                return null;
              },
            ),
          ).animate()
            .fadeIn(delay: 400.ms, duration: 800.ms)
            .slideY(begin: 0.3, end: 0),
          
          const SizedBox(height: 20),
          
          // Email field
          Container(
            decoration: AmoraTheme.glassmorphism(
              color: Colors.white,
              borderRadius: 16,
            ),
            child: TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                prefixIcon: Icon(Icons.email_outlined),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(20),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your email';
                }
                if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                  return 'Please enter a valid email';
                }
                return null;
              },
            ),
          ).animate()
            .fadeIn(delay: 600.ms, duration: 800.ms)
            .slideY(begin: 0.3, end: 0),
          
          const SizedBox(height: 20),
          
          // Age field
          Container(
            decoration: AmoraTheme.glassmorphism(
              color: Colors.white,
              borderRadius: 16,
            ),
            child: TextFormField(
              controller: _ageController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Age',
                prefixIcon: Icon(Icons.cake_outlined),
                border: InputBorder.none,
                contentPadding: EdgeInsets.all(20),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your age';
                }
                final age = int.tryParse(value);
                if (age == null || age < 18 || age > 100) {
                  return 'Please enter a valid age (18-100)';
                }
                return null;
              },
            ),
          ).animate()
            .fadeIn(delay: 800.ms, duration: 800.ms)
            .slideY(begin: 0.3, end: 0),
          
          const SizedBox(height: 20),
          
          // Password field
          Container(
            decoration: AmoraTheme.glassmorphism(
              color: Colors.white,
              borderRadius: 16,
            ),
            child: TextFormField(
              controller: _passwordController,
              obscureText: !_isPasswordVisible,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outlined),
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible 
                        ? Icons.visibility_off 
                        : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(20),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a password';
                }
                if (value.length < 6) {
                  return 'Password must be at least 6 characters';
                }
                return null;
              },
            ),
          ).animate()
            .fadeIn(delay: 1000.ms, duration: 800.ms)
            .slideY(begin: 0.3, end: 0),
        ],
      ),
    );
  }

  Widget _buildGenderStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'I am a',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AmoraTheme.deepMidnight,
            ),
          ).animate()
            .fadeIn(duration: 800.ms)
            .slideY(begin: 0.3, end: 0),
          
          const SizedBox(height: 32),
          
          ...List.generate(_genders.length, (index) {
            final gender = _genders[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _selectedGender = gender;
                  });
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: _selectedGender == gender
                      ? BoxDecoration(
                          gradient: AmoraTheme.primaryGradient,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: AmoraTheme.softShadow,
                        )
                      : AmoraTheme.glassmorphism(
                          color: Colors.white,
                          borderRadius: 16,
                        ),
                  child: Text(
                    gender,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: _selectedGender == gender 
                          ? Colors.white 
                          : AmoraTheme.deepMidnight,
                    ),
                  ),
                ),
              ).animate()
                .fadeIn(delay: (index * 200).ms, duration: 800.ms)
                .slideX(begin: 0.3, end: 0),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildInterestsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Interests',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: AmoraTheme.deepMidnight,
            ),
          ).animate()
            .fadeIn(duration: 800.ms)
            .slideY(begin: 0.3, end: 0),
          
          const SizedBox(height: 8),
          
          Text(
            'Select at least 3 interests',
            style: TextStyle(
              fontSize: 16,
              color: AmoraTheme.deepMidnight.withOpacity(0.7),
            ),
          ).animate()
            .fadeIn(delay: 200.ms, duration: 800.ms),
          
          const SizedBox(height: 32),
          
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: List.generate(_interests.length, (index) {
              final interest = _interests[index];
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
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
                      color: isSelected ? Colors.white : AmoraTheme.deepMidnight,
                    ),
                  ),
                ),
              ).animate()
                .fadeIn(delay: (index * 50).ms, duration: 600.ms)
                .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1));
            }),
          ),
        ],
      ),
    );
  }
}