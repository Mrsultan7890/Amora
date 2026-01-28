import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'webrtc_service.dart';
import 'api_service.dart';

enum CallState {
  idle,
  calling,
  ringing,
  connected,
  ended,
  failed
}

enum CallType {
  video,
  audio
}

class CallService {
  static CallService? _instance;
  static CallService get instance => _instance ??= CallService._();
  
  CallService._();
  
  final WebRTCService _webrtc = WebRTCService.instance;
  final ApiService _api = ApiService.instance;
  
  CallState _state = CallState.idle;
  CallType _type = CallType.video;
  String? _currentCallId;
  String? _otherUserId;
  DateTime? _callStartTime;
  
  // Callbacks
  Function(CallState)? onStateChanged;
  Function(MediaStream)? onRemoteStream;
  Function(String)? onError;
  
  CallState get state => _state;
  CallType get type => _type;
  String? get currentCallId => _currentCallId;
  String? get otherUserId => _otherUserId;
  Duration? get callDuration => _callStartTime != null 
      ? DateTime.now().difference(_callStartTime!) 
      : null;
  
  Future<void> initialize() async {
    await _webrtc.initialize();
    
    _webrtc.onRemoteStream = (stream) {
      onRemoteStream?.call(stream);
    };
    
    _webrtc.onIceCandidate = (candidate) {
      _sendSignalingMessage({
        'type': 'ice-candidate',
        'candidate': {
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        }
      });
    };
    
    _webrtc.onConnectionStateChange = (state) {
      if (state.contains('connected')) {
        _setState(CallState.connected);
        _callStartTime = DateTime.now();
      } else if (state.contains('failed') || state.contains('disconnected')) {
        _setState(CallState.failed);
      }
    };
  }
  
  Future<bool> checkNetworkAndShowWarning() async {
    return await _webrtc.isWiFiConnection();
  }
  
  Future<void> startCall(String userId, CallType callType) async {
    try {
      // Check if calling self
      final currentUser = await _api.getCurrentUser();
      if (currentUser.id == userId) {
        onError?.call('Cannot call yourself! Need 2 different devices for video calls.');
        return;
      }
      
      print('📞 Starting call to $userId');
      
      _otherUserId = userId;
      _type = callType;
      _currentCallId = DateTime.now().millisecondsSinceEpoch.toString();
      
      _setState(CallState.calling);
      
      // Start local stream
      final stream = await _webrtc.startLocalStream(
        video: callType == CallType.video,
        audio: true,
      );
      
      if (stream == null) {
        throw Exception('Failed to start camera/microphone');
      }
      
      // Create offer
      final offer = await _webrtc.createOffer();
      if (offer == null) {
        throw Exception('Failed to create call offer');
      }
      
      // Send call invitation
      await _sendSignalingMessage({
        'type': 'call-offer',
        'callId': _currentCallId,
        'callType': callType.name,
        'offer': {
          'type': offer.type,
          'sdp': offer.sdp,
        }
      });
      
      print('✅ Call started');
    } catch (e) {
      print('❌ Error starting call: $e');
      _setState(CallState.failed);
      onError?.call('Call failed: $e');
    }
  }
  
  Future<void> answerCall(Map<String, dynamic> callData) async {
    try {
      print('📱 Answering call');
      
      _currentCallId = callData['callId'];
      _type = callData['callType'] == 'video' ? CallType.video : CallType.audio;
      _setState(CallState.ringing);
      
      // Start local stream
      final stream = await _webrtc.startLocalStream(
        video: _type == CallType.video,
        audio: true,
      );
      
      if (stream == null) {
        throw Exception('Failed to start camera/microphone');
      }
      
      // Set remote offer
      final offer = RTCSessionDescription(
        callData['offer']['sdp'],
        callData['offer']['type'],
      );
      await _webrtc.setRemoteDescription(offer);
      
      // Create answer
      final answer = await _webrtc.createAnswer();
      if (answer == null) {
        throw Exception('Failed to create answer');
      }
      
      // Send answer
      await _sendSignalingMessage({
        'type': 'call-answer',
        'callId': _currentCallId,
        'answer': {
          'type': answer.type,
          'sdp': answer.sdp,
        }
      });
      
      print('✅ Call answered');
    } catch (e) {
      print('❌ Error answering call: $e');
      _setState(CallState.failed);
      onError?.call(e.toString());
    }
  }
  
  Future<void> handleSignalingMessage(Map<String, dynamic> message) async {
    try {
      switch (message['type']) {
        case 'call-offer':
          // Incoming call
          _otherUserId = message['from'];
          _setState(CallState.ringing);
          break;
          
        case 'call-answer':
          // Call accepted
          final answer = RTCSessionDescription(
            message['answer']['sdp'],
            message['answer']['type'],
          );
          await _webrtc.setRemoteDescription(answer);
          break;
          
        case 'ice-candidate':
          // ICE candidate
          final candidate = RTCIceCandidate(
            message['candidate']['candidate'],
            message['candidate']['sdpMid'],
            message['candidate']['sdpMLineIndex'],
          );
          await _webrtc.addIceCandidate(candidate);
          break;
          
        case 'call-end':
          // Call ended by other user
          await endCall();
          break;
      }
    } catch (e) {
      print('❌ Error handling signaling: $e');
    }
  }
  
  Future<void> toggleVideo() async {
    await _webrtc.toggleVideo();
  }
  
  Future<void> toggleAudio() async {
    await _webrtc.toggleAudio();
  }
  
  Future<void> switchCamera() async {
    await _webrtc.switchCamera();
  }
  
  Future<void> endCall() async {
    print('📴 Ending call');
    
    // Send end call signal
    if (_currentCallId != null) {
      await _sendSignalingMessage({
        'type': 'call-end',
        'callId': _currentCallId,
      });
    }
    
    // Save call history
    if (_currentCallId != null && _otherUserId != null) {
      await _saveCallHistory();
    }
    
    // Clean up WebRTC
    await _webrtc.hangUp();
    
    // Reset state
    _setState(CallState.ended);
    _currentCallId = null;
    _otherUserId = null;
    _callStartTime = null;
  }
  
  Future<void> _sendSignalingMessage(Map<String, dynamic> message) async {
    try {
      message['to'] = _otherUserId;
      await _api.sendSignalingMessage(message);
    } catch (e) {
      print('❌ Error sending signaling message: $e');
    }
  }
  
  Future<void> _saveCallHistory() async {
    try {
      await _api.saveCallHistory({
        'call_id': _currentCallId,
        'other_user_id': _otherUserId,
        'call_type': _type.name,
        'duration': callDuration?.inSeconds ?? 0,
        'status': _state == CallState.connected ? 'completed' : 'missed',
      });
    } catch (e) {
      print('❌ Error saving call history: $e');
    }
  }
  
  void _setState(CallState newState) {
    _state = newState;
    onStateChanged?.call(newState);
  }
  
  // Getters for WebRTC
  MediaStream? get localStream => _webrtc.localStream;
  MediaStream? get remoteStream => _webrtc.remoteStream;
  bool get isVideoEnabled => _webrtc.isVideoEnabled;
  bool get isAudioEnabled => _webrtc.isAudioEnabled;
}