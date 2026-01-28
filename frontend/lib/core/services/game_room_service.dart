import 'dart:async';
import 'dart:math';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'api_service.dart';

enum GameState {
  waiting,
  spinning,
  questioning,
  answering,
  finished
}

class GamePlayer {
  final String id;
  final String name;
  final String? avatar;
  bool isConnected;
  bool isMuted;
  
  GamePlayer({
    required this.id,
    required this.name,
    this.avatar,
    this.isConnected = true,
    this.isMuted = false,
  });
}

class GameRoom {
  final String id;
  final List<GamePlayer> players;
  GameState state;
  String? currentQuestion;
  String? selectedPlayerId;
  int round;
  
  GameRoom({
    required this.id,
    required this.players,
    this.state = GameState.waiting,
    this.currentQuestion,
    this.selectedPlayerId,
    this.round = 1,
  });
}

class GameRoomService {
  static GameRoomService? _instance;
  static GameRoomService get instance => _instance ??= GameRoomService._();
  
  GameRoomService._();
  
  final ApiService _api = ApiService.instance;
  GameRoom? _currentRoom;
  StreamController<GameRoom>? _roomController;
  
  // Voice chat
  RTCPeerConnection? _peerConnection;
  MediaStream? _localStream;
  final Map<String, MediaStream> _remoteStreams = {};
  
  // Callbacks
  Function(GameRoom)? onRoomUpdate;
  Function(String)? onError;
  
  Stream<GameRoom>? get roomStream => _roomController?.stream;
  GameRoom? get currentRoom => _currentRoom;
  
  Future<void> initialize() async {
    _roomController = StreamController<GameRoom>.broadcast();
  }
  
  Future<GameRoom> createRoom() async {
    try {
      final response = await _api.createGameRoom();
      final room = GameRoom(
        id: response['room_id'],
        players: [],
      );
      
      _currentRoom = room;
      _roomController?.add(room);
      
      await _initializeVoiceChat();
      return room;
    } catch (e) {
      throw Exception('Failed to create room: $e');
    }
  }
  
  Future<GameRoom> joinRoom(String roomId) async {
    try {
      final response = await _api.joinGameRoom(roomId);
      final playersData = response['players'] as List;
      
      final room = GameRoom(
        id: roomId,
        players: playersData.map((p) => GamePlayer(
          id: p['id'],
          name: p['name'],
          avatar: p['avatar'],
        )).toList(),
        state: GameState.values.firstWhere(
          (s) => s.name == response['state'],
          orElse: () => GameState.waiting,
        ),
      );
      
      _currentRoom = room;
      _roomController?.add(room);
      
      await _initializeVoiceChat();
      return room;
    } catch (e) {
      throw Exception('Failed to join room: $e');
    }
  }
  
  Future<void> _initializeVoiceChat() async {
    try {
      // Create peer connection for group voice chat
      _peerConnection = await createPeerConnection({
        'iceServers': [
          {'urls': 'stun:stun.l.google.com:19302'},
        ]
      });
      
      // Get local audio stream
      _localStream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': false,
      });
      
      await _peerConnection!.addStream(_localStream!);
      
      _peerConnection!.onAddStream = (stream) {
        // Handle remote audio streams
        print('Remote audio stream added');
      };
      
    } catch (e) {
      print('Voice chat initialization failed: $e');
    }
  }
  
  Future<void> spinBottle() async {
    if (_currentRoom == null) return;
    
    try {
      _currentRoom!.state = GameState.spinning;
      _roomController?.add(_currentRoom!);
      
      // Simulate bottle spin with random selection
      await Future.delayed(const Duration(seconds: 3));
      
      final random = Random();
      final selectedPlayer = _currentRoom!.players[random.nextInt(_currentRoom!.players.length)];
      
      _currentRoom!.selectedPlayerId = selectedPlayer.id;
      _currentRoom!.state = GameState.questioning;
      _roomController?.add(_currentRoom!);
      
      // Send to backend
      await _api.updateGameState(_currentRoom!.id, {
        'state': 'questioning',
        'selected_player': selectedPlayer.id,
        'round': _currentRoom!.round,
      });
      
    } catch (e) {
      onError?.call('Failed to spin bottle: $e');
    }
  }
  
  Future<void> submitQuestion(String question) async {
    if (_currentRoom == null) return;
    
    try {
      _currentRoom!.currentQuestion = question;
      _currentRoom!.state = GameState.answering;
      _roomController?.add(_currentRoom!);
      
      await _api.updateGameState(_currentRoom!.id, {
        'state': 'answering',
        'question': question,
      });
      
    } catch (e) {
      onError?.call('Failed to submit question: $e');
    }
  }
  
  Future<void> nextRound() async {
    if (_currentRoom == null) return;
    
    _currentRoom!.round++;
    _currentRoom!.state = GameState.waiting;
    _currentRoom!.currentQuestion = null;
    _currentRoom!.selectedPlayerId = null;
    _roomController?.add(_currentRoom!);
    
    await _api.updateGameState(_currentRoom!.id, {
      'state': 'waiting',
      'round': _currentRoom!.round,
    });
  }
  
  Future<void> toggleMute() async {
    if (_localStream != null) {
      final audioTrack = _localStream!.getAudioTracks().first;
      audioTrack.enabled = !audioTrack.enabled;
      
      // Update player mute status
      if (_currentRoom != null) {
        final currentUser = await _api.getCurrentUser();
        final playerIndex = _currentRoom!.players.indexWhere((p) => p.id == currentUser.id);
        if (playerIndex != -1) {
          _currentRoom!.players[playerIndex].isMuted = !audioTrack.enabled;
          _roomController?.add(_currentRoom!);
        }
      }
    }
  }
  
  Future<void> leaveRoom() async {
    try {
      if (_currentRoom != null) {
        await _api.leaveGameRoom(_currentRoom!.id);
      }
      
      // Clean up voice chat
      if (_localStream != null) {
        _localStream!.getTracks().forEach((track) => track.stop());
        _localStream = null;
      }
      
      if (_peerConnection != null) {
        await _peerConnection!.close();
        _peerConnection = null;
      }
      
      _currentRoom = null;
      _remoteStreams.clear();
      
    } catch (e) {
      print('Error leaving room: $e');
    }
  }
  
  void dispose() {
    _roomController?.close();
    leaveRoom();
  }
  
  bool get isVoiceChatActive => _localStream != null;
  bool get isMuted => _localStream?.getAudioTracks().first.enabled == false;
}