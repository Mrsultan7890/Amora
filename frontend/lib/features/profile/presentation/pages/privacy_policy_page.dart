import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';

class PrivacyPolicyPage extends StatelessWidget {
  const PrivacyPolicyPage({super.key});

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
                        'Privacy Policy',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AmoraTheme.deepMidnight,
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              
              // Content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Container(
                    decoration: AmoraTheme.glassmorphism(
                      color: Colors.white,
                      borderRadius: 16,
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Privacy Policy',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AmoraTheme.deepMidnight,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Last updated: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                          style: TextStyle(
                            color: AmoraTheme.deepMidnight.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        _buildSection(
                          'Information We Collect',
                          'We collect information you provide directly to us, such as when you create an account, update your profile, or communicate with other users.',
                        ),
                        
                        _buildSection(
                          'How We Use Your Information',
                          'We use the information we collect to provide, maintain, and improve our services, including matching you with other users and facilitating communication.',
                        ),
                        
                        _buildSection(
                          'Information Sharing',
                          'We do not sell, trade, or otherwise transfer your personal information to third parties without your consent, except as described in this policy.',
                        ),
                        
                        _buildSection(
                          'Location Information',
                          'We collect and use location information to show you potential matches nearby. You can control location sharing in your device settings.',
                        ),
                        
                        _buildSection(
                          'Data Security',
                          'We implement appropriate security measures to protect your personal information against unauthorized access, alteration, disclosure, or destruction.',
                        ),
                        
                        _buildSection(
                          'Emergency Features',
                          'Our emergency alert system may share your location with your matches and emergency contacts when activated for safety purposes.',
                        ),
                        
                        _buildSection(
                          'Your Rights',
                          'You have the right to access, update, or delete your personal information. You can also deactivate your account at any time.',
                        ),
                        
                        _buildSection(
                          'Contact Us',
                          'If you have any questions about this Privacy Policy, please contact us at privacy@amora.app',
                        ),
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

  Widget _buildSection(String title, String content) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AmoraTheme.deepMidnight,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 16,
              color: AmoraTheme.deepMidnight.withOpacity(0.8),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}