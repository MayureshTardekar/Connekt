enum SharedCardType { none, note, event, lostFound, ghostPost }

class ChatMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String text;
  final DateTime timestamp;
  final bool isRead;
  final bool isFromMe; // Local UI helper

  // Phase 2 Expressive features
  final Map<String, int> reactions;
  final bool isGif;
  final bool isSticker;

  final SharedCardType sharedCardType;
  final Map<String, dynamic>? sharedData;
  
  // Phase 4 Threading
  final String? replyToId;
  final String? replyToText;
  final String? replyToName;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.text,
    required this.timestamp,
    this.isRead = false,
    this.isFromMe = false,
    this.reactions = const {},
    this.isGif = false,
    this.isSticker = false,
    this.sharedCardType = SharedCardType.none,
    this.sharedData,
    this.replyToId,
    this.replyToText,
    this.replyToName,
  });

  ChatMessage copyWith({
    String? id,
    String? senderId,
    String? senderName,
    String? text,
    DateTime? timestamp,
    bool? isRead,
    bool? isFromMe,
    Map<String, int>? reactions,
    bool? isGif,
    bool? isSticker,
    SharedCardType? sharedCardType,
    Map<String, dynamic>? sharedData,
    String? replyToId,
    String? replyToText,
    String? replyToName,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      senderName: senderName ?? this.senderName,
      text: text ?? this.text,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      isFromMe: isFromMe ?? this.isFromMe,
      reactions: reactions ?? this.reactions,
      isGif: isGif ?? this.isGif,
      isSticker: isSticker ?? this.isSticker,
      sharedCardType: sharedCardType ?? this.sharedCardType,
      sharedData: sharedData ?? this.sharedData,
      replyToId: replyToId ?? this.replyToId,
      replyToText: replyToText ?? this.replyToText,
      replyToName: replyToName ?? this.replyToName,
    );
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id']?.toString() ?? '',
      senderId: (json['senderId'] ?? json['sender_id'])?.toString() ?? '',
      senderName: (json['senderName'] ?? json['sender_name'])?.toString() ?? '',
      text: json['text'] as String? ?? '',
      timestamp: (json['timestamp'] ?? json['created_at']) != null 
          ? ((json['timestamp'] ?? json['created_at']) is int 
              ? DateTime.fromMillisecondsSinceEpoch((json['timestamp'] ?? json['created_at']) as int)
              : DateTime.parse((json['timestamp'] ?? json['created_at']).toString()))
          : DateTime.now(),
      isRead: (json['isRead'] ?? json['is_read']) as bool? ?? false,
      isFromMe: (json['isFromMe'] ?? json['is_from_me']) as bool? ?? false,
      reactions: (json['reactions'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as int),
          ) ??
          {},
      isGif: (json['isGif'] ?? json['is_gif']) as bool? ?? false,
      isSticker: (json['isSticker'] ?? json['is_sticker']) as bool? ?? false,
      sharedCardType: SharedCardType.values.firstWhere(
        (e) => e.name == (json['sharedCardType'] ?? json['shared_card_type']) as String?,
        orElse: () => SharedCardType.none,
      ),
      sharedData: (json['sharedData'] ?? json['shared_data']) as Map<String, dynamic>?,
      replyToId: (json['replyToId'] ?? json['reply_to_id'])?.toString(),
      replyToText: (json['replyToText'] ?? json['reply_to_text'])?.toString(),
      replyToName: (json['replyToName'] ?? json['reply_to_name'])?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'senderId': senderId,
      'senderName': senderName,
      'text': text,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'isFromMe': isFromMe,
      'reactions': reactions,
      'isGif': isGif,
      'isSticker': isSticker,
      'sharedCardType': sharedCardType.name,
      'sharedData': sharedData,
      'reply_to_id': replyToId,
      'reply_to_text': replyToText,
      'reply_to_name': replyToName,
    };
  }
}
