import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import 'truth_dare_room_page.dart';

class GameLobbyPage extends StatefulWidget {
  const GameLobbyPage({super.key});

  @override
  State<GameLobbyPage> createState() => _GameLobbyPageState();
}

class _GameLobbyPageState extends State<GameLobbyPage> {
  final TextEditingController _roomIdController = TextEditingController();
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AmoraTheme.backgroundGradient),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Header
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios, color: AmoraTheme.deepMidnight),
                    ),
                    const Expanded(
                      child: Text(
                        'Game Lobby',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AmoraTheme.deepMidnight),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
                
                const SizedBox(height: 40),
                
                // Game selection
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Truth or Dare Game Card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: AmoraTheme.glassmorphism(color: Colors.white, borderRadius: 20),
                        child: Column(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                gradient: AmoraTheme.primaryGradient,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.psychology, color: Colors.white, size: 40),
                            ),
                            
                            const SizedBox(height: 16),
                            
                            const Text(
                              'Truth or Dare',
                              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AmoraTheme.deepMidnight),
                            ),
                            
                            const SizedBox(height: 8),
                            
                            Text(
                              'Spin the bottle and ask questions!\nPerfect for couples and friends.',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 16, color: AmoraTheme.deepMidnight.withOpacity(0.7)),
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Features
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildFeature(Icons.people, '2-4 Players'),
                                _buildFeature(Icons.mic, 'Voice Chat'),
                                _buildFeature(Icons.favorite, 'Love Theme'),
                              ],
                            ),
                          ],
                        ),
                      ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.3, end: 0),
                      
                      const SizedBox(height: 32),
                      
                      // Action buttons
                      Column(
                        children: [
                          // Create Room
                          SizedBox(
                            width: double.infinity,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: AmoraTheme.primaryGradient,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: TextButton(
                                onPressed: _createRoom,
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                ),
                                child: const Text(
                                  'Create New Room',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ).animate(delay: 200.ms).fadeIn(duration: 600.ms).slideX(begin: -0.3, end: 0),
                          
                          const SizedBox(height: 16),
                          
                          // Join Room
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(color: AmoraTheme.sunsetRose, width: 2),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: TextButton(
                              onPressed: _showJoinRoomDialog,
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: const Text(
                                'Join Existing Room',
                                style: TextStyle(
                                  color: AmoraTheme.sunsetRose,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ).animate(delay: 400.ms).fadeIn(duration: 600.ms).slideX(begin: 0.3, end: 0),
                        ],
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Instructions
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AmoraTheme.sunsetRose.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.info_outline, color: AmoraTheme.sunsetRose),
                                SizedBox(width: 8),
                                Text(
                                  'How to Play',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: AmoraTheme.deepMidnight),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '1. Create or join a room with friends\n'
                              '2. Enable voice chat for better experience\n'
                              '3. Spin the bottle to select a player\n'
                              '4. Selected player asks a question\n'
                              '5. Everyone answers and has fun!',
                              style: TextStyle(fontSize: 14, color: AmoraTheme.deepMidnight.withOpacity(0.8)),
                            ),
                          ],
                        ),
                      ).animate(delay: 600.ms).fadeIn(duration: 600.ms).slideY(begin: 0.3, end: 0),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildFeature(IconData icon, String text) {
    return Column(
      children: [
        Icon(icon, color: AmoraTheme.sunsetRose, size: 24),
        const SizedBox(height: 4),
        Text(
          text,
          style: const TextStyle(fontSize: 12, color: AmoraTheme.deepMidnight, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
  
  void _createRoom() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const TruthDareRoomPage(),
      ),
    );
  }
  
  void _showJoinRoomDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: AmoraTheme.glassmorphism(color: Colors.white, borderRadius: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Join Room',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AmoraTheme.deepMidnight),
              ),
              
              const SizedBox(height: 16),
              
              TextField(
                controller: _roomIdController,
                decoration: const InputDecoration(
                  labelText: 'Room ID',
                  hintText: 'Enter room ID',
                  border: OutlineInputBorder(),
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              
              const SizedBox(height: 24),
              
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel', style: TextStyle(color: AmoraTheme.deepMidnight)),
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: AmoraTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: TextButton(
                        onPressed: _joinRoom,
                        child: const Text('Join', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _joinRoom() {
    if (_roomIdController.text.trim().isEmpty) return;
    
    Navigator.pop(context);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TruthDareRoomPage(roomId: _roomIdController.text.trim()),
      ),
    );
  }
  
  @override
  void dispose() {
    _roomIdController.dispose();
    super.dispose();
  }
}