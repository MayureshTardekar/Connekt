import 'dart:convert';

class CampusEvent {
  final String id;
  final String title;
  final String description;
  final String location;
  final DateTime dateTime;
  final String organizer;
  final String organizerId;
  final String category;
  final String? imageUrl;
  final int attendees;

  CampusEvent({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.dateTime,
    required this.organizer,
    required this.organizerId,
    required this.category,
    this.imageUrl,
    this.attendees = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'location': location,
      'date_time': dateTime.toIso8601String(),
      'organizer': organizer,
      'organizer_id': organizerId,
      'category': category,
      'image_url': imageUrl,
      'attendees': attendees,
    };
  }

  factory CampusEvent.fromMap(Map<String, dynamic> map) {
    return CampusEvent(
      id: map['id']?.toString() ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      location: map['location'] ?? 'Campus',
      dateTime: DateTime.parse(map['date_time']),
      organizer: map['organizer_name'] ?? map['organizer'] ?? 'Unknown',
      organizerId: map['organizer_id'] ?? '',
      category: map['category'] ?? 'General',
      imageUrl: map['image_url'],
      attendees: map['attendees'] ?? 0,
    );
  }

  String toJson() => json.encode(toMap());

  factory CampusEvent.fromJson(String source) =>
      CampusEvent.fromMap(json.decode(source));
}
