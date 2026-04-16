import 'dart:convert';

class GhostPost {
  final String id;
  final String text;
  final String? authorId;
  final String? authorAlias;
  final String mood;
  final DateTime createdAt;
  final int likes;

  GhostPost({
    required this.id,
    required this.text,
    this.authorId,
    this.authorAlias,
    this.mood = 'Neutral',
    required this.createdAt,
    this.likes = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'content': text,
      'author_id': authorId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory GhostPost.fromMap(Map<String, dynamic> map) {
    return GhostPost(
      id: map['id']?.toString() ?? '',
      text: map['content'] ?? map['text'] ?? '',
      authorId: map['user_id']?.toString() ?? map['author_id']?.toString(),
      authorAlias: map['author_alias'] ?? map['profiles']?['ghost_alias'],
      mood: map['mood'] ?? 'Neutral',
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at']).toLocal()
          : DateTime.now(),
      likes: map['likes'] ?? 0,
    );
  }

  String toJson() => json.encode(toMap());

  factory GhostPost.fromJson(String source) =>
      GhostPost.fromMap(json.decode(source));
}
