class EmergencyContact {
  final String id;
  final String name;
  final String phoneNumber;
  final EmergencyContactType type;
  final bool isEnabled;

  const EmergencyContact({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.type,
    this.isEnabled = true,
  });

  EmergencyContact copyWith({
    String? id,
    String? name,
    String? phoneNumber,
    EmergencyContactType? type,
    bool? isEnabled,
  }) {
    return EmergencyContact(
      id: id ?? this.id,
      name: name ?? this.name,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      type: type ?? this.type,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'type': type.name,
      'isEnabled': isEnabled,
    };
  }

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      id: json['id'],
      name: json['name'],
      phoneNumber: json['phoneNumber'],
      type: EmergencyContactType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => EmergencyContactType.personal,
      ),
      isEnabled: json['isEnabled'] ?? true,
    );
  }

  String get displayName {
    switch (type) {
      case EmergencyContactType.police:
        return '🚔 $name';
      case EmergencyContactType.ambulance:
        return '🚑 $name';
      case EmergencyContactType.family:
        return '👨‍👩‍👧‍👦 $name';
      case EmergencyContactType.friend:
        return '👥 $name';
      case EmergencyContactType.personal:
        return '📞 $name';
    }
  }
}

enum EmergencyContactType {
  police,
  ambulance,
  family,
  friend,
  personal,
}

// Default emergency contacts
class DefaultEmergencyContacts {
  static List<EmergencyContact> getDefaults() {
    return [
      const EmergencyContact(
        id: 'police',
        name: 'Police',
        phoneNumber: '100',
        type: EmergencyContactType.police,
      ),
      const EmergencyContact(
        id: 'ambulance',
        name: 'Ambulance',
        phoneNumber: '108',
        type: EmergencyContactType.ambulance,
      ),
    ];
  }
}