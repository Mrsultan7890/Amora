import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:uuid/uuid.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/offline_emergency_service.dart';
import '../../../../core/services/sms_service.dart';
import '../../../../shared/models/emergency_contact_model.dart';

class EmergencyContactsPage extends StatefulWidget {
  const EmergencyContactsPage({super.key});

  @override
  State<EmergencyContactsPage> createState() => _EmergencyContactsPageState();
}

class _EmergencyContactsPageState extends State<EmergencyContactsPage> {
  final OfflineEmergencyService _emergencyService = OfflineEmergencyService.instance;
  List<EmergencyContact> _contacts = [];
  bool _isLoading = true;
  Map<String, bool> _permissionStatus = {};

  @override
  void initState() {
    super.initState();
    _loadContacts();
    _checkPermissions();
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
          child: Column(
            children: [
              // Header
              Padding(
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

              // Emergency toggle
              Container(
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

              // Info card
              Container(
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

              // Permission status card
              Container(
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

              // Contacts list
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AmoraTheme.sunsetRose,
                          ),
                        ),
                      )
                    : _contacts.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.contacts,
                                  size: 64,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No emergency contacts',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Add contacts for emergency situations',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _contacts.length,
                            itemBuilder: (context, index) {
                              final contact = _contacts[index];
                              return _buildContactCard(contact, index);
                            },
                          ),
              ),

              // Test buttons
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
}