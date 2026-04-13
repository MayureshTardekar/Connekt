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

  // Phase 3 Campus Social Layer features
  final SharedCardType sharedCardType;
  final Map<String, dynamic>? sharedData;

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
    );
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] as String? ?? '',
      senderId: json['senderId'] as String? ?? '',
      senderName: json['senderName'] as String? ?? '',
      text: json['text'] as String? ?? '',
      // Note: Assuming timestamp might be sent as ISO-8601 string or milliseconds since epoch
      timestamp: json['timestamp'] != null 
          ? (json['timestamp'] is int 
              ? DateTime.fromMillisecondsSinceEpoch(json['timestamp'] as int)
              : DateTime.parse(json['timestamp'].toString()))
          : DateTime.now(),
      isRead: json['isRead'] as bool? ?? false,
      isFromMe: json['isFromMe'] as bool? ?? false,
      reactions: (json['reactions'] as Map<String, dynamic>?)?.map(
            (k, e) => MapEntry(k, e as int),
          ) ??
          {},
      isGif: json['isGif'] as bool? ?? false,
      isSticker: json['isSticker'] as bool? ?? false,
      sharedCardType: SharedCardType.values.firstWhere(
        (e) => e.name == (json['sharedCardType'] as String?),
        orElse: () => SharedCardType.none,
      ),
      sharedData: json['sharedData'] as Map<String, dynamic>?,
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
    };
  }
}
