import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/settings_service.dart';
import '../../../../core/services/emergency_service.dart';
import '../../../../core/services/offline_emergency_service.dart';
import '../../../calling/presentation/pages/call_history_page.dart';
import 'emergency_contacts_page.dart';
import 'privacy_policy_page.dart';
import 'terms_of_service_page.dart';
import 'help_support_page.dart';
import 'amoradev_chat_page.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final SettingsService _settingsService = SettingsService.instance;
  
  // Settings values
  bool _pushNotifications = true;
  bool _emailNotifications = false;
  bool _showOnlineStatus = true;
  bool _showDistance = true;
  bool _emergencyShakeEnabled = true;
  double _maxDistance = 50.0;
  RangeValues _ageRange = const RangeValues(18, 35);
  String _interestedIn = 'Everyone';
  bool _showMeOnAmora = true;
  bool _incognitoMode = false;
  bool _showInFeed = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }
  
  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    
    try {
      final settings = await _settingsService.loadAllSettings();
      final ageRange = settings['age_range'] as List<double>;
      
      if (mounted) {
        setState(() {
          _maxDistance = settings['max_distance'];
          _ageRange = RangeValues(ageRange[0], ageRange[1]);
          _interestedIn = settings['interested_in'];
          _pushNotifications = settings['push_notifications'];
          _emailNotifications = settings['email_notifications'];
          _showOnlineStatus = settings['show_online_status'];
          _showDistance = settings['show_distance'];
          _emergencyShakeEnabled = settings['emergency_shake_enabled'] ?? true;
          _showMeOnAmora = settings['show_me_on_amora'];
          _incognitoMode = settings['incognito_mode'];
          _showInFeed = settings['show_in_feed'] ?? true;
        });
      }
    } catch (e) {
      print('Error loading settings: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
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
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: AmoraTheme.deepMidnight,
                      ),
                    ),
                    
                    const Expanded(
                      child: Text(
                        'Settings',
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
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AmoraTheme.sunsetRose,
                          ),
                        ),
                      )
                    : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Discovery Settings
                      _buildSectionHeader('Discovery Settings'),
                      
                      _buildSettingsCard([
                        _buildSliderSetting(
                          'Maximum Distance',
                          '${_maxDistance.round()} km',
                          _maxDistance,
                          1.0,
                          100.0,
                          (value) async {
                            if (mounted) {
                              setState(() => _maxDistance = value);
                              await _settingsService.setMaxDistance(value);
                            }
                          },
                        ),
                        
                        const Divider(height: 1),
                        
                        _buildRangeSliderSetting(
                          'Age Range',
                          '${_ageRange.start.round()} - ${_ageRange.end.round()} years',
                          _ageRange,
                          18.0,
                          80.0,
                          (values) async {
                            if (mounted) {
                              setState(() => _ageRange = values);
                              await _settingsService.setAgeRange(values.start, values.end);
                            }
                          },
                        ),
                        
                        const Divider(height: 1),
                        
                        _buildDropdownSetting(
                          'Show Me',
                          _interestedIn,
                          ['Everyone', 'Men', 'Women', 'Non-binary'],
                          (value) async {
                            setState(() => _interestedIn = value!);
                            await _settingsService.setInterestedIn(value!);
                          },
                        ),
                      ]).animate()
                        .fadeIn(delay: 200.ms, duration: 600.ms)
                        .slideY(begin: 0.3, end: 0),
                      
                      const SizedBox(height: 24),
                      
                      // Notifications
                      _buildSectionHeader('Notifications'),
                      
                      _buildSettingsCard([
                        _buildSwitchSetting(
                          'Push Notifications',
                          'Get notified about new matches and messages',
                          _pushNotifications,
                          (value) async {
                            setState(() => _pushNotifications = value);
                            await _settingsService.setPushNotifications(value);
                          },
                        ),
                        
                        const Divider(height: 1),
                        
                        _buildSwitchSetting(
                          'Email Notifications',
                          'Receive updates via email',
                          _emailNotifications,
                          (value) async {
                            setState(() => _emailNotifications = value);
                            await _settingsService.setEmailNotifications(value);
                          },
                        ),
                      ]).animate()
                        .fadeIn(delay: 400.ms, duration: 600.ms)
                        .slideY(begin: 0.3, end: 0),
                      
                      const SizedBox(height: 24),
                      
                      // Privacy & Safety
                      _buildSectionHeader('Privacy & Safety'),
                      
                      _buildSettingsCard([
                        _buildSwitchSetting(
                          'Show Online Status',
                          'Let others see when you\'re online',
                          _showOnlineStatus,
                          (value) async {
                            setState(() => _showOnlineStatus = value);
                            await _settingsService.setShowOnlineStatus(value);
                          },
                        ),
                        
                        const Divider(height: 1),
                        
                        _buildSwitchSetting(
                          'Emergency Shake Alert',
                          'Shake phone to send emergency alert (30s cooldown)',
                          _emergencyShakeEnabled,
                          (value) async {
                            setState(() => _emergencyShakeEnabled = value);
                            await _settingsService.setEmergencyShakeEnabled(value);
                            // Update both emergency services
                            final EmergencyService emergencyService = EmergencyService.instance;
                            await emergencyService.setEmergencyEnabled(value);
                            final OfflineEmergencyService offlineService = OfflineEmergencyService.instance;
                            await offlineService.setEnabled(value);
                            
                            // Show feedback
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    value 
                                      ? '🚨 Emergency shake detection ENABLED' 
                                      : '❌ Emergency shake detection DISABLED'
                                  ),
                                  backgroundColor: value ? Colors.green : Colors.red,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                        ),
                        
                        const Divider(height: 1),
                        
                        _buildSwitchSetting(
                          'Show Distance',
                          'Display your distance to other users',
                          _showDistance,
                          (value) async {
                            setState(() => _showDistance = value);
                            await _settingsService.setShowDistance(value);
                          },
                        ),
                        
                        const Divider(height: 1),
                        
                        _buildSwitchSetting(
                          'Show Me on Amora',
                          'Make your profile discoverable',
                          _showMeOnAmora,
                          (value) async {
                            setState(() => _showMeOnAmora = value);
                            await _settingsService.setShowMeOnAmora(value);
                          },
                        ),
                        
                        const Divider(height: 1),
                        
                        _buildSwitchSetting(
                          'Incognito Mode',
                          'Only people you like can see your profile',
                          _incognitoMode,
                          (value) async {
                            setState(() => _incognitoMode = value);
                            await _settingsService.setIncognitoMode(value);
                          },
                        ),
                        
                        const Divider(height: 1),
                        
                        _buildSwitchSetting(
                          'Show in Feed',
                          'Display your photos in the community feed',
                          _showInFeed,
                          (value) async {
                            setState(() => _showInFeed = value);
                            await _settingsService.setShowInFeed(value);
                          },
                        ),
                      ]).animate()
                        .fadeIn(delay: 600.ms, duration: 600.ms)
                        .slideY(begin: 0.3, end: 0),
                      
                      const SizedBox(height: 24),
                      
                      // Account Actions
                      _buildSectionHeader('Account'),
                      
                      _buildSettingsCard([
                        _buildActionSetting(
                          'Get Verified',
                          'Chat with AmoraDev for verification',
                          Icons.verified,
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const AmoraDevChatPage(),
                            ),
                          ),
                        ),
                        
                        const Divider(height: 1),
                        
                        _buildActionSetting(
                          'Emergency Contacts',
                          'Manage offline emergency contacts',
                          Icons.contact_emergency,
                          () => _showEmergencyContactsPage(),
                        ),
                        
                        const Divider(height: 1),
                        
                        _buildActionSetting(
                          'Call History',
                          'View your video call history',
                          Icons.call,
                          () => _showCallHistoryPage(),
                        ),
                        
                        const Divider(height: 1),
                        
                        _buildActionSetting(
                          'Blocked Users',
                          'Manage blocked profiles',
                          Icons.block,
                          () => _showBlockedUsersPage(),
                        ),
                        
                        const Divider(height: 1),
                        
                        _buildActionSetting(
                          'Privacy Policy',
                          'Read our privacy policy',
                          Icons.privacy_tip,
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const PrivacyPolicyPage(),
                            ),
                          ),
                        ),
                        
                        const Divider(height: 1),
                        
                        _buildActionSetting(
                          'Terms of Service',
                          'Read our terms of service',
                          Icons.description,
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const TermsOfServicePage(),
                            ),
                          ),
                        ),
                        
                        const Divider(height: 1),
                        
                        _buildActionSetting(
                          'Help & Support',
                          'Get help or contact support',
                          Icons.help,
                          () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const HelpSupportPage(),
                            ),
                          ),
                        ),
                        
                        const Divider(height: 1),
                        
                        _buildActionSetting(
                          'Delete Account',
                          'Permanently delete your account',
                          Icons.delete_forever,
                          () {
                            _showDeleteAccountDialog();
                          },
                          isDestructive: true,
                        ),
                      ]).animate()
                        .fadeIn(delay: 800.ms, duration: 600.ms)
                        .slideY(begin: 0.3, end: 0),
                      
                      const SizedBox(height: 40),
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

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: AmoraTheme.deepMidnight,
        ),
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: AmoraTheme.glassmorphism(
        color: Colors.white,
        borderRadius: 16,
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSwitchSetting(
    String title,
    String subtitle,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AmoraTheme.deepMidnight,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          color: AmoraTheme.deepMidnight.withOpacity(0.7),
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AmoraTheme.sunsetRose,
      ),
    );
  }

  Widget _buildSliderSetting(
    String title,
    String value,
    double currentValue,
    double min,
    double max,
    ValueChanged<double> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AmoraTheme.deepMidnight,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AmoraTheme.sunsetRose,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AmoraTheme.sunsetRose,
              inactiveTrackColor: AmoraTheme.sunsetRose.withOpacity(0.3),
              thumbColor: AmoraTheme.sunsetRose,
              overlayColor: AmoraTheme.sunsetRose.withOpacity(0.2),
            ),
            child: Slider(
              value: currentValue,
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRangeSliderSetting(
    String title,
    String value,
    RangeValues currentValues,
    double min,
    double max,
    ValueChanged<RangeValues> onChanged,
  ) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AmoraTheme.deepMidnight,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AmoraTheme.sunsetRose,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: AmoraTheme.sunsetRose,
              inactiveTrackColor: AmoraTheme.sunsetRose.withOpacity(0.3),
              thumbColor: AmoraTheme.sunsetRose,
              overlayColor: AmoraTheme.sunsetRose.withOpacity(0.2),
            ),
            child: RangeSlider(
              values: currentValues,
              min: min,
              max: max,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownSetting(
    String title,
    String value,
    List<String> options,
    ValueChanged<String?> onChanged,
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: AmoraTheme.deepMidnight,
        ),
      ),
      trailing: DropdownButton<String>(
        value: value,
        onChanged: onChanged,
        underline: const SizedBox(),
        items: options.map((option) {
          return DropdownMenuItem(
            value: option,
            child: Text(
              option,
              style: const TextStyle(
                color: AmoraTheme.deepMidnight,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActionSetting(
    String title,
    String subtitle,
    IconData icon,
    VoidCallback onTap, {
    bool isDestructive = false,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      leading: Icon(
        icon,
        color: isDestructive ? Colors.red : AmoraTheme.sunsetRose,
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: isDestructive ? Colors.red : AmoraTheme.deepMidnight,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontSize: 14,
          color: AmoraTheme.deepMidnight.withOpacity(0.7),
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: AmoraTheme.deepMidnight.withOpacity(0.3),
      ),
      onTap: onTap,
    );
  }

  void _showDeleteAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: const Text(
          'Delete Account',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.red,
          ),
        ),
        content: const Text(
          'Are you sure you want to delete your account? This action cannot be undone and all your data will be permanently removed.',
          style: TextStyle(
            color: AmoraTheme.deepMidnight,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(
                color: AmoraTheme.deepMidnight,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _deleteAccount();
              },
              child: const Text(
                'Delete',
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

  void _deleteAccount() async {
    try {
      await _settingsService.deleteAccount();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
        context.go('/onboarding');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete account: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
  
  void _showBlockedUsersPage() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) {
          return Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Blocked Users',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AmoraTheme.deepMidnight,
                    ),
                  ),
                ),
                Expanded(
                  child: FutureBuilder<Map<String, dynamic>>(
                    future: _settingsService.getBlockedUsers(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      
                      if (!snapshot.hasData || 
                          snapshot.data!['blocked_users'] == null ||
                          (snapshot.data!['blocked_users'] as List).isEmpty) {
                        return const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.block,
                                size: 64,
                                color: AmoraTheme.sunsetRose,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No blocked users',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: AmoraTheme.deepMidnight,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Users you block will appear here',
                                style: TextStyle(
                                  color: AmoraTheme.deepMidnight,
                                ),
                              ),
                            ],
                          ),
                        );
                      }
                      
                      final blockedUsers = snapshot.data!['blocked_users'] as List;
                      
                      return ListView.builder(
                        controller: scrollController,
                        itemCount: blockedUsers.length,
                        itemBuilder: (context, index) {
                          final blockedUser = blockedUsers[index];
                          return Container(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.grey.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: const CircleAvatar(
                                backgroundColor: AmoraTheme.sunsetRose,
                                child: Icon(
                                  Icons.person,
                                  color: Colors.white,
                                ),
                              ),
                              title: Text(
                                blockedUser['name'] ?? 'Unknown User',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AmoraTheme.deepMidnight,
                                ),
                              ),
                              subtitle: Text(
                                'Blocked on ${_formatDate(blockedUser['blocked_at'])}',
                                style: TextStyle(
                                  color: AmoraTheme.deepMidnight.withOpacity(0.7),
                                ),
                              ),
                              trailing: Container(
                                decoration: BoxDecoration(
                                  color: AmoraTheme.sunsetRose,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: TextButton(
                                  onPressed: () async {
                                    await _settingsService.unblockUser(blockedUser['id']);
                                    setState(() {}); // Refresh the page
                                    Navigator.pop(context);
                                    _showBlockedUsersPage(); // Reopen to refresh
                                  },
                                  child: const Text(
                                    'Unblock',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
  
  void _showEmergencyContactsPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const EmergencyContactsPage(),
      ),
    );
  }
  
  void _showCallHistoryPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const CallHistoryPage(),
      ),
    );
  }
  
  String _formatDate(String? dateString) {
    if (dateString == null) return 'Unknown';
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);
      
      if (difference.inDays == 0) {
        return 'Today';
      } else if (difference.inDays == 1) {
        return 'Yesterday';
      } else if (difference.inDays < 7) {
        return '${difference.inDays} days ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return 'Unknown';
    }
  }
}