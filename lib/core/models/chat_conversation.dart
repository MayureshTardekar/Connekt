class ChatConversation {
  final String id;
  final String participantName;
  final String participantId;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  final String? campusId;
  final bool isPinned;
  final bool isOfficial;
  final bool isGroup;

  ChatConversation({
    required this.id,
    required this.participantName,
    required this.participantId,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
    this.isPinned = false,
    this.campusId,
    this.isOfficial = false,
    this.isGroup = false,
  });

  factory ChatConversation.fromJson(Map<String, dynamic> json) {
    return ChatConversation(
      id: json['id']?.toString() ?? '',
      participantName:
          (json['participantName'] ?? 
           json['participant_name'] ?? 
           json['other_user_name'])?.toString() ??
          'Conversation',
      participantId:
          (json['participantId'] ?? json['participant_id'])?.toString() ?? '',
      lastMessage:
          (json['lastMessage'] ?? json['last_message'])?.toString() ?? '',
      lastMessageTime:
          (json['lastMessageTime'] ?? json['last_message_time']) != null
          ? ((json['lastMessageTime'] ?? json['last_message_time']) is int
                ? DateTime.fromMillisecondsSinceEpoch(
                    (json['lastMessageTime'] ?? json['last_message_time'])
                        as int,
                  )
                : DateTime.parse(
                    (json['lastMessageTime'] ?? json['last_message_time'])
                        .toString(),
                  ))
          : DateTime.now(),
      unreadCount: (json['unreadCount'] ?? json['unread_count']) as int? ?? 0,
      isPinned: (json['isPinned'] ?? json['is_pinned']) as bool? ?? false,
      campusId: (json['campusId'] ?? json['campus_id'])?.toString(),
      isOfficial: (json['isOfficial'] ?? json['is_official']) as bool? ?? false,
      isGroup: (json['isGroup'] ?? json['is_group']) as bool? ?? false,
    );
  }

  ChatConversation copyWith({
    String? id,
    String? participantName,
    String? participantId,
    String? lastMessage,
    DateTime? lastMessageTime,
    int? unreadCount,
    bool? isPinned,
    String? campusId,
    bool? isOfficial,
    bool? isGroup,
  }) {
    return ChatConversation(
      id: id ?? this.id,
      participantName: participantName ?? this.participantName,
      participantId: participantId ?? this.participantId,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      isPinned: isPinned ?? this.isPinned,
      campusId: campusId ?? this.campusId,
      isOfficial: isOfficial ?? this.isOfficial,
      isGroup: isGroup ?? this.isGroup,
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
      'campus_id': campusId,
      'is_official': isOfficial,
      'is_group': isGroup,
    };
  }
}
