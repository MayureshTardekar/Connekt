import 'dart:convert';

class FriendRequest {
  final String id;
  final String senderId;
  final String senderName;
  final String receiverId;
  final String status; // 'pending', 'accepted', 'declined'
  final DateTime createdAt;
  final int mutualCount;

  FriendRequest({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.receiverId,
    required this.status,
    required this.createdAt,
    this.mutualCount = 0,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'sender_id': senderId,
    'sender_name': senderName,
    'receiver_id': receiverId,
    'status': status,
    'created_at': createdAt.toIso8601String(),
    'mutual_count': mutualCount,
  };

  factory FriendRequest.fromMap(Map<String, dynamic> map) => FriendRequest(
    id: map['id']?.toString() ?? '',
    senderId: map['sender_id'] ?? '',
    senderName: map['sender_name'] ?? 'Unknown',
    receiverId: map['receiver_id'] ?? '',
    status: map['status'] ?? 'pending',
    createdAt: (DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now()).toUtc(),
    mutualCount: map['mutual_count'] ?? 0,
  );

  String toJson() => json.encode(toMap());
  factory FriendRequest.fromJson(String source) =>
      FriendRequest.fromMap(json.decode(source));
}
