import 'dart:convert';

class GhostPost {
  final String id;
  final String text;
  final String mood;
  final DateTime createdAt;
  final int likes;
  final int commentsCount;
  final String? colorHex;

  GhostPost({
    required this.id,
    required this.text,
    required this.mood,
    required this.createdAt,
    this.likes = 0,
    this.commentsCount = 0,
    this.colorHex,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'text': text,
      'mood': mood,
      'created_at': createdAt.toIso8601String(),
      'likes': likes,
      'comments_count': commentsCount,
      'color_hex': colorHex,
    };
  }

  factory GhostPost.fromMap(Map<String, dynamic> map) {
    return GhostPost(
      id: map['id']?.toString() ?? '',
      text: map['text'] ?? '',
      mood: map['mood'] ?? 'Unknown',
      createdAt: DateTime.parse(map['created_at']),
      likes: map['likes'] ?? 0,
      commentsCount: map['comments_count'] ?? 0,
      colorHex: map['color_hex'],
    );
  }

  String toJson() => json.encode(toMap());

  factory GhostPost.fromJson(String source) => GhostPost.fromMap(json.decode(source));
}
