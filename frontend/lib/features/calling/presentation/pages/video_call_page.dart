import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/call_service.dart';

class VideoCallPage extends StatefulWidget {
  final String otherUserId;
  final String otherUserName;
  final bool isIncoming;
  
  const VideoCallPage({
    super.key,
    required this.otherUserId,
    required this.otherUserName,
    this.isIncoming = false,
  });

  @override
  State<VideoCallPage> createState() => _VideoCallPageState();
}

class _VideoCallPageState extends State<VideoCallPage> {
  final CallService _callService = CallService.instance;
  final RTCVideoRenderer _localRenderer = RTCVideoRenderer();
  final RTCVideoRenderer _remoteRenderer = RTCVideoRenderer();
  
  bool _isVideoEnabled = true;
  bool _isAudioEnabled = true;
  bool _showControls = true;
  String _callDuration = '00:00';
  
  @override
  void initState() {
    super.initState();
    _initializeCall();
  }
  
  Future<void> _initializeCall() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
    
    // Initialize call service if not already done
    await _callService.initialize();
    
    _callService.onStateChanged = (state) {
      if (mounted) {
        setState(() {});
        if (state == CallState.ended || state == CallState.failed) {
          Navigator.of(context).pop();
        }
      }
    };
    
    _callService.onRemoteStream = (stream) {
      if (mounted) {
        _remoteRenderer.srcObject = stream;
        setState(() {});
      }
    };
    
    _callService.onError = (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Colors.red,
          ),
        );
        if (error.contains('permission')) {
          Navigator.of(context).pop();
        }
      }
    };
    
    // Set local stream when available
    if (_callService.localStream != null) {
      _localRenderer.srcObject = _callService.localStream;
    }
    
    // Start call duration timer
    _startDurationTimer();
    
    // Auto-hide controls after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _showControls = false);
      }
    });
  }
  
  void _startDurationTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _callService.state == CallState.connected) {
        final duration = _callService.callDuration;
        if (duration != null) {
          final minutes = duration.inMinutes.toString().padLeft(2, '0');
          final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
          setState(() => _callDuration = '$minutes:$seconds');
        }
        _startDurationTimer();
      }
    });
  }
  
  @override
  void dispose() {
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    super.dispose();
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: () => setState(() => _showControls = !_showControls),
        child: Stack(
          children: [
            // Remote video (full screen)
            if (_callService.remoteStream != null)
              Positioned.fill(
                child: RTCVideoView(
                  _remoteRenderer,
                  objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                ),
              )
            else
              Container(
                color: AmoraTheme.deepMidnight,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: AmoraTheme.sunsetRose,
                        child: Text(
                          widget.otherUserName[0].toUpperCase(),
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        widget.otherUserName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _getCallStateText(),
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            
            // Local video (small overlay)
            if (_callService.localStream != null && _isVideoEnabled)
              Positioned(
                top: 60,
                right: 20,
                child: Container(
                  width: 120,
                  height: 160,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: RTCVideoView(
                      _localRenderer,
                      mirror: true,
                      objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                    ),
                  ),
                ),
              ),
            
            // Top bar
            if (_showControls)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.black.withOpacity(0.7),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => _callService.switchCamera(),
                        icon: const Icon(Icons.flip_camera_ios, color: Colors.white),
                      ),
                      const Spacer(),
                      if (_callService.state == CallState.connected)
                        Text(
                          _callDuration,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            
            // Bottom controls
            if (_showControls)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(30),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.black.withOpacity(0.8),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Audio toggle
                      _buildControlButton(
                        icon: _isAudioEnabled ? Icons.mic : Icons.mic_off,
                        isActive: _isAudioEnabled,
                        onTap: () async {
                          await _callService.toggleAudio();
                          setState(() => _isAudioEnabled = _callService.isAudioEnabled);
                        },
                      ),
                      
                      // End call
                      _buildControlButton(
                        icon: Icons.call_end,
                        isActive: false,
                        backgroundColor: Colors.red,
                        onTap: () => _callService.endCall(),
                      ),
                      
                      // Video toggle
                      _buildControlButton(
                        icon: _isVideoEnabled ? Icons.videocam : Icons.videocam_off,
                        isActive: _isVideoEnabled,
                        onTap: () async {
                          await _callService.toggleVideo();
                          setState(() => _isVideoEnabled = _callService.isVideoEnabled);
                        },
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildControlButton({
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
    Color? backgroundColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: backgroundColor ?? (isActive ? Colors.white.withOpacity(0.2) : Colors.white.withOpacity(0.1)),
          shape: BoxShape.circle,
          border: Border.all(
            color: isActive ? Colors.white : Colors.white.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Icon(
          icon,
          color: backgroundColor != null ? Colors.white : (isActive ? Colors.white : Colors.white.withOpacity(0.7)),
          size: 28,
        ),
      ),
    );
  }
  
  String _getCallStateText() {
    switch (_callService.state) {
      case CallState.calling:
        return 'Calling...';
      case CallState.ringing:
        return 'Ringing...';
      case CallState.connected:
        return 'Connected';
      case CallState.ended:
        return 'Call ended';
      case CallState.failed:
        return 'Call failed';
      default:
        return '';
    }
  }
}