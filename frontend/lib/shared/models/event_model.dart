class EventModel {
  final String id;
  final String title;
  final String description;
  final String location;
  final double latitude;
  final double longitude;
  final DateTime dateTime;
  final String category;
  final int maxAttendees;
  final int currentAttendees;
  final double price;
  final String imageUrl;
  final String organizerId;
  final String organizerName;
  final List<String> attendeeIds;
  final bool isJoined;
  final double distanceKm;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.latitude,
    required this.longitude,
    required this.dateTime,
    required this.category,
    required this.maxAttendees,
    required this.currentAttendees,
    required this.price,
    required this.imageUrl,
    required this.organizerId,
    required this.organizerName,
    required this.attendeeIds,
    required this.isJoined,
    required this.distanceKm,
  });

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      location: json['location'],
      latitude: json['latitude'].toDouble(),
      longitude: json['longitude'].toDouble(),
      dateTime: DateTime.parse(json['date_time']),
      category: json['category'],
      maxAttendees: json['max_attendees'],
      currentAttendees: json['current_attendees'],
      price: json['price'].toDouble(),
      imageUrl: json['image_url'] ?? '',
      organizerId: json['organizer_id'],
      organizerName: json['organizer_name'],
      attendeeIds: List<String>.from(json['attendee_ids'] ?? []),
      isJoined: json['is_joined'] ?? false,
      distanceKm: json['distance_km'].toDouble(),
    );
  }
}