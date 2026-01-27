import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/services/api_service.dart';
import 'verification_status_page.dart';

class AmoraDevChatPage extends StatefulWidget {
  const AmoraDevChatPage({Key? key}) : super(key: key);

  @override
  State<AmoraDevChatPage> createState() => _AmoraDevChatPageState();
}

class _AmoraDevChatPageState extends State<AmoraDevChatPage> {
  final ApiService _apiService = ApiService.instance;
  final ScrollController _scrollController = ScrollController();
  
  List<ChatMessage> _messages = [];
  bool _isEligible = false;
  String _selectedBadgeColor = 'blue';
  
  final String _upiId = 'khansalahuddin2023@okicici';
  
  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  void _initializeChat() {
    _addMessage(ChatMessage(
      text: "👋 Hi! I'm AmoraDev, your verification assistant!\n\nLet me help you get verified on Amora. First, let me check if you're eligible...",
      isBot: true,
      timestamp: DateTime.now(),
    ));
    
    Future.delayed(const Duration(seconds: 2), () {
      _checkEligibility();
    });
  }

  Future<void> _checkEligibility() async {
    _addMessage(ChatMessage(
      text: "🔍 Checking your eligibility...",
      isBot: true,
      timestamp: DateTime.now(),
    ));

    try {
      final response = await _apiService.checkVerificationEligibility();
      _isEligible = response['eligible'] ?? false;
      final requirements = response['requirements'] ?? {};
      
      if (_isEligible) {
        _addMessage(ChatMessage(
          text: "🎉 Great news! You're eligible for verification!\n\n✅ Profile Complete\n✅ 3+ Photos\n✅ Bio (20+ chars)\n✅ 15+ Days Account\n✅ Job & Education\n✅ No Reports\n\nWould you like to proceed with verification?",
          isBot: true,
          timestamp: DateTime.now(),
          showOptions: true,
          options: ['Yes, verify me!', 'Tell me more'],
        ));
      } else {
        String missing = "❌ You're not eligible yet. Please complete:\n\n";
        if (!(requirements['profile_complete'] ?? false)) missing += "• Complete your profile\n";
        if (!(requirements['min_photos'] ?? false)) missing += "• Add at least 3 photos\n";
        if (!(requirements['bio_length'] ?? false)) missing += "• Write a bio (20+ characters)\n";
        if (!(requirements['account_age'] ?? false)) missing += "• Wait for 15+ days account age\n";
        if (!(requirements['job_education'] ?? false)) missing += "• Add job and education\n";
        
        missing += "\nCome back when you've completed these requirements! 😊";
        
        _addMessage(ChatMessage(
          text: missing,
          isBot: true,
          timestamp: DateTime.now(),
        ));
      }
    } catch (e) {
      _addMessage(ChatMessage(
        text: "❌ Sorry, I couldn't check your eligibility right now. Please try again later.",
        isBot: true,
        timestamp: DateTime.now(),
      ));
    }
  }

  void _handleOptionTap(String option) {
    _addMessage(ChatMessage(
      text: option,
      isBot: false,
      timestamp: DateTime.now(),
    ));

    if (option == 'Yes, verify me!') {
      _showBadgeSelection();
    } else if (option == 'Tell me more') {
      _showVerificationBenefits();
    } else if (option.contains('Badge')) {
      _selectedBadgeColor = option.toLowerCase().split(' ')[0];
      _showDonationPrompt();
    } else if (option == 'Skip donation (7-10 days)') {
      _submitVerification(false);
    } else if (option == 'Donate ₹29 (Instant)') {
      _showUpiPayment(29);
    } else if (option == 'Donate ₹49 (Instant)') {
      _showUpiPayment(49);
    } else if (option == 'Donate ₹99 (Instant)') {
      _showUpiPayment(99);
    }
  }

  void _showVerificationBenefits() {
    _addMessage(ChatMessage(
      text: "🌟 Verification Benefits:\n\n✅ Colored verification badge\n✅ Higher visibility in discover\n✅ Priority in matches\n✅ Trust indicator for others\n✅ Profile boost\n✅ Special verified features\n\nReady to get verified?",
      isBot: true,
      timestamp: DateTime.now(),
      showOptions: true,
      options: ['Yes, let\'s do it!', 'Maybe later'],
    ));
  }

  void _showBadgeSelection() {
    _addMessage(ChatMessage(
      text: "🎨 Choose your verification badge color:\n\n💙 Blue - Classic & Professional\n💖 Pink - Elegant & Stylish\n💜 Purple - Unique & Creative\n\nWhich color represents you best?",
      isBot: true,
      timestamp: DateTime.now(),
      showOptions: true,
      options: ['Blue Badge', 'Pink Badge', 'Purple Badge'],
    ));
  }

  void _showDonationPrompt() {
    _addMessage(ChatMessage(
      text: "Perfect choice! 🎯\n\n💝 To keep Amora free and safe, we rely on community support.\n\n⚡ Donate for instant verification\n⏰ Or skip for 7-10 days review\n\nWhat would you prefer?",
      isBot: true,
      timestamp: DateTime.now(),
      showOptions: true,
      options: ['Donate ₹29 (Instant)', 'Donate ₹49 (Instant)', 'Donate ₹99 (Instant)', 'Skip donation (7-10 days)'],
    ));
  }

