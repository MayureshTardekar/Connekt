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
}
