import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:uuid/uuid.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/offline_emergency_service.dart';
import '../../../../core/services/emergency_service.dart';
import '../../../../core/services/settings_service.dart';
import '../../../../core/services/sms_service.dart';
import '../../../../core/services/emergency_voice_service.dart';
import '../../../../core/services/bluetooth_emergency_service.dart';
import '../../../../shared/models/emergency_contact_model.dart';

class EmergencyContactsPage extends StatefulWidget {
  const EmergencyContactsPage({super.key});

  @override
  State<EmergencyContactsPage> createState() => _EmergencyContactsPageState();
}

class _EmergencyContactsPageState extends State<EmergencyContactsPage> with TickerProviderStateMixin {
  final OfflineEmergencyService _emergencyService = OfflineEmergencyService.instance;
  List<EmergencyContact> _contacts = [];
  bool _isLoading = true;
  Map<String, bool> _permissionStatus = {};
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadContacts();
    _checkPermissions();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    setState(() => _isLoading = true);
    await _emergencyService.initialize();
    
    setState(() {
      _contacts = _emergencyService.contacts;
      _isLoading = false;
    });
  }

  Future<void> _checkPermissions() async {
    final smsPermission = await Permission.sms.status;
    final phonePermission = await Permission.phone.status;
    final locationPermission = await Permission.location.status;
    final hasSpecialPermissions = await SmsService.checkPermissions();
    
    setState(() {
      _permissionStatus = {
        'SMS': smsPermission.isGranted,
        'Phone': phonePermission.isGranted,
        'Location': locationPermission.isGranted,
        'Battery Optimization': hasSpecialPermissions,
        'Display Over Apps': hasSpecialPermissions,
      };
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: AmoraTheme.backgroundGradient,
        ),
        child: SafeArea(
          child: CustomScrollView(
            slivers: [
              // Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(
                          Icons.arrow_back_ios,
                          color: AmoraTheme.deepMidnight,
                        ),
                      ),
                      const Expanded(
                        child: Text(
                          'Emergency Contacts',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AmoraTheme.deepMidnight,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _addContact,
                        icon: const Icon(
                          Icons.add,
                          color: AmoraTheme.sunsetRose,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Emergency toggle
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: AmoraTheme.glassmorphism(
                    color: _emergencyService.isEnabled ? Colors.green.shade50 : Colors.grey.shade50,
                    borderRadius: 12,
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _emergencyService.isEnabled ? Icons.security : Icons.security_outlined,
                        color: _emergencyService.isEnabled ? Colors.green : Colors.grey,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Emergency System',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: _emergencyService.isEnabled ? Colors.green : Colors.grey,
                              ),
                            ),
                            Text(
                              _emergencyService.isEnabled 
                                ? 'Shake detection active (30s cooldown)'
                                : 'Shake detection disabled',
                              style: TextStyle(
                                fontSize: 14,
                                color: _emergencyService.isEnabled ? Colors.green.shade700 : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: _emergencyService.isEnabled,
                        onChanged: (value) async {
                          await _emergencyService.setEnabled(value);
                          final EmergencyService emergencyService = EmergencyService.instance;
                          await emergencyService.setEmergencyEnabled(value);
                          final SettingsService settingsService = SettingsService.instance;
                          await settingsService.setEmergencyShakeEnabled(value);
                          
                          setState(() {});
                          
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  value 
                                    ? '🚨 Emergency system ENABLED' 
                                    : '❌ Emergency system DISABLED'
                                ),
                                backgroundColor: value ? Colors.green : Colors.red,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          }
                        },
                        activeColor: Colors.green,
                      ),
                    ],
                  ),
                ).animate()
                  .fadeIn(duration: 600.ms)
                  .slideY(begin: 0.3, end: 0),
              ),

              // Info card
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: AmoraTheme.glassmorphism(
                    color: Colors.red.shade50,
                    borderRadius: 12,
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.warning,
                            color: Colors.red.shade600,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Text(
                              'Emergency Contacts',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'These contacts will receive SMS and calls during emergency situations, even without internet.',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.red,
                        ),
                      ),
                    ],
                  ),
                ).animate()
                  .fadeIn(duration: 600.ms)
                  .slideY(begin: 0.3, end: 0),
              ),

              // Permission status card
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: AmoraTheme.glassmorphism(
                    color: Colors.blue.shade50,
                    borderRadius: 12,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.verified_user,
                            color: Colors.blue.shade600,
                            size: 24,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Permission Status',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () async {
                              await _checkPermissions();
                            },
                            child: const Text('Refresh'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      ..._permissionStatus.entries.map((entry) => 
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Icon(
                                entry.value ? Icons.check_circle : Icons.cancel,
                                color: entry.value ? Colors.green : Colors.red,
                                size: 20,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  entry.key,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: entry.value ? Colors.green.shade700 : Colors.red.shade700,
                                  ),
                                ),
                              ),
                              if (!entry.value)
                                TextButton(
                                  onPressed: () => _requestSpecificPermission(entry.key),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  ),
                                  child: const Text(
                                    'Grant',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ).toList(),
                      if (_permissionStatus.values.any((granted) => !granted))
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: () async {
                                await SmsService.requestSpecialPermissions();
                                await _emergencyService.requestPermissions();
                                await Future.delayed(const Duration(seconds: 1));
                                await _checkPermissions();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text('Grant All Permissions'),
                            ),
                          ),
                        ),
                    ],
                  ),
                ).animate()
                  .fadeIn(duration: 600.ms)
                  .slideY(begin: 0.3, end: 0),
              ),

              // Tabs
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicator: BoxDecoration(
                      gradient: AmoraTheme.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    labelColor: Colors.white,
                    unselectedLabelColor: AmoraTheme.deepMidnight,
                    tabs: const [
                      Tab(text: 'My Contacts'),
                      Tab(text: 'Voice Setup'),
                      Tab(text: 'Bluetooth SOS'),
                    ],
                  ),
                ),
              ),

              // Tab Content
              SliverFillRemaining(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildContactsTab(),
                    _buildVoiceSetupTab(),
                    _buildBluetoothSOSTab(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContactCard(EmergencyContact contact, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: AmoraTheme.glassmorphism(
        color: Colors.white,
        borderRadius: 12,
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: CircleAvatar(
          backgroundColor: _getContactColor(contact.type),
          child: Icon(
            _getContactIcon(contact.type),
            color: Colors.white,
          ),
        ),
        title: Text(
          contact.name,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AmoraTheme.deepMidnight,
          ),
        ),
        subtitle: Text(
          contact.phoneNumber,
          style: TextStyle(
            fontSize: 14,
            color: AmoraTheme.deepMidnight.withOpacity(0.7),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Switch(
              value: contact.isEnabled,
              onChanged: (value) => _toggleContact(contact, value),
              activeColor: AmoraTheme.sunsetRose,
            ),
            PopupMenuButton(
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Text('Edit'),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete'),
                ),
              ],
              onSelected: (value) {
                if (value == 'edit') {
                  _editContact(contact);
                } else if (value == 'delete') {
                  _deleteContact(contact);
                }
              },
            ),
          ],
        ),
      ),
    ).animate()
      .fadeIn(delay: (index * 100).ms, duration: 600.ms)
      .slideX(begin: 0.3, end: 0);
  }

  Color _getContactColor(EmergencyContactType type) {
    switch (type) {
      case EmergencyContactType.police:
        return Colors.blue;
      case EmergencyContactType.ambulance:
        return Colors.red;
      case EmergencyContactType.family:
        return Colors.green;
      case EmergencyContactType.friend:
        return Colors.orange;
      case EmergencyContactType.personal:
        return Colors.purple;
    }
  }

  IconData _getContactIcon(EmergencyContactType type) {
    switch (type) {
      case EmergencyContactType.police:
        return Icons.local_police;
      case EmergencyContactType.ambulance:
        return Icons.local_hospital;
      case EmergencyContactType.family:
        return Icons.family_restroom;
      case EmergencyContactType.friend:
        return Icons.people;
      case EmergencyContactType.personal:
        return Icons.person;
    }
  }

  void _addContact() {
    _showContactDialog();
  }

  void _editContact(EmergencyContact contact) {
    _showContactDialog(contact: contact);
  }

  void _showContactDialog({EmergencyContact? contact}) {
    final nameController = TextEditingController(text: contact?.name ?? '');
    final phoneController = TextEditingController(text: contact?.phoneNumber ?? '');
    EmergencyContactType selectedType = contact?.type ?? EmergencyContactType.personal;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(contact == null ? 'Add Contact' : 'Edit Contact'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Phone Number',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<EmergencyContactType>(
                value: selectedType,
                decoration: const InputDecoration(
                  labelText: 'Type',
                  border: OutlineInputBorder(),
                ),
                items: EmergencyContactType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(_getTypeDisplayName(type)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setDialogState(() {
                      selectedType = value;
                    });
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty && phoneController.text.isNotEmpty) {
                  final newContact = EmergencyContact(
                    id: contact?.id ?? const Uuid().v4(),
                    name: nameController.text,
                    phoneNumber: phoneController.text,
                    type: selectedType,
                    isEnabled: contact?.isEnabled ?? true,
                  );

                  if (contact == null) {
                    _emergencyService.addContact(newContact);
                  } else {
                    _emergencyService.updateContact(newContact);
                  }

                  _loadContacts();
                  Navigator.pop(context);
                }
              },
              child: Text(contact == null ? 'Add' : 'Save'),
            ),
          ],
        ),
      ),
    );
  }

  String _getTypeDisplayName(EmergencyContactType type) {
    switch (type) {
      case EmergencyContactType.police:
        return '🚔 Police';
      case EmergencyContactType.ambulance:
        return '🚑 Ambulance';
      case EmergencyContactType.family:
        return '👨‍👩‍👧‍👦 Family';
      case EmergencyContactType.friend:
        return '👥 Friend';
      case EmergencyContactType.personal:
        return '📞 Personal';
    }
  }

  void _toggleContact(EmergencyContact contact, bool enabled) async {
    final updatedContact = contact.copyWith(isEnabled: enabled);
    await _emergencyService.updateContact(updatedContact);
    _loadContacts();
  }

  void _deleteContact(EmergencyContact contact) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Contact'),
        content: Text('Are you sure you want to delete ${contact.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _emergencyService.removeContact(contact.id);
              _loadContacts();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _requestSpecificPermission(String permissionType) async {
    switch (permissionType) {
      case 'SMS':
        await Permission.sms.request();
        break;
      case 'Phone':
        await Permission.phone.request();
        break;
      case 'Location':
        await Permission.location.request();
        break;
      case 'Battery Optimization':
      case 'Display Over Apps':
        await SmsService.requestSpecialPermissions();
        break;
    }
    
    await Future.delayed(const Duration(seconds: 1));
    await _checkPermissions();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$permissionType permission requested'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _testEmergencySystem() async {
    // Check special permissions first
    final hasSpecialPermissions = await SmsService.checkPermissions();
    
    if (!hasSpecialPermissions) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('🚨 Emergency Setup Required'),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('For AUTOMATIC emergency alerts, you need:'),
              SizedBox(height: 12),
              Text('1. 📞 Phone permission'),
              Text('2. 💬 SMS permission'),
              Text('3. 🔋 Battery optimization OFF'),
              Text('4. 📱 Display over other apps'),
              Text('5. 👥 At least 1 emergency contact'),
              SizedBox(height: 12),
              Text('This allows shake detection to work even when phone is locked and automatically send SMS/calls without opening apps.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                await SmsService.requestSpecialPermissions();
                await _emergencyService.requestPermissions();
                await Future.delayed(const Duration(seconds: 2));
                _testEmergencySystem();
              },
              child: const Text('Setup Emergency Mode'),
            ),
          ],
        ),
      );
      return;
    }
    
    final isWorking = await _emergencyService.testEmergencySystem();
    
    if (mounted) {
      if (isWorking) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ AUTOMATIC Emergency system is ready! Shake phone to test.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Setup incomplete. Please add emergency contacts.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _testOfflineEmergency() async {
    // Check if contacts exist first
    if (_contacts.where((c) => c.isEnabled).isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('❌ No enabled emergency contacts found!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🚨 Test Offline Emergency'),
        content: Text(
          'This will send REAL SMS and make REAL calls to ${_contacts.where((c) => c.isEnabled).length} contacts:\n\n${_contacts.where((c) => c.isEnabled).map((c) => '• ${c.name} (${c.phoneNumber})').join('\n')}\n\nAre you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('YES, TEST NOW'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      // Show immediate feedback
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('🚨 SENDING EMERGENCY ALERTS...'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      
      // Trigger vibration immediately
      HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 200));
      HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 200));
      HapticFeedback.heavyImpact();
      
      try {
        await _emergencyService.triggerOfflineEmergency();
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✅ AUTOMATIC SMS sent and calls made to ${_contacts.where((c) => c.isEnabled).length} contacts! No manual action needed.'),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 5),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Test failed: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  Widget _buildContactsTab() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(AmoraTheme.sunsetRose),
        ),
      );
    }

    if (_contacts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.contact_emergency,
              size: 64,
              color: AmoraTheme.sunsetRose,
            ),
            const SizedBox(height: 16),
            const Text(
              'No Emergency Contacts',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AmoraTheme.deepMidnight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Add emergency contacts to enable\nshake detection alerts',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AmoraTheme.deepMidnight.withOpacity(0.7),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _addContact,
              style: ElevatedButton.styleFrom(
                backgroundColor: AmoraTheme.sunsetRose,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
              child: const Text('Add First Contact'),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _contacts.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: _buildContactCard(_contacts[index], index),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _testEmergencySystem,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Test Emergency System',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _testOfflineEmergency,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    '🚨 TEST OFFLINE EMERGENCY 🚨',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVoiceSetupTab() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Info Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: AmoraTheme.glassmorphism(color: Colors.white, borderRadius: 12),
            child: const Column(
              children: [
                Icon(Icons.record_voice_over, size: 48, color: AmoraTheme.sunsetRose),
                SizedBox(height: 12),
                Text(
                  'Emergency Voice Message',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AmoraTheme.deepMidnight),
                ),
                SizedBox(height: 8),
                Text(
                  'Record a voice message that will be sent to your emergency contacts when you shake your phone in distress.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Voice Setup Content
          Expanded(
            child: _VoiceSetupContent(),
          ),
        ],
      ),
    );
  }
}

