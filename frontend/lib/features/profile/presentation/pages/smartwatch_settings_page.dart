import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/services/smartwatch_service.dart';

class SmartwatchSettingsPage extends StatefulWidget {
  const SmartwatchSettingsPage({Key? key}) : super(key: key);

  @override
  State<SmartwatchSettingsPage> createState() => _SmartwatchSettingsPageState();
}

class _SmartwatchSettingsPageState extends State<SmartwatchSettingsPage> {
  final SmartwatchService _smartwatchService = SmartwatchService();
  bool _isConnected = false;
  String _connectedDevice = '';
  bool _emergencyEnabled = true;
  bool _heartRateMonitoring = false;
  bool _fallDetection = true;

  @override
  void initState() {
    super.initState();
    _loadWatchStatus();
  }

  void _loadWatchStatus() async {
    final status = await _smartwatchService.getConnectionStatus();
    setState(() {
      _isConnected = status['connected'] ?? false;
      _connectedDevice = status['device'] ?? '';
      _emergencyEnabled = status['emergency_enabled'] ?? true;
      _heartRateMonitoring = status['heart_rate_monitoring'] ?? false;
      _fallDetection = status['fall_detection'] ?? true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Smartwatch Settings', style: TextStyle(color: Colors.white)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Connection Status Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(15),
                border: Border.all(
                  color: _isConnected ? Colors.green : Colors.red,
                  width: 2,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.watch,
                    size: 50,
                    color: _isConnected ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _isConnected ? 'Connected' : 'Not Connected',
                    style: TextStyle(
                      color: _isConnected ? Colors.green : Colors.red,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (_isConnected) ...[
                    const SizedBox(height: 5),
                    Text(
                      _connectedDevice,
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Connect/Disconnect Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isConnected ? _disconnectWatch : _connectWatch,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isConnected ? Colors.red : Colors.pink,
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  _isConnected ? 'Disconnect Watch' : 'Connect Watch',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 30),

            // Emergency Settings
            const Text(
              'Emergency Settings',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 15),

            // Emergency Toggle
            _buildSettingTile(
              'Emergency Features',
              'Enable emergency triggers from watch',
              _emergencyEnabled,
              (value) {
                setState(() => _emergencyEnabled = value);
                _smartwatchService.updateEmergencySettings(value);
              },
              Icons.emergency,
            ),

            // Fall Detection
            _buildSettingTile(
              'Fall Detection',
              'Trigger emergency when fall detected',
              _fallDetection,
              (value) {
                setState(() => _fallDetection = value);
                _smartwatchService.updateFallDetection(value);
              },
              Icons.accessibility_new,
            ),

            // Heart Rate Monitoring
            _buildSettingTile(
              'Heart Rate Monitoring',
              'Monitor for abnormal heart rate patterns',
              _heartRateMonitoring,
              (value) {
                setState(() => _heartRateMonitoring = value);
                _smartwatchService.updateHeartRateMonitoring(value);
              },
              Icons.favorite,
            ),

            const SizedBox(height: 30),

            // Emergency Contacts Info
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info, color: Colors.blue, size: 20),
                      SizedBox(width: 10),
                      Text(
                        'Emergency Contacts',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Your existing emergency contacts will be used for watch emergencies. To manage contacts, go to Emergency Contacts in Profile settings.',
                    style: TextStyle(color: Colors.white70, fontSize: 14),
                  ),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Manage Emergency Contacts →',
                      style: TextStyle(color: Colors.pink),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Test Emergency Button
            if (_isConnected && _emergencyEnabled)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _testEmergency,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.orange),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Test Emergency System',
                    style: TextStyle(color: Colors.orange, fontSize: 16),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingTile(
    String title,
    String subtitle,
    bool value,
    Function(bool) onChanged,
    IconData icon,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.pink, size: 24),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: Colors.pink,
          ),
        ],
      ),
    );
  }

  void _connectWatch() async {
    try {
      final result = await _smartwatchService.connectWatch();
      if (result['success']) {
        HapticFeedback.lightImpact();
        _loadWatchStatus();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Watch connected successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Failed to connect watch'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error connecting to watch'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _disconnectWatch() async {
    try {
      await _smartwatchService.disconnectWatch();
      HapticFeedback.lightImpact();
      _loadWatchStatus();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Watch disconnected'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error disconnecting watch'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _testEmergency() async {
    try {
      await _smartwatchService.testEmergencySystem();
      HapticFeedback.heavyImpact();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Emergency test completed! Check your emergency contacts.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Emergency test failed'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}