import 'package:equatable/equatable.dart';
import 'user_model.dart';

class MatchModel extends Equatable {
  final String id;
  final String user1Id;
  final String user2Id;
  final DateTime createdAt;
  final DateTime lastMessageAt;
  final String? lastMessage;
  final bool isActive;
  final UserModel? otherUser;

  const MatchModel({
    required this.id,
    required this.user1Id,
    required this.user2Id,
    required this.createdAt,
    required this.lastMessageAt,
    this.lastMessage,
    this.isActive = true,
    this.otherUser,
  });

  MatchModel copyWith({
    String? id,
    String? user1Id,
    String? user2Id,
    DateTime? createdAt,
    DateTime? lastMessageAt,
    String? lastMessage,
    bool? isActive,
    UserModel? otherUser,
  }) {
    return MatchModel(
      id: id ?? this.id,
      user1Id: user1Id ?? this.user1Id,
      user2Id: user2Id ?? this.user2Id,
      createdAt: createdAt ?? this.createdAt,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastMessage: lastMessage ?? this.lastMessage,
      isActive: isActive ?? this.isActive,
      otherUser: otherUser ?? this.otherUser,
    );
  }

  String getOtherUserId(String currentUserId) {
    return user1Id == currentUserId ? user2Id : user1Id;
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user1_id': user1Id,
      'user2_id': user2Id,
      'created_at': createdAt.toIso8601String(),
      'last_message_at': lastMessageAt.toIso8601String(),
      'last_message': lastMessage,
      'is_active': isActive,
      'other_user': otherUser?.toJson(),
    };
  }

  factory MatchModel.fromJson(Map<String, dynamic> json) {
    return MatchModel(
      id: json['id'],
      user1Id: json['user1_id'],
      user2Id: json['user2_id'],
      createdAt: DateTime.parse(json['created_at']),
      lastMessageAt: DateTime.parse(json['last_message_at']),
      lastMessage: json['last_message'],
      isActive: json['is_active'] ?? true,
      otherUser: json['other_user'] != null 
          ? UserModel.fromJson(json['other_user']) 
          : null,
    );
  }

  @override
  List<Object?> get props => [
    id, user1Id, user2Id, createdAt, lastMessageAt, lastMessage, isActive, otherUser,
  ];
}