class _VoiceSetupContent extends StatefulWidget {
  @override
  State<_VoiceSetupContent> createState() => _VoiceSetupContentState();
}

class _VoiceSetupContentState extends State<_VoiceSetupContent> {
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
    return Column(
      children: [
        // Recording Status
        if (_voiceService.hasRecording)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: AmoraTheme.glassmorphism(color: Colors.green.withOpacity(0.1), borderRadius: 12),
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
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.stop, color: Colors.white, size: 32),
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
              GestureDetector(
                onTap: _startRecording,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: AmoraTheme.primaryGradient,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.mic, color: Colors.white, size: 32),
                ),
              ),
              const SizedBox(height: 12),
              const Text('Tap to Record', style: TextStyle(fontWeight: FontWeight.w600)),
              
              const SizedBox(height: 20),
              
              if (_voiceService.hasRecording) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _isPlaying ? null : _playRecording,
                      icon: Icon(_isPlaying ? Icons.volume_up : Icons.play_arrow),
                      label: Text(_isPlaying ? 'Playing...' : 'Play'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                    ),
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
          decoration: AmoraTheme.glassmorphism(color: Colors.orange.withOpacity(0.1), borderRadius: 12),
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
    );
  }
  
  Widget _buildBluetoothSOSTab() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Info Card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: AmoraTheme.glassmorphism(color: Colors.white, borderRadius: 12),
            child: const Column(
              children: [
                Icon(Icons.bluetooth, size: 48, color: Colors.blue),
                SizedBox(height: 12),
                Text(
                  'Bluetooth Emergency SOS',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AmoraTheme.deepMidnight),
                ),
                SizedBox(height: 8),
                Text(
                  'When you shake your phone in emergency, it will broadcast SOS message to ALL nearby Bluetooth devices - even if they don\'t have this app!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Bluetooth Setup Content
          Expanded(
            child: _BluetoothSOSContent(),
          ),
        ],
      ),
    );
  }
}

