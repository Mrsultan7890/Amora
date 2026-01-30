import 'dart:async';
import 'dart:math';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'api_service.dart';
import 'websocket_service.dart';

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
    try {
      _roomController = StreamController<GameRoom>.broadcast();
      print('✅ Game room service initialized');
    } catch (e) {
      print('❌ Game room service initialization failed: $e');
    }
  }
  
  Future<GameRoom> createRoom() async {
    try {
      final response = await _api.createGameRoom();
      final room = GameRoom(
        id: response['room_id'],
        players: [GamePlayer(id: 'current_user', name: 'You')],
      );
      
      _currentRoom = room;
      _roomController?.add(room);
      
      print('✅ Game room created: ${room.id}');
      return room;
    } catch (e) {
      print('❌ Failed to create room: $e');
      // Fallback to mock room if API fails
      final roomId = 'room_${DateTime.now().millisecondsSinceEpoch}';
      final room = GameRoom(
        id: roomId,
        players: [GamePlayer(id: 'user1', name: 'You')],
      );
      
      _currentRoom = room;
      _roomController?.add(room);
      
      print('✅ Mock game room created: $roomId');
      return room;
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
      
      print('✅ Joined game room: $roomId');
      return room;
    } catch (e) {
      print('❌ Failed to join room: $e');
      // Fallback to mock room
      final room = GameRoom(
        id: roomId,
        players: [
          GamePlayer(id: 'user1', name: 'You'),
          GamePlayer(id: 'user2', name: 'Player 2'),
        ],
        state: GameState.waiting,
      );
      
      _currentRoom = room;
      _roomController?.add(room);
      
      print('✅ Joined mock game room: $roomId');
      return room;
    }
  }
  
  Future<void> _initializeVoiceChat() async {
    try {
      print('🎤 Voice chat disabled for demo mode');
      // Skip voice chat initialization to prevent crashes
    } catch (e) {
      print('❌ Voice chat initialization failed: $e');
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
      
      // Skip backend update for demo
      print('Game state updated locally');
      
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
      
      // Skip backend update for demo
      print('Question submitted locally');
      
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
    
    // Skip backend update for demo
    print('Next round started locally');
  }
  
  Future<void> toggleMute() async {
    // Mock mute toggle for demo
    if (_currentRoom != null && _currentRoom!.players.isNotEmpty) {
      _currentRoom!.players[0].isMuted = !_currentRoom!.players[0].isMuted;
      _roomController?.add(_currentRoom!);
      print('🎤 Voice ${_currentRoom!.players[0].isMuted ? "muted" : "unmuted"}');
    }
  }
  
  void _sendVoiceChatSignal(Map<String, dynamic> signal) {
    if (_currentRoom == null) return;
    
    final wsService = WebSocketService.instance;
    if (wsService.isConnected) {
      wsService.sendMessage({
        'type': 'voice_chat_signal',
        'room_id': _currentRoom!.id,
        'data': signal,
      });
    }
  }
  
  void _handleVoiceChatSignal(Map<String, dynamic> data) {
    final signalType = data['type'];
    
    switch (signalType) {
      case 'ice-candidate':
        final candidate = RTCIceCandidate(
          data['candidate']['candidate'],
          data['candidate']['sdpMid'],
          data['candidate']['sdpMLineIndex'],
        );
        _peerConnection?.addCandidate(candidate);
        break;
        
      case 'mute-status':
        final playerId = data['player_id'];
        final isMuted = data['is_muted'];
        
        // Update player mute status in UI
        if (_currentRoom != null) {
          final playerIndex = _currentRoom!.players.indexWhere((p) => p.id == playerId);
          if (playerIndex != -1) {
            _currentRoom!.players[playerIndex].isMuted = isMuted;
            _roomController?.add(_currentRoom!);
          }
        }
        break;
    }
  }
  
  Future<void> leaveRoom() async {
    try {
      _currentRoom = null;
      _remoteStreams.clear();
      print('Left game room');
    } catch (e) {
      print('Error leaving room: $e');
    }
  }
  
  void dispose() {
    _roomController?.close();
    leaveRoom();
  }
  
  Future<void> updateGameState(Map<String, dynamic> stateData) async {
    if (_currentRoom == null) return;
    
    try {
      // Send via WebSocket for real-time updates
      final wsService = WebSocketService.instance;
      if (wsService.isConnected) {
        wsService.sendMessage({
          'type': 'game_update',
          'room_id': _currentRoom!.id,
          'data': stateData,
        });
      }
      
      // Skip backend save for demo
      print('Game state updated via WebSocket');
    } catch (e) {
      onError?.call('Failed to update game state: $e');
    }
  }
  
  void _handleGameUpdate(Map<String, dynamic> data) {
    if (_currentRoom == null) return;
    
    try {
      // Update local room state
      if (data['state'] != null) {
        _currentRoom!.state = GameState.values.firstWhere(
          (s) => s.name == data['state'],
          orElse: () => _currentRoom!.state,
        );
      }
      
      if (data['selected_player'] != null) {
        _currentRoom!.selectedPlayerId = data['selected_player'];
      }
      
      if (data['question'] != null) {
        _currentRoom!.currentQuestion = data['question'];
      }
      
      if (data['round'] != null) {
        _currentRoom!.round = data['round'];
      }
      
      // Notify listeners
      _roomController?.add(_currentRoom!);
      onRoomUpdate?.call(_currentRoom!);
    } catch (e) {
      print('Error handling game update: $e');
    }
  }
  
  bool get isVoiceChatActive => _localStream != null;
  bool get isMuted => _localStream?.getAudioTracks().first.enabled == false;
}