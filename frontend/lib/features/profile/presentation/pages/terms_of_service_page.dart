import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';

class TermsOfServicePage extends StatelessWidget {
  const TermsOfServicePage({super.key});

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
                        'Terms of Service',
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
                          'Terms of Service',
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
                          'Acceptance of Terms',
                          'By accessing and using Amora, you accept and agree to be bound by the terms and provision of this agreement.',
                        ),
                        
                        _buildSection(
                          'User Conduct',
                          'You agree to use Amora respectfully and lawfully. Harassment, abuse, or inappropriate behavior is strictly prohibited and may result in account termination.',
                        ),
                        
                        _buildSection(
                          'Account Responsibility',
                          'You are responsible for maintaining the confidentiality of your account and password. You agree to accept responsibility for all activities under your account.',
                        ),
                        
                        _buildSection(
                          'Content Guidelines',
                          'All content you share must be appropriate and respectful. We reserve the right to remove content that violates our community guidelines.',
                        ),
                        
                        _buildSection(
                          'Privacy and Safety',
                          'Your safety is our priority. Use our emergency features responsibly and report any suspicious or harmful behavior immediately.',
                        ),
                        
                        _buildSection(
                          'Service Availability',
                          'We strive to keep Amora available 24/7, but we cannot guarantee uninterrupted service. We may perform maintenance that temporarily limits access.',
                        ),
                        
                        _buildSection(
                          'Termination',
                          'We may terminate or suspend your account immediately if you breach these terms. You may also delete your account at any time.',
                        ),
                        
                        _buildSection(
                          'Changes to Terms',
                          'We reserve the right to modify these terms at any time. Continued use of the service constitutes acceptance of modified terms.',
                        ),
                        
                        _buildSection(
                          'Contact Information',
                          'For questions about these Terms of Service, please contact us at legal@amora.app',
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