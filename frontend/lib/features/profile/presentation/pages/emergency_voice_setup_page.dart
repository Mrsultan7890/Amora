import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/emergency_voice_service.dart';

class EmergencyVoiceSetupPage extends StatefulWidget {
  const EmergencyVoiceSetupPage({super.key});

  @override
  State<EmergencyVoiceSetupPage> createState() => _EmergencyVoiceSetupPageState();
}

class _EmergencyVoiceSetupPageState extends State<EmergencyVoiceSetupPage> {
  final EmergencyVoiceService _voiceService = EmergencyVoiceService.instance;
  bool _isRecording = false;
  bool _isPlaying = false;
  
  @override
  void initState() {
    super.initState();
    _initializeVoiceService();
  }
  
  Future<void> _initializeVoiceService() async {
    await _voiceService.initialize();
    setState(() {});
  }
  
  Future<void> _startRecording() async {
    final path = await _voiceService.startRecording();
    if (path != null) {
      setState(() => _isRecording = true);
    } else {
      _showError('Failed to start recording. Check microphone permission.');
    }
  }
  
  Future<void> _stopRecording() async {
    final path = await _voiceService.stopRecording();
    setState(() => _isRecording = false);
    
    if (path != null) {
      _showSuccess('Emergency voice message saved!');
    }
  }
  
  Future<void> _playRecording() async {
    setState(() => _isPlaying = true);
    await _voiceService.playRecording();
    
    // Auto stop after playing
    await Future.delayed(const Duration(seconds: 3));
    await _voiceService.stopPlaying();
    if (mounted) setState(() => _isPlaying = false);
  }
  
  Future<void> _deleteRecording() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Voice Message'),
        content: const Text('Are you sure you want to delete your emergency voice message?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    
    if (confirm == true) {
      await _voiceService.deleteRecording();
      setState(() {});
      _showSuccess('Voice message deleted');
    }
  }
  
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }
  
  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Emergency Voice Message'),
        backgroundColor: AmoraTheme.sunsetRose,
        foregroundColor: Colors.white,
      ),
      body: Container(
        decoration: const BoxDecoration(gradient: AmoraTheme.backgroundGradient),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // Info Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: AmoraTheme.glassmorphism(color: Colors.white),
                child: Column(
                  children: [
                    const Icon(Icons.record_voice_over, size: 48, color: AmoraTheme.sunsetRose),
                    const SizedBox(height: 12),
                    const Text(
                      'Emergency Voice Message',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Record a voice message that will be sent to your emergency contacts when you shake your phone in distress.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey),
                    ),
                  ],
                ),
              ),
              
              const SizedBox(height: 30),
              
              // Recording Status
              if (_voiceService.hasRecording)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: AmoraTheme.glassmorphism(color: Colors.green.withOpacity(0.1)),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Voice message ready', style: TextStyle(fontWeight: FontWeight.w600)),
                            FutureBuilder<int>(
                              future: _voiceService.getRecordingDuration(),
                              builder: (context, snapshot) {
                                final duration = snapshot.data ?? 0;
                                return Text('Duration: ${duration}s', style: const TextStyle(color: Colors.grey));
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              
              const SizedBox(height: 20),
              
              // Recording Controls
              if (_isRecording)
                Column(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.stop, color: Colors.white, size: 40),
                    ),
                    const SizedBox(height: 12),
                    const Text('Recording...', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: _stopRecording,
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                      child: const Text('Stop Recording', style: TextStyle(color: Colors.white)),
                    ),
                  ],
                )
              else
                Column(
                  children: [
                    // Record Button
                    GestureDetector(
                      onTap: _startRecording,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: AmoraTheme.primaryGradient,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.mic, color: Colors.white, size: 40),
                      ),
                    ),
                    const SizedBox(height: 12),
                    const Text('Tap to Record', style: TextStyle(fontWeight: FontWeight.w600)),
                    
                    const SizedBox(height: 30),
                    
                    // Action Buttons
                    if (_voiceService.hasRecording) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          // Play Button
                          ElevatedButton.icon(
                            onPressed: _isPlaying ? null : _playRecording,
                            icon: Icon(_isPlaying ? Icons.volume_up : Icons.play_arrow),
                            label: Text(_isPlaying ? 'Playing...' : 'Play'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                          ),
                          
                          // Delete Button
                          ElevatedButton.icon(
                            onPressed: _deleteRecording,
                            icon: const Icon(Icons.delete),
                            label: const Text('Delete'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              
              const Spacer(),
              
              // Instructions
              Container(
                padding: const EdgeInsets.all(16),
                decoration: AmoraTheme.glassmorphism(color: Colors.orange.withOpacity(0.1)),
                child: const Column(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange),
                    SizedBox(height: 8),
                    Text(
                      'Tips for Emergency Voice Message:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(
                      '• Keep it short (10-30 seconds)\n• Speak clearly and calmly\n• Include your name and situation\n• Example: "This is John, I need help immediately"',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}