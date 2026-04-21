import 'dart:convert';

import 'package:flutter/foundation.dart';

class GhostPost {
  final String id;
  final String text;
  final String? authorId;
  final String? authorAlias;
  final String mood;
  final DateTime createdAt;
  final int likes;
  
  // Phase 2 Expressive features
  final String? audioUrl;
  final String? imageUrl;
  final String? replyToId;
  final String? replyToText;
  final String? replyToName;
  final Map<String, List<String>> reactions;

  GhostPost({
    required this.id,
    required this.text,
    this.authorId,
    this.authorAlias,
    this.mood = 'Neutral',
    required this.createdAt,
    this.likes = 0,
    this.audioUrl,
    this.imageUrl,
    this.replyToId,
    this.replyToText,
    this.replyToName,
    this.reactions = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'content': text,
      'author_id': authorId,
      'created_at': createdAt.toIso8601String(),
      'audio_url': audioUrl,
      'image_url': imageUrl,
      'reply_to_id': replyToId,
      'reply_to_text': replyToText,
      'reply_to_name': replyToName,
      'reactions': reactions,
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
      audioUrl: map['audio_url'],
      imageUrl: map['image_url'],
      replyToId: map['reply_to_id'],
      replyToText: map['reply_to_text'],
      replyToName: map['reply_to_name'],
      reactions: (map['reactions'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, (e as List).map((id) => id.toString()).toList()),
          ) ??
          {},
    );
  }

  String toJson() => json.encode(toMap());

  factory GhostPost.fromJson(String source) =>
      GhostPost.fromMap(json.decode(source));

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is GhostPost &&
        id == other.id &&
        text == other.text &&
        authorId == other.authorId &&
        authorAlias == other.authorAlias &&
        mood == other.mood &&
        createdAt == other.createdAt &&
        likes == other.likes &&
        audioUrl == other.audioUrl &&
        imageUrl == other.imageUrl &&
        replyToId == other.replyToId &&
        replyToText == other.replyToText &&
        replyToName == other.replyToName &&
        _reactionsMapEquals(reactions, other.reactions);
  }

  @override
  int get hashCode => Object.hash(
        id,
        text,
        authorId,
        authorAlias,
        mood,
        createdAt,
        likes,
        audioUrl,
        imageUrl,
        replyToId,
        replyToText,
        replyToName,
        Object.hashAll(
          reactions.entries.map((e) => Object.hash(e.key, Object.hashAll(e.value))),
        ),
      );
}

bool _reactionsMapEquals(
  Map<String, List<String>> a,
  Map<String, List<String>> b,
) {
  if (a.length != b.length) return false;
  for (final e in a.entries) {
    if (!listEquals(e.value, b[e.key])) return false;
  }
  return true;
}
