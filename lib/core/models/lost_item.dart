import 'dart:convert';

class LostItem {
  final String id;
  final String title;
  final String description;
  final String location;
  final DateTime createdAt;
  final String type; // 'lost' or 'found'
  final String contactInfo;
  final String? imageUrl;
  final bool isResolved;
  final String? postedBy;

  LostItem({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.createdAt,
    required this.type,
    required this.contactInfo,
    this.imageUrl,
    this.isResolved = false,
    this.postedBy,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'location': location,
      'created_at': createdAt.toUtc().toIso8601String(),
      'type': type,
      'contact_info': contactInfo,
      'image_url': imageUrl,
      'is_resolved': isResolved,
      'posted_by': postedBy,
    };
  }

  factory LostItem.fromMap(Map<String, dynamic> map) {
    return LostItem(
      id: map['id']?.toString() ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      location: map['location'] ?? 'Campus',
      createdAt: DateTime.parse(map['created_at']).toUtc(),
      type: map['type'] ?? 'lost',
      contactInfo: map['contact_info'] ?? '',
      imageUrl: map['image_url'],
      isResolved: map['is_resolved'] ?? false,
      postedBy: map['posted_by'],
    );
  }

  String toJson() => json.encode(toMap());

  factory LostItem.fromJson(String source) =>
      LostItem.fromMap(json.decode(source));
}
