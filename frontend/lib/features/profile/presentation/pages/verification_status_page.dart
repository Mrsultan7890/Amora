import 'package:flutter/material.dart';
import '../../../../core/services/api_service.dart';
import '../../../../shared/widgets/loading_widget.dart';

class VerificationStatusPage extends StatefulWidget {
  const VerificationStatusPage({Key? key}) : super(key: key);

  @override
  State<VerificationStatusPage> createState() => _VerificationStatusPageState();
}

class _VerificationStatusPageState extends State<VerificationStatusPage> {
  final ApiService _apiService = ApiService();
  bool _isLoading = true;
  Map<String, dynamic> _status = {};

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  Future<void> _loadStatus() async {
    try {
      final response = await _apiService.getVerificationStatus();
      setState(() {
        _status = response;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading status: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verification Status'),
        backgroundColor: Colors.pink,
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? const LoadingWidget()
          : RefreshIndicator(
              onRefresh: _loadStatus,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: _getStatusColors(),
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(15),
                      ),
                      child: Column(
                        children: [
                          Icon(
                            _getStatusIcon(),
                            size: 60,
                            color: Colors.white,
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _getStatusTitle(),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            _getStatusMessage(),
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 30),
                    
                    // Status Details
                    if (_status['status'] != null) ...[
                      _buildDetailItem(
                        'Status',
                        _status['status'].toString().toUpperCase(),
                        _getStatusIcon(),
                        _getStatusColor(),
                      ),
                      
                      if (_status['badge_color'] != null)
                        _buildDetailItem(
                          'Badge Color',
                          _status['badge_color'].toString().toUpperCase(),
                          Icons.verified,
                          _getBadgeColor(_status['badge_color']),
                        ),
                      
                      if (_status['verification_type'] != null)
                        _buildDetailItem(
                          'Verification Type',
                          _status['verification_type'].toString().toUpperCase(),
                          Icons.star,
                          Colors.amber,
                        ),
                      
                      if (_status['requested_at'] != null)
                        _buildDetailItem(
                          'Requested At',
                          _formatDate(_status['requested_at']),
                          Icons.schedule,
                          Colors.blue,
                        ),
                    ],
                    
                    const SizedBox(height: 30),
                    
                    // Timeline
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Verification Process',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 15),
                          
                          _buildTimelineItem(
                            'Request Submitted',
                            _status['status'] != 'unverified',
                            true,
                          ),
                          _buildTimelineItem(
                            'Under Review',
                            _status['status'] == 'pending',
                            _status['status'] == 'pending',
                          ),
                          _buildTimelineItem(
                            'Verification Complete',
                            _status['status'] == 'verified',
                            false,
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 30),
                    
                    // Help Section
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.blue.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.help_outline, color: Colors.blue.shade600),
                              const SizedBox(width: 10),
                              Text(
                                'Need Help?',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 15),
                          Text(
                            '• Verification typically takes 3-7 days\n'
                            '• Make sure your profile is complete\n'
                            '• Contact support if you have questions\n'
                            '• Rejected? You can reapply after 30 days',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.blue.shade700,
                            ),
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

  List<Color> _getStatusColors() {
    switch (_status['status']) {
      case 'verified':
        return [Colors.green.shade400, Colors.green.shade600];
      case 'pending':
        return [Colors.orange.shade400, Colors.orange.shade600];
      case 'rejected':
        return [Colors.red.shade400, Colors.red.shade600];
      default:
        return [Colors.grey.shade400, Colors.grey.shade600];
    }
  }

  IconData _getStatusIcon() {
    switch (_status['status']) {
      case 'verified':
        return Icons.verified;
      case 'pending':
        return Icons.pending;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  Color _getStatusColor() {
    switch (_status['status']) {
      case 'verified':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusTitle() {
    switch (_status['status']) {
      case 'verified':
        return 'Verified!';
      case 'pending':
        return 'Under Review';
      case 'rejected':
        return 'Rejected';
      default:
        return 'Not Requested';
    }
  }

  String _getStatusMessage() {
    switch (_status['status']) {
      case 'verified':
        return 'Your account has been successfully verified!';
      case 'pending':
        return 'Your verification request is being reviewed. This usually takes 3-7 days.';
      case 'rejected':
        return 'Your verification request was rejected. You can reapply after 30 days.';
      default:
        return 'You haven\'t requested verification yet.';
    }
  }

  Color _getBadgeColor(String? colorName) {
    switch (colorName) {
      case 'blue':
        return Colors.blue;
      case 'pink':
        return Colors.pink;
      case 'purple':
        return Colors.purple;
      case 'gold':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'Invalid date';
    }
  }

  Widget _buildDetailItem(String label, String value, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(String title, bool isCompleted, bool isActive) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isCompleted 
                  ? Colors.green 
                  : isActive 
                      ? Colors.orange 
                      : Colors.grey.shade300,
            ),
            child: Icon(
              isCompleted 
                  ? Icons.check 
                  : isActive 
                      ? Icons.schedule 
                      : Icons.circle,
              color: Colors.white,
              size: 16,
            ),
          ),
          const SizedBox(width: 15),
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
              color: isCompleted 
                  ? Colors.green 
                  : isActive 
                      ? Colors.orange 
                      : Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}