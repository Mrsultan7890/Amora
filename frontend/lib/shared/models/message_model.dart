import 'package:equatable/equatable.dart';

class MessageModel extends Equatable {
  final String id;
  final String matchId;
  final String senderId;
  final String content;
  final String? imageUrl;
  final DateTime createdAt;
  final bool isRead;
  final MessageType type;
  final String senderName;

  const MessageModel({
    required this.id,
    required this.matchId,
    required this.senderId,
    required this.content,
    this.imageUrl,
    required this.createdAt,
    required this.isRead,
    this.type = MessageType.text,
    required this.senderName,
  });

  MessageModel copyWith({
    String? id,
    String? matchId,
    String? senderId,
    String? content,
    String? imageUrl,
    DateTime? createdAt,
    bool? isRead,
    MessageType? type,
    String? senderName,
  }) {
    return MessageModel(
      id: id ?? this.id,
      matchId: matchId ?? this.matchId,
      senderId: senderId ?? this.senderId,
      content: content ?? this.content,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      type: type ?? this.type,
      senderName: senderName ?? this.senderName,
    );
  }

  bool isFromCurrentUser(String currentUserId) {
    return senderId == currentUserId;
  }

  String get timeText {
    final now = DateTime.now();
    final difference = now.difference(createdAt);
    
    if (difference.inMinutes < 1) {
      return 'Now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else {
      return '${difference.inDays}d';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'match_id': matchId,
      'sender_id': senderId,
      'content': content,
      'image_url': imageUrl,
      'created_at': createdAt.toIso8601String(),
      'is_read': isRead,
      'message_type': type.name,
      'sender_name': senderName,
    };
  }

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'],
      matchId: json['match_id'],
      senderId: json['sender_id'],
      content: json['content'],
      imageUrl: json['image_url'],
      createdAt: DateTime.parse(json['created_at']),
      isRead: json['is_read'] ?? false,
      type: MessageType.values.firstWhere(
        (e) => e.name == json['message_type'],
        orElse: () => MessageType.text,
      ),
      senderName: json['sender_name'] ?? '',
    );
  }

  factory MessageModel.fromWebSocket(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] ?? DateTime.now().millisecondsSinceEpoch.toString(),
      matchId: json['match_id'],
      senderId: json['sender_id'],
      content: json['content'],
      imageUrl: json['image_url'],
      createdAt: DateTime.parse(json['timestamp']),
      isRead: false,
      type: MessageType.values.firstWhere(
        (e) => e.name == json['message_type'],
        orElse: () => MessageType.text,
      ),
      senderName: json['sender_name'] ?? '',
    );
  }

  @override
  List<Object?> get props => [
    id, matchId, senderId, content, imageUrl, createdAt, isRead, type, senderName,
  ];
}

enum MessageType {
  text,
  image,
  gif,
  system,
  emergency,
}