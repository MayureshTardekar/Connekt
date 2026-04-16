import 'dart:convert';

class AcademicNote {
  final String id;
  final String title;
  final String description;
  final String author;
  final String? authorId;
  final String category;
  final DateTime createdAt;
  final String? fileUrl;
  final String? authorAvatar;

  AcademicNote({
    required this.id,
    required this.title,
    required this.description,
    required this.author,
    this.authorId,
    required this.category,
    required this.createdAt,
    this.fileUrl,
    this.authorAvatar,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'author': author,
      'author_id': authorId,
      'category': category,
      'created_at': createdAt.toIso8601String(),
      'file_url': fileUrl,
    };
  }

  factory AcademicNote.fromMap(Map<String, dynamic> map) {
    return AcademicNote(
      id: map['id']?.toString() ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      author: map['author_name'] ?? map['author'] ?? 'Anonymous',
      authorId: map['author_id']?.toString(),
      category: map['category'] ?? 'General',
      createdAt: DateTime.parse(map['created_at']),
      fileUrl: map['file_url'],
      authorAvatar: map['author_avatar'],
    );
  }

  AcademicNote copyWith({
    String? title,
    String? description,
    String? category,
  }) {
    return AcademicNote(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      author: author,
      authorId: authorId,
      category: category ?? this.category,
      createdAt: createdAt,
      fileUrl: fileUrl,
      authorAvatar: authorAvatar,
    );
  }
}
