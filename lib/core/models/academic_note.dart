import 'dart:convert';

class AcademicNote {
  final String id;
  final String title;
  final String description;
  final String author;
  final String category;
  final int pages;
  final DateTime createdAt;
  final String? fileUrl;

  AcademicNote({
    required this.id,
    required this.title,
    required this.description,
    required this.author,
    required this.category,
    required this.pages,
    required this.createdAt,
    this.fileUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'author': author,
      'category': category,
      'pages': pages,
      'created_at': createdAt.toIso8601String(),
      'file_url': fileUrl,
    };
  }

  factory AcademicNote.fromMap(Map<String, dynamic> map) {
    return AcademicNote(
      id: map['id']?.toString() ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      author: map['author'] ?? 'Anonymous',
      category: map['category'] ?? 'General',
      pages: map['pages'] ?? 0,
      createdAt: DateTime.parse(map['created_at']),
      fileUrl: map['file_url'],
    );
  }

  String toJson() => json.encode(toMap());

  factory AcademicNote.fromJson(String source) =>
      AcademicNote.fromMap(json.decode(source));
}