class _BluetoothSOSContent extends StatefulWidget {
  @override
  State<_BluetoothSOSContent> createState() => _BluetoothSOSContentState();
}

class _BluetoothSOSContentState extends State<_BluetoothSOSContent> {
  final BluetoothEmergencyService _bluetoothService = BluetoothEmergencyService.instance;
  bool _isBluetoothEnabled = false;
  bool _isSOSEnabled = false;
  bool _isListenerActive = false;
  
  @override
  void initState() {
    super.initState();
    _loadSettings();
    _checkBluetoothStatus();
  }
  
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _isSOSEnabled = prefs.getBool('bluetooth_sos_enabled') ?? false;
      _isListenerActive = prefs.getBool('bluetooth_listener_active') ?? false;
    });
    
    if (_isListenerActive) {
      await _bluetoothService.startEmergencyListener();
    }
  }
  
  Future<void> _checkBluetoothStatus() async {
    final enabled = await _bluetoothService.isBluetoothEnabled();
    setState(() {
      _isBluetoothEnabled = enabled;
    });
  }
  
  Future<void> _toggleBluetoothSOS(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('bluetooth_sos_enabled', enabled);
    
    setState(() {
      _isSOSEnabled = enabled;
    });
    
    if (enabled && !_isBluetoothEnabled) {
      await _bluetoothService.enableBluetooth();
      await _checkBluetoothStatus();
    }
    
    _showMessage(enabled ? 'Bluetooth SOS enabled' : 'Bluetooth SOS disabled');
  }
  
  Future<void> _toggleListener(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('bluetooth_listener_active', enabled);
    
    setState(() {
      _isListenerActive = enabled;
    });
    
    if (enabled) {
      if (!_isBluetoothEnabled) {
        await _bluetoothService.enableBluetooth();
        await _checkBluetoothStatus();
      }
      await _bluetoothService.startEmergencyListener();
      _showMessage('Now listening for emergency broadcasts');
    } else {
      await _bluetoothService.stopEmergencyListener();
      _showMessage('Stopped listening for emergencies');
    }
  }
  
  Future<void> _testBluetoothSOS() async {
    if (!_isBluetoothEnabled) {
      _showMessage('Please enable Bluetooth first');
      return;
    }
    
    await _bluetoothService.broadcastEmergency(
      phoneNumber: '+91XXXXXXXXXX',
      latitude: 19.4148171,
      longitude: 72.8038184,
      customMessage: 'TEST EMERGENCY - This is a test of Bluetooth SOS system',
    );
    
    _showMessage('Test emergency broadcast sent to nearby devices!');
  }
  
  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Bluetooth Status
        Container(
          padding: const EdgeInsets.all(16),
          decoration: AmoraTheme.glassmorphism(
            color: _isBluetoothEnabled ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1), 
            borderRadius: 12
          ),
          child: Row(
            children: [
              Icon(
                Icons.bluetooth,
                color: _isBluetoothEnabled ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bluetooth Status',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      _isBluetoothEnabled ? 'Enabled and ready' : 'Disabled - Tap to enable',
                      style: TextStyle(
                        color: _isBluetoothEnabled ? Colors.green : Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (!_isBluetoothEnabled)
                ElevatedButton(
                  onPressed: () async {
                    await _bluetoothService.enableBluetooth();
                    await _checkBluetoothStatus();
                  },
                  child: const Text('Enable'),
                ),
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        
        // SOS Broadcasting Toggle
        Container(
          padding: const EdgeInsets.all(16),
          decoration: AmoraTheme.glassmorphism(color: Colors.white, borderRadius: 12),
          child: Row(
            children: [
              const Icon(Icons.sos, color: Colors.red),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Emergency Broadcasting',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      _isSOSEnabled 
                        ? 'Will broadcast SOS when you shake phone'
                        : 'Disabled - Enable to broadcast emergencies',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _isSOSEnabled,
                onChanged: _toggleBluetoothSOS,
                activeColor: Colors.red,
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Emergency Listener Toggle
        Container(
          padding: const EdgeInsets.all(16),
          decoration: AmoraTheme.glassmorphism(color: Colors.white, borderRadius: 12),
          child: Row(
            children: [
              const Icon(Icons.hearing, color: Colors.blue),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Emergency Listener',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    Text(
                      _isListenerActive 
                        ? 'Listening for emergency broadcasts from others'
                        : 'Not listening - Enable to help others in emergency',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _isListenerActive,
                onChanged: _toggleListener,
                activeColor: Colors.blue,
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Test Button
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _testBluetoothSOS,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: const Text(
              'Test Bluetooth SOS',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
        
        const Spacer(),
        
        // Instructions
        Container(
          padding: const EdgeInsets.all(16),
          decoration: AmoraTheme.glassmorphism(color: Colors.blue.withOpacity(0.1), borderRadius: 12),
          child: const Column(
            children: [
              Icon(Icons.info_outline, color: Colors.blue),
              SizedBox(height: 8),
              Text(
                'How Bluetooth SOS Works:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 4),
              Text(
                '• Shake phone in emergency → Broadcasts SOS to ALL nearby phones\n• Other phones get notification with your number & location\n• Works WITHOUT internet - pure Bluetooth\n• Receiver can call you or share your location\n• Keep listener ON to help others in emergency',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }
}