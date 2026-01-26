import 'package:equatable/equatable.dart';
import 'dart:convert';

class UserModel extends Equatable {
  final String id;
  final String email;
  final String name;
  final int age;
  final String gender;
  final List<String> photos;
  final String bio;
  final List<String> interests;
  final bool isVerified;
  final bool isOnline;
  final DateTime lastSeen;
  final DateTime createdAt;
  final String? job;
  final String? education;
  final int? height;
  final String? relationshipGoal;
  final List<String>? languages;
  final bool? isPrivate;
  final double? latitude;
  final double? longitude;

  const UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.age,
    required this.gender,
    required this.photos,
    required this.bio,
    required this.interests,
    required this.isVerified,
    required this.isOnline,
    required this.lastSeen,
    required this.createdAt,
    this.job,
    this.education,
    this.height,
    this.relationshipGoal,
    this.languages,
    this.isPrivate,
    this.latitude,
    this.longitude,
  });

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    int? age,
    String? gender,
    List<String>? photos,
    String? bio,
    List<String>? interests,
    bool? isVerified,
    bool? isOnline,
    DateTime? lastSeen,
    DateTime? createdAt,
    String? job,
    String? education,
    int? height,
    String? relationshipGoal,
    List<String>? languages,
    bool? isPrivate,
    double? latitude,
    double? longitude,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      photos: photos ?? this.photos,
      bio: bio ?? this.bio,
      interests: interests ?? this.interests,
      isVerified: isVerified ?? this.isVerified,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      createdAt: createdAt ?? this.createdAt,
      job: job ?? this.job,
      education: education ?? this.education,
      height: height ?? this.height,
      relationshipGoal: relationshipGoal ?? this.relationshipGoal,
      languages: languages ?? this.languages,
      isPrivate: isPrivate ?? this.isPrivate,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'age': age,
      'gender': gender,
      'photos': photos,
      'bio': bio,
      'interests': interests,
      'is_verified': isVerified,
      'is_online': isOnline,
      'last_seen': lastSeen.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
      'job': job,
      'education': education,
      'height': height,
      'relationship_goal': relationshipGoal,
      'languages': languages,
      'is_private': isPrivate,
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      age: json['age'] ?? 0,
      gender: json['gender']?.toString() ?? '',
      photos: json['photos'] is String 
          ? (json['photos'] as String).isEmpty 
              ? <String>[] 
              : List<String>.from(jsonDecode(json['photos']))
          : List<String>.from(json['photos'] ?? []),
      bio: json['bio']?.toString() ?? '',
      interests: json['interests'] != null ? List<String>.from(json['interests']) : <String>[],
      isVerified: json['is_verified'] ?? false,
      isOnline: json['is_online'] ?? false,
      lastSeen: json['last_seen'] != null ? DateTime.parse(json['last_seen']) : DateTime.now(),
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
      job: json['job']?.toString(),
      education: json['education']?.toString(),
      height: json['height'],
      relationshipGoal: json['relationship_goal']?.toString(),
      languages: json['languages'] != null ? List<String>.from(json['languages']) : null,
      isPrivate: json['is_private'],
      latitude: json['latitude']?.toDouble(),
      longitude: json['longitude']?.toDouble(),
    );
  }

  String get primaryPhoto => photos.isNotEmpty ? photos.first : '';
  
  int get photoCount => photos.length;
  
  String get ageText => '$age';
  
  String get distanceText {
    // This will be updated with real distance from API response
    return '2 km away'; // Placeholder - will be replaced by API data
  }
  
  bool get hasCompleteProfile {
    return photos.isNotEmpty && 
           bio.isNotEmpty && 
           interests.isNotEmpty &&
           job != null &&
           education != null;
  }

  @override
  List<Object?> get props => [
    id, email, name, age, gender, photos, bio, interests,
    isVerified, isOnline, lastSeen, createdAt,
    job, education, height, relationshipGoal, languages, isPrivate,
    latitude, longitude,
  ];
}