import 'package:equatable/equatable.dart';

class SwipeModel extends Equatable {
  final String id;
  final String swiperId;
  final String swipedId;
  final bool isLike;
  final DateTime createdAt;
  final SwipeType type;

  const SwipeModel({
    required this.id,
    required this.swiperId,
    required this.swipedId,
    required this.isLike,
    required this.createdAt,
    this.type = SwipeType.normal,
  });

  SwipeModel copyWith({
    String? id,
    String? swiperId,
    String? swipedId,
    bool? isLike,
    DateTime? createdAt,
    SwipeType? type,
  }) {
    return SwipeModel(
      id: id ?? this.id,
      swiperId: swiperId ?? this.swiperId,
      swipedId: swipedId ?? this.swipedId,
      isLike: isLike ?? this.isLike,
      createdAt: createdAt ?? this.createdAt,
      type: type ?? this.type,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'swiper_id': swiperId,
      'swiped_id': swipedId,
      'is_like': isLike,
      'created_at': createdAt.toIso8601String(),
      'type': type.name,
    };
  }

  factory SwipeModel.fromJson(Map<String, dynamic> json) {
    return SwipeModel(
      id: json['id'],
      swiperId: json['swiper_id'],
      swipedId: json['swiped_id'],
      isLike: json['is_like'],
      createdAt: DateTime.parse(json['created_at']),
      type: SwipeType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => SwipeType.normal,
      ),
    );
  }

  @override
  List<Object?> get props => [
    id, swiperId, swipedId, isLike, createdAt, type,
  ];
}

enum SwipeType {
  normal,
  superLike,
  boost,
}