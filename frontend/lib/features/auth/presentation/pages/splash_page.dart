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
    Future.delayed(const Duration(seconds: 4), () {
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
                  // Logo with heart design
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer glow effect
                      Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.white.withOpacity(0.3),
                              blurRadius: 30,
                              spreadRadius: 10,
                            ),
                          ],
                        ),
                      ),
                      // Main logo container
                      Container(
                        width: 120,
                        height: 120,
                        decoration: AmoraTheme.glassmorphism(
                          color: Colors.white,
                          borderRadius: 60,
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // Heart icon background
                            Icon(
                              Icons.favorite,
                              size: 40,
                              color: AmoraTheme.sunsetRose.withOpacity(0.2),
                            ),
                            // Letter A
                            const Text(
                              'A',
                              style: TextStyle(
                                fontSize: 52,
                                fontWeight: FontWeight.bold,
                                color: AmoraTheme.sunsetRose,
                                shadows: [
                                  Shadow(
                                    color: AmoraTheme.warmGold,
                                    offset: Offset(2, 2),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Floating hearts animation
                      Positioned(
                        top: -10,
                        right: 10,
                        child: Icon(
                          Icons.favorite,
                          size: 16,
                          color: Colors.white.withOpacity(0.8),
                        ).animate(onPlay: (controller) => controller.repeat())
                          .fadeIn(duration: 1000.ms)
                          .then()
                          .fadeOut(duration: 1000.ms),
                      ),
                      Positioned(
                        bottom: 5,
                        left: 15,
                        child: Icon(
                          Icons.favorite,
                          size: 12,
                          color: Colors.white.withOpacity(0.6),
                        ).animate(onPlay: (controller) => controller.repeat())
                          .fadeIn(delay: 500.ms, duration: 1000.ms)
                          .then()
                          .fadeOut(duration: 1000.ms),
                      ),
                    ],
                  ).animate()
                    .scale(duration: 1200.ms, curve: Curves.elasticOut)
                    .then()
                    .shimmer(duration: 1500.ms, color: Colors.white.withOpacity(0.5)),
                  
                  const SizedBox(height: 32),
                  
                  // App name with gradient effect
                  ShaderMask(
                    shaderCallback: (bounds) => const LinearGradient(
                      colors: [Colors.white, AmoraTheme.warmGold],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ).createShader(bounds),
                    child: const Text(
                      'Amora',
                      style: TextStyle(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 3,
                        shadows: [
                          Shadow(
                            color: Colors.black26,
                            offset: Offset(0, 4),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                    ),
                  ).animate()
                    .fadeIn(delay: 800.ms, duration: 1000.ms)
                    .slideY(begin: 0.3, end: 0)
                    .then()
                    .shimmer(duration: 2000.ms, color: Colors.white.withOpacity(0.3)),
                  
                  const SizedBox(height: 12),
                  
                  // Tagline with typing effect
                  const Text(
                    '💕 Find Your Perfect Match 💕',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      letterSpacing: 1.5,
                      fontWeight: FontWeight.w500,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          offset: Offset(0, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ).animate()
                    .fadeIn(delay: 1500.ms, duration: 1000.ms)
                    .slideX(begin: -0.3, end: 0, duration: 1500.ms),
                  
                  const SizedBox(height: 100),
                  
                  // Loading indicator with pulse effect
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Pulse rings
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 2,
                          ),
                        ),
                      ).animate(onPlay: (controller) => controller.repeat())
                        .scale(
                          begin: const Offset(0.8, 0.8),
                          end: const Offset(1.2, 1.2),
                          duration: 2000.ms,
                        )
                        .fadeOut(duration: 2000.ms),
                      
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.5),
                            width: 2,
                          ),
                        ),
                      ).animate(onPlay: (controller) => controller.repeat())
                        .scale(
                          begin: const Offset(0.8, 0.8),
                          end: const Offset(1.2, 1.2),
                          duration: 2000.ms,
                        )
                        .fadeOut(duration: 2000.ms, delay: 500.ms),
                      
                      // Main loading container
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: AmoraTheme.glassmorphism(
                          color: Colors.white,
                          borderRadius: 35,
                        ),
                        child: const SizedBox(
                          width: 30,
                          height: 30,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AmoraTheme.sunsetRose,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ).animate()
                    .fadeIn(delay: 2500.ms, duration: 800.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}