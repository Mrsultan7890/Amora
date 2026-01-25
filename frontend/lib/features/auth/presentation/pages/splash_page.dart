import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/auth_bloc.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    print('SplashPage initialized');
    _navigateAfterDelay();
  }

  void _navigateAfterDelay() {
    print('Setting up navigation delay...');
    Future.delayed(const Duration(seconds: 3), () {
      print('Navigation delay completed');
      if (mounted) {
        print('Navigating to onboarding...');
        context.go('/onboarding');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        print('Auth state changed: ${state.runtimeType}');
        if (state is AuthAuthenticated) {
          print('User authenticated, navigating to discover');
          context.go('/discover');
        } else if (state is AuthUnauthenticated) {
          print('User not authenticated, navigating to onboarding');
          context.go('/onboarding');
        } else if (state is AuthError) {
          print('Auth error: ${state.message}');
          context.go('/onboarding');
        }
      },
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: AmoraTheme.primaryGradient,
          ),
          child: SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Logo with heart
                  Container(
                    width: 120,
                    height: 120,
                    decoration: AmoraTheme.glassmorphism(
                      color: Colors.white,
                      borderRadius: 60,
                    ),
                    child: const Center(
                      child: Text(
                        'A',
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: AmoraTheme.sunsetRose,
                        ),
                      ),
                    ),
                  ).animate()
                    .scale(duration: 800.ms, curve: Curves.elasticOut)
                    .then()
                    .shimmer(duration: 1000.ms),
                  
                  const SizedBox(height: 24),
                  
                  // App name
                  const Text(
                    'Amora',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ).animate()
                    .fadeIn(delay: 500.ms, duration: 800.ms)
                    .slideY(begin: 0.3, end: 0),
                  
                  const SizedBox(height: 8),
                  
                  // Tagline
                  const Text(
                    'Find Your Perfect Match',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                      letterSpacing: 1,
                    ),
                  ).animate()
                    .fadeIn(delay: 1000.ms, duration: 800.ms),
                  
                  const SizedBox(height: 80),
                  
                  // Loading indicator
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: AmoraTheme.glassmorphism(
                      color: Colors.white,
                      borderRadius: 30,
                    ),
                    child: const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AmoraTheme.sunsetRose,
                        ),
                      ),
                    ),
                  ).animate()
                    .fadeIn(delay: 1500.ms, duration: 800.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}