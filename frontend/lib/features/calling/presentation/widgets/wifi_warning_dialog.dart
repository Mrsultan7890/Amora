import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';

class WiFiWarningDialog extends StatelessWidget {
  final VoidCallback onContinueAnyway;
  final VoidCallback onSwitchToMobile;
  
  const WiFiWarningDialog({
    super.key,
    required this.onContinueAnyway,
    required this.onSwitchToMobile,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: AmoraTheme.glassmorphism(color: Colors.white, borderRadius: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.wifi_off, color: Colors.orange, size: 40),
            ),
            
            const SizedBox(height: 20),
            
            const Text(
              'WiFi Detected ⚠️',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AmoraTheme.deepMidnight),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 12),
            
            const Text(
              'For best call quality, switch to mobile data. WiFi networks may block video calls due to security settings.',
              style: TextStyle(fontSize: 16, color: AmoraTheme.deepMidnight, height: 1.4),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 24),
            
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                      onContinueAnyway();
                    },
                    child: const Text('Continue Anyway', style: TextStyle(color: AmoraTheme.deepMidnight)),
                  ),
                ),
                
                const SizedBox(width: 12),
                
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(gradient: AmoraTheme.primaryGradient, borderRadius: BorderRadius.circular(8)),
                    child: TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                        onSwitchToMobile();
                      },
                      child: const Text('Switch to Mobile', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  static Future<void> show(BuildContext context, {required VoidCallback onContinueAnyway, required VoidCallback onSwitchToMobile}) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WiFiWarningDialog(onContinueAnyway: onContinueAnyway, onSwitchToMobile: onSwitchToMobile),
    );
  }
}