  void _showUpiPayment(int amount) {
    _addMessage(ChatMessage(
      text: "💳 Payment Details:\n\nAmount: ₹$amount\nUPI ID: $_upiId\n\n📱 Scan the QR code below or copy UPI ID to pay:",
      isBot: true,
      timestamp: DateTime.now(),
      showQrCode: true,
      amount: amount,
    ));
  }

  Future<void> _submitVerification(bool isDonation) async {
    _addMessage(ChatMessage(
      text: "⏳ Submitting your verification request...",
      isBot: true,
      timestamp: DateTime.now(),
    ));

    try {
      await _apiService.requestVerification(_selectedBadgeColor);
      
      if (isDonation) {
        _addMessage(ChatMessage(
          text: "🎉 Thank you for your donation!\n\n✅ Verification request submitted\n⚡ You'll be verified instantly after payment confirmation\n🏆 You'll receive a GOLD badge as a premium supporter!\n\nThank you for supporting Amora! 💖",
          isBot: true,
          timestamp: DateTime.now(),
        ));
      } else {
        _addMessage(ChatMessage(
          text: "✅ Verification request submitted successfully!\n\n⏰ Review time: 3-7 days\n📧 You'll get notified when approved\n🎯 Badge color: ${_selectedBadgeColor.toUpperCase()}\n\nThank you for choosing Amora! 😊",
          isBot: true,
          timestamp: DateTime.now(),
        ));
      }
      
      Future.delayed(const Duration(seconds: 2), () {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const VerificationStatusPage(),
          ),
        );
      });
      
    } catch (e) {
      _addMessage(ChatMessage(
        text: "❌ Sorry, something went wrong. Please try again or contact support.",
        isBot: true,
        timestamp: DateTime.now(),
      ));
    }
  }

  void _addMessage(ChatMessage message) {
    setState(() {
      _messages.add(message);
    });
    
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _copyUpiId() async {
    await Clipboard.setData(ClipboardData(text: _upiId));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('UPI ID copied to clipboard!'),
        backgroundColor: Colors.green,
      ),
    );
  }

  Future<void> _downloadQrCode(int amount) async {
    try {
      final permission = await Permission.storage.request();
      if (!permission.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Storage permission required')),
        );
        return;
      }

      final qrValidationResult = QrValidator.validate(
        data: 'upi://pay?pa=$_upiId&am=$amount&cu=INR&tn=Amora Verification',
        version: QrVersions.auto,
      );

      if (qrValidationResult.status == QrValidationStatus.valid) {
        final qrCode = qrValidationResult.qrCode!;
        final painter = QrPainter.withQr(
          qr: qrCode,
          eyeStyle: const QrEyeStyle(
            eyeShape: QrEyeShape.square,
            color: Color(0xFF000000),
          ),
          dataModuleStyle: const QrDataModuleStyle(
            dataModuleShape: QrDataModuleShape.square,
            color: Color(0xFF000000),
          ),
          gapless: false,
        );

        final picData = await painter.toImageData(200, format: ui.ImageByteFormat.png);
        final buffer = picData!.buffer.asUint8List();

        final directory = await getExternalStorageDirectory();
        final file = File('${directory!.path}/amora_payment_qr.png');
        await file.writeAsBytes(buffer);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('QR Code saved to ${file.path}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to download QR code'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              backgroundColor: Colors.pink,
              child: const Text('AD', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('AmoraDev', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                Text('Verification Assistant', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment: message.isBot ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (message.isBot) ...[
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.pink,
              child: const Text('AD', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: message.isBot ? Colors.grey.shade100 : Colors.pink,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: TextStyle(
                      color: message.isBot ? Colors.black : Colors.white,
                      fontSize: 14,
                    ),
                  ),
                  if (message.showQrCode && message.amount != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          QrImageView(
                            data: 'upi://pay?pa=$_upiId&am=${message.amount}&cu=INR&tn=Amora Verification',
                            version: QrVersions.auto,
                            size: 150,
                            eyeStyle: const QrEyeStyle(
                              eyeShape: QrEyeShape.square,
                              color: Colors.black,
                            ),
                            dataModuleStyle: const QrDataModuleStyle(
                              dataModuleShape: QrDataModuleShape.square,
                              color: Colors.black,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              ElevatedButton.icon(
                                onPressed: _copyUpiId,
                                icon: const Icon(Icons.copy, size: 16),
                                label: const Text('Copy UPI'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                              ),
                              ElevatedButton.icon(
                                onPressed: () => _downloadQrCode(message.amount!),
                                icon: const Icon(Icons.download, size: 16),
                                label: const Text('Download'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: () => _submitVerification(true),
                      child: const Text('I have paid ✅'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                  if (message.showOptions && message.options != null) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: message.options!.map((option) {
                        return ElevatedButton(
                          onPressed: () => _handleOptionTap(option),
                          child: Text(option),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.pink.shade50,
                            foregroundColor: Colors.pink,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    '${message.timestamp.hour}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                    style: TextStyle(
                      color: message.isBot ? Colors.grey.shade600 : Colors.white70,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (!message.isBot) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 16,
              backgroundColor: Colors.blue,
              child: const Icon(Icons.person, color: Colors.white, size: 16),
            ),
          ],
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isBot;
  final DateTime timestamp;
  final bool showOptions;
  final List<String>? options;
  final bool showQrCode;
  final int? amount;

  ChatMessage({
    required this.text,
    required this.isBot,
    required this.timestamp,
    this.showOptions = false,
    this.options,
    this.showQrCode = false,
    this.amount,
  });
}