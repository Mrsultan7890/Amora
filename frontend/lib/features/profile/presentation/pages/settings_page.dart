import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/settings_service.dart';
import 'package:url_launcher/url_launcher.dart';

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
  double _maxDistance = 50.0;
  RangeValues _ageRange = const RangeValues(18, 35);
  String _interestedIn = 'Everyone';
  bool _showMeOnAmora = true;
  bool _incognitoMode = false;
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
      
      setState(() {
        _maxDistance = settings['max_distance'];
        _ageRange = RangeValues(ageRange[0], ageRange[1]);
        _interestedIn = settings['interested_in'];
        _pushNotifications = settings['push_notifications'];
        _emailNotifications = settings['email_notifications'];
        _showOnlineStatus = settings['show_online_status'];
        _showDistance = settings['show_distance'];
        _showMeOnAmora = settings['show_me_on_amora'];
        _incognitoMode = settings['incognito_mode'];
      });
    } catch (e) {
      print('Error loading settings: $e');
    } finally {
      setState(() => _isLoading = false);
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
                            setState(() => _maxDistance = value);
                            await _settingsService.setMaxDistance(value);
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
                            setState(() => _ageRange = values);
                            await _settingsService.setAgeRange(values.start, values.end);
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
                          (value) => setState(() => _showOnlineStatus = value),
                        ),
                        
                        const Divider(height: 1),
                        
                        _buildSwitchSetting(
                          'Show Distance',
                          'Display your distance to other users',
                          _showDistance,
                          (value) => setState(() => _showDistance = value),
                        ),
                        
                        const Divider(height: 1),
                        
                        _buildSwitchSetting(
                          'Show Me on Amora',
                          'Make your profile discoverable',
                          _showMeOnAmora,
                          (value) => setState(() => _showMeOnAmora = value),
                        ),
                        
                        const Divider(height: 1),
                        
                        _buildSwitchSetting(
                          'Incognito Mode',
                          'Only people you like can see your profile',
                          _incognitoMode,
                          (value) => setState(() => _incognitoMode = value),
                        ),
                      ]).animate()
                        .fadeIn(delay: 600.ms, duration: 600.ms)
                        .slideY(begin: 0.3, end: 0),
                      
                      const SizedBox(height: 24),
                      
                      // Account Actions
                      _buildSectionHeader('Account'),
                      
                      _buildSettingsCard([
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
                          () => _openUrl('https://amora.app/privacy'),
                        ),
                        
                        const Divider(height: 1),
                        
                        _buildActionSetting(
                          'Terms of Service',
                          'Read our terms of service',
                          Icons.description,
                          () => _openUrl('https://amora.app/terms'),
                        ),
                        
                        const Divider(height: 1),
                        
                        _buildActionSetting(
                          'Help & Support',
                          'Get help or contact support',
                          Icons.help,
                          () => _openUrl('mailto:support@amora.app'),
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
                  child: FutureBuilder<List<String>>(
                    future: _settingsService.getBlockedUsers(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Center(
                          child: Text(
                            'No blocked users',
                            style: TextStyle(color: AmoraTheme.deepMidnight),
                          ),
                        );
                      }
                      
                      return ListView.builder(
                        controller: scrollController,
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          final userId = snapshot.data![index];
                          return ListTile(
                            leading: const CircleAvatar(
                              child: Icon(Icons.person),
                            ),
                            title: Text('User $userId'),
                            trailing: TextButton(
                              onPressed: () async {
                                await _settingsService.unblockUser(userId);
                                Navigator.pop(context);
                              },
                              child: const Text(
                                'Unblock',
                                style: TextStyle(color: AmoraTheme.sunsetRose),
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
  
  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open $url'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}