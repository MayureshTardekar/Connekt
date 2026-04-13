class FriendRequest {
  final String id;
  final String name;
  final String mutualText;
  final DateTime createdAt;

  const FriendRequest({
    required this.id,
    required this.name,
    required this.mutualText,
    required this.createdAt,
  });

  factory FriendRequest.fromJson(Map<String, dynamic> json) {
    return FriendRequest(
      id: json['id']?.toString() ?? '',
      name: (json['name'] ?? json['requester_name'])?.toString() ?? 'Unknown',
      mutualText: (json['mutual_text'] ?? json['mutualText'])?.toString() ?? '0 mutual friends',
      createdAt: (json['created_at'] ?? json['createdAt']) != null
          ? DateTime.parse((json['created_at'] ?? json['createdAt']).toString())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'mutual_text': mutualText,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
