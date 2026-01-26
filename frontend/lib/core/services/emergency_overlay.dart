import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class EmergencyOverlay {
  static OverlayEntry? _overlayEntry;
  
  static void showEmergencyAlert(BuildContext context, {
    required int alertsSent,
    required String location,
  }) {
    _removeOverlay();
    
    _overlayEntry = OverlayEntry(
      builder: (context) => _EmergencyAlertWidget(
        alertsSent: alertsSent,
        location: location,
        onDismiss: _removeOverlay,
      ),
    );
    
    Overlay.of(context).insert(_overlayEntry!);
    
    // Auto dismiss after 5 seconds
    Future.delayed(const Duration(seconds: 5), () {
      _removeOverlay();
    });
  }
  
  static void showEmergencyError(BuildContext context, String error) {
    _removeOverlay();
    
    _overlayEntry = OverlayEntry(
      builder: (context) => _EmergencyErrorWidget(
        error: error,
        onDismiss: _removeOverlay,
      ),
    );
    
    Overlay.of(context).insert(_overlayEntry!);
    
    // Auto dismiss after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      _removeOverlay();
    });
  }
  
  static void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }
}

class _EmergencyAlertWidget extends StatelessWidget {
  final int alertsSent;
  final String location;
  final VoidCallback onDismiss;
  
  const _EmergencyAlertWidget({
    required this.alertsSent,
    required this.location,
    required this.onDismiss,
  });
  
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black.withOpacity(0.8),
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(32),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 64,
                ),
                const SizedBox(height: 16),
                const Text(
                  '🚨 EMERGENCY ALERT SENT',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Alert sent to $alertsSent matches',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Location: $location',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: onDismiss,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('OK'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmergencyErrorWidget extends StatelessWidget {
  final String error;
  final VoidCallback onDismiss;
  
  const _EmergencyErrorWidget({
    required this.error,
    required this.onDismiss,
  });
  
  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: Colors.black.withOpacity(0.8),
        child: Center(
          child: Container(
            margin: const EdgeInsets.all(32),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.error,
                  color: Colors.red,
                  size: 64,
                ),
                const SizedBox(height: 16),
                const Text(
                  '❌ EMERGENCY ALERT FAILED',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  error,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: onDismiss,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('OK'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}