import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/api_service.dart';

class CallHistoryPage extends StatefulWidget {
  const CallHistoryPage({super.key});

  @override
  State<CallHistoryPage> createState() => _CallHistoryPageState();
}

class _CallHistoryPageState extends State<CallHistoryPage> {
  final ApiService _apiService = ApiService.instance;
  List<Map<String, dynamic>> _callHistory = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCallHistory();
  }

  Future<void> _loadCallHistory() async {
    try {
      final history = await _apiService.getCallHistory();
      setState(() {
        _callHistory = history;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading call history: $e');
      setState(() {
        _callHistory = [];
        _isLoading = false;
      });
    }
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AmoraTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios, color: AmoraTheme.deepMidnight),
                    ),
                    const Expanded(
                      child: Text(
                        'Call History',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AmoraTheme.deepMidnight),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
              ),
              
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AmoraTheme.sunsetRose)))
                    : _callHistory.isEmpty
                        ? const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.call, size: 64, color: AmoraTheme.deepMidnight),
                                SizedBox(height: 16),
                                Text('No call history', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, color: AmoraTheme.deepMidnight)),
                                SizedBox(height: 8),
                                Text('Your video calls will appear here', style: TextStyle(fontSize: 16, color: Colors.grey)),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: _callHistory.length,
                            itemBuilder: (context, index) => _buildCallItem(_callHistory[index], index),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCallItem(Map<String, dynamic> call, int index) {
    final isVideo = call['call_type'] == 'video';
    final isMissed = call['status'] == 'missed';
    final duration = call['duration'] ?? 0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: AmoraTheme.glassmorphism(color: Colors.white, borderRadius: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (isMissed ? Colors.red : AmoraTheme.sunsetRose).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isVideo ? Icons.videocam : Icons.call,
              color: isMissed ? Colors.red : AmoraTheme.sunsetRose,
              size: 20,
            ),
          ),
          
          const SizedBox(width: 16),
          
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  call['other_user_name'] ?? 'Unknown',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AmoraTheme.deepMidnight),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      isMissed ? Icons.call_missed : Icons.call_made,
                      size: 16,
                      color: isMissed ? Colors.red : Colors.green,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isMissed ? 'Missed' : _formatDuration(duration),
                      style: TextStyle(fontSize: 14, color: AmoraTheme.deepMidnight.withOpacity(0.7)),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          Text(
            _formatTime(call['timestamp']),
            style: TextStyle(fontSize: 12, color: AmoraTheme.deepMidnight.withOpacity(0.5)),
          ),
        ],
      ),
    ).animate().fadeIn(delay: (100 * index).ms);
  }

  String _formatDuration(int seconds) {
    if (seconds == 0) return 'No answer';
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes}m ${remainingSeconds}s';
  }

  String _formatTime(String? timestamp) {
    if (timestamp == null) return '';
    
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);
      
      if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else {
        return '${difference.inDays}d ago';
      }
    } catch (e) {
      return '';
    }
  }
}