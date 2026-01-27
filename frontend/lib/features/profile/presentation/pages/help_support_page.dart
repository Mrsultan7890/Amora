import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/api_service.dart';

class HelpSupportPage extends StatefulWidget {
  const HelpSupportPage({super.key});

  @override
  State<HelpSupportPage> createState() => _HelpSupportPageState();
}

class _HelpSupportPageState extends State<HelpSupportPage> {
  final ApiService _apiService = ApiService.instance;
  List<Map<String, dynamic>> _faqList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFAQ();
  }

  Future<void> _loadFAQ() async {
    try {
      final faq = await _apiService.getFAQ();
      setState(() {
        _faqList = faq;
        _isLoading = false;
      });
    } catch (e) {
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
                        'Help & Support',
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
                  child: Column(
                    children: [
                      // Contact Support Button
                      Container(
                        width: double.infinity,
                        decoration: AmoraTheme.glassmorphism(
                          color: Colors.white,
                          borderRadius: 16,
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(20),
                          leading: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: const BoxDecoration(
                              gradient: AmoraTheme.primaryGradient,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.support_agent,
                              color: Colors.white,
                            ),
                          ),
                          title: const Text(
                            'Contact Support',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: AmoraTheme.deepMidnight,
                            ),
                          ),
                          subtitle: const Text(
                            'Get help from our support team',
                            style: TextStyle(
                              color: AmoraTheme.deepMidnight,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            color: AmoraTheme.sunsetRose,
                          ),
                          onTap: _showContactSupportDialog,
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // FAQ Section
                      Container(
                        decoration: AmoraTheme.glassmorphism(
                          color: Colors.white,
                          borderRadius: 16,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Padding(
                              padding: EdgeInsets.all(20),
                              child: Text(
                                'Frequently Asked Questions',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AmoraTheme.deepMidnight,
                                ),
                              ),
                            ),
                            
                            if (_isLoading)
                              const Padding(
                                padding: EdgeInsets.all(20),
                                child: Center(child: CircularProgressIndicator()),
                              )
                            else
                              ..._faqList.map((faq) => _buildFAQItem(
                                faq['question'],
                                faq['answer'],
                              )).toList(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return ExpansionTile(
      title: Text(
        question,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: AmoraTheme.deepMidnight,
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Text(
            answer,
            style: TextStyle(
              fontSize: 14,
              color: AmoraTheme.deepMidnight.withOpacity(0.8),
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }

  void _showContactSupportDialog() {
    final TextEditingController subjectController = TextEditingController();
    final TextEditingController messageController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Contact Support',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AmoraTheme.deepMidnight,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: subjectController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Subject',
                contentPadding: EdgeInsets.all(12),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: messageController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Message',
                contentPadding: EdgeInsets.all(12),
              ),
              maxLines: 4,
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
              gradient: AmoraTheme.primaryGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextButton(
              onPressed: () async {
                if (subjectController.text.isNotEmpty && 
                    messageController.text.isNotEmpty) {
                  Navigator.pop(context);
                  await _sendSupportRequest(
                    subjectController.text,
                    messageController.text,
                  );
                }
              },
              child: const Text(
                'Send',
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

  Future<void> _sendSupportRequest(String subject, String message) async {
    try {
      await _apiService.sendSupportRequest(
        subject: subject,
        message: message,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Support request sent successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}