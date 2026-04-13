class ChatConversation {
  final String id;
  final String participantName;
  final String participantId;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  final bool isPinned;

  ChatConversation({
    required this.id,
    required this.participantName,
    required this.participantId,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
    this.isPinned = false,
  });

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    return ChatConversation(
      id: json['id'] as String? ?? '',
      participantName: json['participantName'] as String? ?? '',
      participantId: json['participantId'] as String? ?? '',
      lastMessage: json['lastMessage'] as String? ?? '',
      lastMessageTime: json['lastMessageTime'] != null
          ? (json['lastMessageTime'] is int
              ? DateTime.fromMillisecondsSinceEpoch(json['lastMessageTime'] as int)
              : DateTime.parse(json['lastMessageTime'].toString()))
          : DateTime.now(),
      unreadCount: json['unreadCount'] as int? ?? 0,
      isPinned: json['isPinned'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'participantName': participantName,
      'participantId': participantId,
      'lastMessage': lastMessage,
      'lastMessageTime': lastMessageTime.toIso8601String(),
      'unreadCount': unreadCount,
      'isPinned': isPinned,
    };
  }
}
