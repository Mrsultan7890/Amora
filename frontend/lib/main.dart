import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'core/services/api_service.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/pages/splash_page.dart';
import 'features/auth/presentation/pages/onboarding_page.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/auth/presentation/pages/signup_page.dart';
import 'features/swipe/presentation/pages/discover_page.dart';
import 'features/chat/presentation/pages/matches_page.dart';
import 'features/profile/presentation/pages/profile_page.dart';
import 'features/profile/presentation/pages/edit_profile_page.dart';
import 'features/profile/presentation/pages/settings_page.dart';
import 'shared/widgets/main_navigation.dart';
import 'core/services/location_service.dart';
import 'core/constants/app_constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  print('App starting...');
  
  try {
    // Initialize API service first
    print('Initializing API service...');
    await ApiService.instance.initialize();
    print('API service initialized');
  } catch (e) {
    print('API service initialization error: $e');
  }
  
  print('Starting app widget...');
  runApp(const AmoraApp());
}

class AmoraApp extends StatelessWidget {
  const AmoraApp({super.key});

  @override
  Widget build(BuildContext context) {
    print('Building AmoraApp widget...');
    
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) {
            print('Creating AuthBloc...');
            return AuthBloc()..add(AuthCheckRequested());
          },
        ),
      ],
      child: PopScope(
        canPop: false,
        onPopInvoked: (didPop) {
          // Prevent app from closing on back gesture in main tabs
        },
        child: MaterialApp.router(
          title: 'Amora',
          debugShowCheckedModeBanner: false,
          theme: AmoraTheme.lightTheme,
          darkTheme: AmoraTheme.darkTheme,
          themeMode: ThemeMode.light,
          routerConfig: _router,
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(context).copyWith(textScaleFactor: 1.0),
              child: child ?? const Scaffold(
                body: Center(
                  child: Text('App failed to load'),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

final GoRouter _router = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashPage(),
    ),
    GoRoute(
      path: '/onboarding',
      builder: (context, state) => const OnboardingPage(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: '/signup',
      builder: (context, state) => const SignupPage(),
    ),
    ShellRoute(
      builder: (context, state, child) => MainNavigation(child: child),
      routes: [
        GoRoute(
          path: '/discover',
          builder: (context, state) => const DiscoverPage(),
        ),
        GoRoute(
          path: '/matches',
          builder: (context, state) => const MatchesPage(),
        ),
        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfilePage(),
        ),
      ],
    ),
    GoRoute(
      path: '/edit-profile',
      builder: (context, state) => const EditProfilePage(),
    ),
    GoRoute(
      path: '/settings',
      builder: (context, state) => const SettingsPage(),
    ),
  ],
);