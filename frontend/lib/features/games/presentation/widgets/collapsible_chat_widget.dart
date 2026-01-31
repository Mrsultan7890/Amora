import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/game_room_service.dart';

class CollapsibleChatWidget extends StatefulWidget {
  final GameRoomService gameService;
  final bool isExpanded;
  final VoidCallback onToggle;

  const CollapsibleChatWidget({
    Key? key,
    required this.gameService,
    required this.isExpanded,
    required this.onToggle,
  }) : super(key: key);

  @override
  State<CollapsibleChatWidget> createState() => _CollapsibleChatWidgetState();
}

class _CollapsibleChatWidgetState extends State<CollapsibleChatWidget> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: widget.isExpanded ? 300 : 60,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          children: [
            // Chat Header
            GestureDetector(
              onTap: widget.onToggle,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(
                      Icons.chat_bubble,
                      color: AmoraTheme.sunsetRose,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Game Chat',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AmoraTheme.deepMidnight,
                      ),
                    ),
                    const Spacer(),
                    StreamBuilder<GameRoom>(
                      stream: widget.gameService.roomStream,
                      builder: (context, snapshot) {
                        final unreadCount = widget.gameService.chatMessages.length;
                        return unreadCount > 0
                            ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AmoraTheme.sunsetRose,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$unreadCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              )
                            : const SizedBox();
                      },
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      widget.isExpanded ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_up,
                      color: AmoraTheme.deepMidnight,
                    ),
                  ],
                ),
              ),
            ),

            // Chat Content (only visible when expanded)
            if (widget.isExpanded) ...[
              const Divider(height: 1),
              
              // Messages List
              Expanded(
                child: StreamBuilder<GameRoom>(
                  stream: widget.gameService.roomStream,
                  builder: (context, snapshot) {
                    final messages = widget.gameService.chatMessages;
                    
                    if (messages.isEmpty) {
                      return const Center(
                        child: Text(
                          'No messages yet. Start chatting!',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 14,
                          ),
                        ),
                      );
                    }
                    
                    return ListView.builder(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(8),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final message = messages[index];
                        final isMe = message.playerId == 'current_user';
                        
                        return Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                            children: [
                              if (!isMe) ...[
                                CircleAvatar(
                                  radius: 12,
                                  backgroundColor: AmoraTheme.sunsetRose,
                                  child: Text(
                                    message.playerName[0].toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              
                              Flexible(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isMe ? AmoraTheme.sunsetRose : Colors.grey[200],
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: message.isReaction
                                      ? Text(
                                          message.message,
                                          style: const TextStyle(fontSize: 20),
                                        )
                                      : Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            if (!isMe)
                                              Text(
                                                message.playerName,
                                                style: TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.grey[600],
                                                ),
                                              ),
                                            Text(
                                              message.message,
                                              style: TextStyle(
                                                color: isMe ? Colors.white : AmoraTheme.deepMidnight,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                              
                              if (isMe) ...[
                                const SizedBox(width: 8),
                                CircleAvatar(
                                  radius: 12,
                                  backgroundColor: AmoraTheme.sunsetRose,
                                  child: const Text(
                                    'Y',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              
              // Quick Reactions
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Text(
                      'Quick:',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ...['😂', '😱', '👍', '❤️', '🔥'].map((emoji) => 
                      GestureDetector(
                        onTap: () => widget.gameService.sendReaction(emoji),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(emoji, style: const TextStyle(fontSize: 16)),
                        ),
                      ),
                    ).toList(),
                  ],
                ),
              ),
              
              // Message Input
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  border: Border(top: BorderSide(color: Colors.grey[200]!)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: TextStyle(color: Colors.grey[500]),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        ),
                        onSubmitted: _sendMessage,
                        maxLines: 1,
                      ),
                    ),
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _sendMessage,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: AmoraTheme.sunsetRose,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.send,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ).animate(target: widget.isExpanded ? 1 : 0)
        .slideY(begin: 0.3, end: 0, duration: 300.ms),
    );
  }

  void _sendMessage([String? value]) {
    final message = value ?? _messageController.text.trim();
    if (message.isNotEmpty) {
      widget.gameService.sendChatMessage(message);
      _messageController.clear();
      
      // Auto scroll to bottom
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}