import '../utils/reactions_json.dart';

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
  final Map<String, List<String>> reactions; // emoji -> list of userIds
  final String? audioUrl;
  final String? imageUrl;
  final int? audioDuration; // in seconds
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
    this.audioUrl,
    this.imageUrl,
    this.audioDuration,
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
    Map<String, List<String>>? reactions,
    String? audioUrl,
    String? imageUrl,
    int? audioDuration,
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
      audioUrl: audioUrl ?? this.audioUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      audioDuration: audioDuration ?? this.audioDuration,
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
      text: (json['content'] ?? json['text'] ?? '') as String,
      timestamp: (json['created_at'] ?? json['timestamp']) != null
          ? ((json['created_at'] ?? json['timestamp']) is int
                ? DateTime.fromMillisecondsSinceEpoch(
                    (json['created_at'] ?? json['timestamp']) as int,
                  )
                : DateTime.parse(
                    (json['created_at'] ?? json['timestamp']).toString(),
                  ))
          : DateTime.now(),
      isRead: (json['isRead'] ?? json['is_read']) as bool? ?? false,
      isFromMe: (json['isFromMe'] ?? json['is_from_me']) as bool? ?? false,
      reactions: parseReactionsJson(json['reactions']),
      audioUrl: (json['audioUrl'] ?? json['audio_url'])?.toString(),
      imageUrl: (json['imageUrl'] ?? json['image_url'])?.toString(),
      audioDuration: json['audioDuration'] ?? json['audio_duration'],
      isGif: (json['isGif'] ?? json['is_gif']) as bool? ?? false,
      isSticker: (json['isSticker'] ?? json['is_sticker']) as bool? ?? false,
      sharedCardType: SharedCardType.values.firstWhere(
        (e) =>
            e.name ==
            (json['sharedCardType'] ?? json['shared_card_type']) as String?,
        orElse: () => SharedCardType.none,
      ),
      sharedData:
          (json['sharedData'] ?? json['shared_data']) as Map<String, dynamic>?,
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
      'audio_url': audioUrl,
      'image_url': imageUrl,
      'audio_duration': audioDuration,
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
