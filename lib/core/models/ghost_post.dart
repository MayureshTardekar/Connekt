import 'dart:convert';

class GhostPost {
  final String id;
  final String text;
  final String mood;
  final DateTime createdAt;
  final int likes;
  final int commentsCount;
  final String? colorHex;
  final String? authorId;
  final String? authorAlias;

  GhostPost({
    required this.id,
    required this.text,
    required this.mood,
    required this.createdAt,
    this.likes = 0,
    this.commentsCount = 0,
    this.colorHex,
    this.authorId,
    this.authorAlias,
  });

  Map<String, dynamic> toMap() {
    return {
      'text': text,
      'mood': mood,
      'color_hex': colorHex,
      'author_id': authorId,
      'author_alias': authorAlias,
      'created_at': createdAt.toIso8601String(),
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
      authorId: map['author_id'],
      authorAlias: map['author_alias'],
    );
  }

  String toJson() => json.encode(toMap());

  factory GhostPost.fromJson(String source) =>
      GhostPost.fromMap(json.decode(source));
}
