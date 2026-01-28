import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/game_room_service.dart';
import '../widgets/bottle_widget.dart';

class TruthDareRoomPage extends StatefulWidget {
  final String? roomId;
  
  const TruthDareRoomPage({super.key, this.roomId});

  @override
  State<TruthDareRoomPage> createState() => _TruthDareRoomPageState();
}

class _TruthDareRoomPageState extends State<TruthDareRoomPage> {
  final GameRoomService _gameService = GameRoomService.instance;
  final TextEditingController _questionController = TextEditingController();
  
  GameRoom? _room;
  bool _isSpinning = false;
  int _selectedPlayerIndex = 0;
  
  @override
  void initState() {
    super.initState();
    _initializeRoom();
  }
  
  Future<void> _initializeRoom() async {
    await _gameService.initialize();
    
    _gameService.onRoomUpdate = (room) {
      if (mounted) {
        setState(() => _room = room);
      }
    };
    
    _gameService.onError = (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
      }
    };
    
    try {
      if (widget.roomId != null) {
        _room = await _gameService.joinRoom(widget.roomId!);
      } else {
        _room = await _gameService.createRoom();
      }
      setState(() {});
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to initialize room: $e')),
      );
    }
  }
  
  Future<void> _spinBottle() async {
    if (_room == null || _isSpinning || _room!.players.length < 2) return;
    
    setState(() => _isSpinning = true);
    
    try {
      // Update room state to spinning
      _room!.state = GameState.spinning;
      setState(() {});
      
      // Select random player
      final random = Random();
      _selectedPlayerIndex = random.nextInt(_room!.players.length);
      final selectedPlayer = _room!.players[_selectedPlayerIndex];
      
      // Wait for animation to complete (3 seconds)
      await Future.delayed(const Duration(seconds: 3));
      
      // Update room state
      _room!.selectedPlayerId = selectedPlayer.id;
      _room!.state = GameState.questioning;
      
      setState(() => _isSpinning = false);
      
      // Send to backend
      await _gameService.updateGameState({
        'state': 'questioning',
        'selected_player': selectedPlayer.id,
        'round': _room!.round,
      });
      
    } catch (e) {
      setState(() => _isSpinning = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to spin bottle: $e')),
      );
    }
  }
  
  void _onSpinComplete() {
    setState(() => _isSpinning = false);
  }
  
  Future<void> _submitQuestion() async {
    if (_questionController.text.trim().isEmpty) return;
    
    await _gameService.submitQuestion(_questionController.text.trim());
    _questionController.clear();
  }
  
  Future<void> _nextRound() async {
    await _gameService.nextRound();
  }
  
  @override
  Widget build(BuildContext context) {
    if (_room == null) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: AmoraTheme.backgroundGradient),
          child: const Center(
            child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(AmoraTheme.sunsetRose)),
          ),
        ),
      );
    }
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AmoraTheme.backgroundGradient),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildHeader(),
              
              // Game Area
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Players Circle
                      SizedBox(height: 300, child: _buildPlayersCircle()),
                      
                      // Game Status
                      _buildGameStatus(),
                      
                      // Controls
                      _buildControls(),
                      
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              _gameService.leaveRoom();
              Navigator.pop(context);
            },
            icon: const Icon(Icons.arrow_back_ios, color: AmoraTheme.deepMidnight),
          ),
          Expanded(
            child: Column(
              children: [
                const Text(
                  'Truth or Dare',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AmoraTheme.deepMidnight),
                ),
                Text(
                  'Room: ${_room!.id}',
                  style: TextStyle(fontSize: 12, color: AmoraTheme.deepMidnight.withOpacity(0.7)),
                ),
              ],
            ),
          ),
          // Voice controls
          Row(
            children: [
              IconButton(
                onPressed: _gameService.toggleMute,
                icon: Icon(
                  _gameService.isMuted ? Icons.mic_off : Icons.mic,
                  color: _gameService.isMuted ? Colors.red : AmoraTheme.sunsetRose,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _gameService.isVoiceChatActive ? Colors.green : Colors.grey,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _gameService.isVoiceChatActive ? 'LIVE' : 'OFF',
                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildPlayersCircle() {
    return Stack(
      children: [
        // Players positioned in circle
        ..._room!.players.asMap().entries.map((entry) {
          final index = entry.key;
          final player = entry.value;
          final angle = (index * 2 * pi) / _room!.players.length;
          final radius = 120.0;
          
          final x = radius * cos(angle - pi / 2);
          final y = radius * sin(angle - pi / 2);
          
          return Positioned(
            left: MediaQuery.of(context).size.width / 2 + x - 30,
            top: 150 + y - 30,
            child: _buildPlayerAvatar(player, index == _selectedPlayerIndex && _room!.selectedPlayerId == player.id),
          );
        }).toList(),
        
        // Bottle in center
        Positioned(
          left: MediaQuery.of(context).size.width / 2 - 60,
          top: 150 - 60,
          child: SpinBottleWidget(
            isSpinning: _isSpinning,
            selectedPlayerIndex: _selectedPlayerIndex,
            onSpinComplete: _onSpinComplete,
          ),
        ),
      ],
    );
  }
  
  Widget _buildPlayerAvatar(GamePlayer player, bool isSelected) {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: isSelected ? AmoraTheme.sunsetRose : Colors.transparent,
          width: 3,
        ),
        boxShadow: isSelected ? [
          BoxShadow(
            color: AmoraTheme.sunsetRose.withOpacity(0.5),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ] : null,
      ),
      child: Stack(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: AmoraTheme.sunsetRose,
            backgroundImage: player.avatar != null ? NetworkImage(player.avatar!) : null,
            child: player.avatar == null ? Text(
              player.name[0].toUpperCase(),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20),
            ) : null,
          ),
          
          // Connection status
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: player.isConnected ? Colors.green : Colors.red,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
          
          // Mute status
          if (player.isMuted)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 16,
                height: 16,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.mic_off, color: Colors.white, size: 10),
              ),
            ),
        ],
      ),
    ).animate(target: isSelected ? 1 : 0)
      .scale(duration: 300.ms, curve: Curves.easeOut);
  }
  
  Widget _buildGameStatus() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: AmoraTheme.glassmorphism(color: Colors.white, borderRadius: 16),
      child: Column(
        children: [
          Text(
            'Round ${_room!.round}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AmoraTheme.deepMidnight),
          ),
          const SizedBox(height: 8),
          
          if (_room!.state == GameState.waiting)
            const Text('Tap the bottle to spin!', style: TextStyle(color: AmoraTheme.deepMidnight))
          else if (_room!.state == GameState.spinning)
            const Text('Spinning...', style: TextStyle(color: AmoraTheme.sunsetRose, fontWeight: FontWeight.bold))
          else if (_room!.state == GameState.questioning)
            Column(
              children: [
                Text(
                  '${_getSelectedPlayerName()} asks a question:',
                  style: const TextStyle(fontWeight: FontWeight.w600, color: AmoraTheme.deepMidnight),
                ),
                const SizedBox(height: 8),
                if (_isCurrentUserSelected())
                  TextField(
                    controller: _questionController,
                    decoration: const InputDecoration(
                      hintText: 'Type your question...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _submitQuestion(),
                  )
                else
                  const Text('Waiting for question...', style: TextStyle(color: Colors.grey)),
              ],
            )
          else if (_room!.state == GameState.answering)
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AmoraTheme.sunsetRose.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _room!.currentQuestion ?? '',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AmoraTheme.deepMidnight),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 8),
                const Text('Everyone answer using voice chat!', style: TextStyle(color: AmoraTheme.sunsetRose)),
              ],
            ),
        ],
      ),
    );
  }
  
  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          if (_room!.state == GameState.waiting)
            Container(
              decoration: BoxDecoration(gradient: AmoraTheme.primaryGradient, borderRadius: BorderRadius.circular(12)),
              child: TextButton(
                onPressed: _room!.players.length >= 2 ? _spinBottle : null,
                child: Text(
                  'Spin Bottle',
                  style: TextStyle(
                    color: _room!.players.length >= 2 ? Colors.white : Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            )
          else if (_room!.state == GameState.questioning && _isCurrentUserSelected())
            Container(
              decoration: BoxDecoration(gradient: AmoraTheme.primaryGradient, borderRadius: BorderRadius.circular(12)),
              child: TextButton(
                onPressed: _submitQuestion,
                child: const Text('Ask Question', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            )
          else if (_room!.state == GameState.answering)
            Container(
              decoration: BoxDecoration(gradient: AmoraTheme.primaryGradient, borderRadius: BorderRadius.circular(12)),
              child: TextButton(
                onPressed: _nextRound,
                child: const Text('Next Round', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
        ],
      ),
    );
  }
  
  String _getSelectedPlayerName() {
    if (_room!.selectedPlayerId == null) return '';
    final player = _room!.players.firstWhere((p) => p.id == _room!.selectedPlayerId);
    return player.name;
  }
  
  bool _isCurrentUserSelected() {
    // This would check if current user is the selected player
    // For now, return true for demo
    return true;
  }
  
  @override
  void dispose() {
    _questionController.dispose();
    _gameService.dispose();
    super.dispose();
  }
}