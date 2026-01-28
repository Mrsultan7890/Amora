import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class WebRTCService {
  static WebRTCService? _instance;
  static WebRTCService get instance => _instance ??= WebRTCService._();
  
  WebRTCService._();
  
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  MediaStream? _remoteStream;
  
  // Google STUN servers (Free)
  final Map<String, dynamic> _configuration = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
      {'urls': 'stun:stun2.l.google.com:19302'},
    ]
  };
  
  final Map<String, dynamic> _constraints = {
    'mandatory': {},
    'optional': [
      {'DtlsSrtpKeyAgreement': true},
    ]
  };
  
  // Callbacks
  Function(MediaStream)? onRemoteStream;
  Function(RTCIceCandidate)? onIceCandidate;
  Function(String)? onConnectionStateChange;
  
  Future<bool> isWiFiConnection() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult == ConnectivityResult.wifi;
  }
  
  Future<void> initialize() async {
    print('🎥 Initializing WebRTC...');
    
    // Create peer connection
    _peerConnection = await createPeerConnection(_configuration, _constraints);
    
    // Set up event handlers
    _peerConnection!.onIceCandidate = (RTCIceCandidate candidate) {
      print('🧊 ICE Candidate: ${candidate.candidate}');
      onIceCandidate?.call(candidate);
    };
    
    _peerConnection!.onAddStream = (MediaStream stream) {
      print('📺 Remote stream added');
      _remoteStream = stream;
      onRemoteStream?.call(stream);
    };
    
    _peerConnection!.onConnectionState = (RTCPeerConnectionState state) {
      print('🔗 Connection state: $state');
      onConnectionStateChange?.call(state.toString());
    };
    
    print('✅ WebRTC initialized');
  }
  
  Future<MediaStream?> startLocalStream({bool video = true, bool audio = true}) async {
    try {
      print('📹 Starting local stream...');
      
      final Map<String, dynamic> mediaConstraints = {
        'audio': audio,
        'video': video ? {
          'mandatory': {
            'minWidth': '640',
            'minHeight': '480',
            'minFrameRate': '30',
          },
          'facingMode': 'user',
          'optional': [],
        } : false,
      };
      
      _localStream = await navigator.mediaDevices.getUserMedia(mediaConstraints);
      
      if (_peerConnection != null) {
        await _peerConnection!.addStream(_localStream!);
      }
      
      print('✅ Local stream started');
      return _localStream;
    } catch (e) {
      print('❌ Error starting local stream: $e');
      return null;
    }
  }
  
  Future<RTCSessionDescription?> createOffer() async {
    try {
      print('📞 Creating offer...');
      
      RTCSessionDescription offer = await _peerConnection!.createOffer();
      await _peerConnection!.setLocalDescription(offer);
      
      print('✅ Offer created');
      return offer;
    } catch (e) {
      print('❌ Error creating offer: $e');
      return null;
    }
  }
  
  Future<RTCSessionDescription?> createAnswer() async {
    try {
      print('📱 Creating answer...');
      
      RTCSessionDescription answer = await _peerConnection!.createAnswer();
      await _peerConnection!.setLocalDescription(answer);
      
      print('✅ Answer created');
      return answer;
    } catch (e) {
      print('❌ Error creating answer: $e');
      return null;
    }
  }
  
  Future<void> setRemoteDescription(RTCSessionDescription description) async {
    try {
      await _peerConnection!.setRemoteDescription(description);
      print('✅ Remote description set');
    } catch (e) {
      print('❌ Error setting remote description: $e');
    }
  }
  
  Future<void> addIceCandidate(RTCIceCandidate candidate) async {
    try {
      await _peerConnection!.addCandidate(candidate);
      print('✅ ICE candidate added');
    } catch (e) {
      print('❌ Error adding ICE candidate: $e');
    }
  }
  
  Future<void> toggleVideo() async {
    if (_localStream != null) {
      final videoTrack = _localStream!.getVideoTracks().first;
      videoTrack.enabled = !videoTrack.enabled;
      print('📹 Video toggled: ${videoTrack.enabled}');
    }
  }
  
  Future<void> toggleAudio() async {
    if (_localStream != null) {
      final audioTrack = _localStream!.getAudioTracks().first;
      audioTrack.enabled = !audioTrack.enabled;
      print('🎤 Audio toggled: ${audioTrack.enabled}');
    }
  }
  
  Future<void> switchCamera() async {
    if (_localStream != null) {
      final videoTrack = _localStream!.getVideoTracks().first;
      await Helper.switchCamera(videoTrack);
      print('🔄 Camera switched');
    }
  }
  
  Future<void> hangUp() async {
    print('📴 Hanging up...');
    
    // Stop local stream
    if (_localStream != null) {
      _localStream!.getTracks().forEach((track) {
        track.stop();
      });
      _localStream = null;
    }
    
    // Close peer connection
    if (_peerConnection != null) {
      await _peerConnection!.close();
      _peerConnection = null;
    }
    
    _remoteStream = null;
    print('✅ Call ended');
  }
  
  // Getters
  MediaStream? get localStream => _localStream;
  MediaStream? get remoteStream => _remoteStream;
  RTCPeerConnection? get peerConnection => _peerConnection;
  
  bool get isVideoEnabled {
    if (_localStream == null) return false;
    final videoTracks = _localStream!.getVideoTracks();
    return videoTracks.isNotEmpty && videoTracks.first.enabled;
  }
  
  bool get isAudioEnabled {
    if (_localStream == null) return false;
    final audioTracks = _localStream!.getAudioTracks();
    return audioTracks.isNotEmpty && audioTracks.first.enabled;
  }
}