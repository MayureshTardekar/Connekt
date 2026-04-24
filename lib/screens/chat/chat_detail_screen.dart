import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/repositories/chat_repository.dart';
import '../../core/utils/time_formatter.dart';
import '../../core/widgets/base_chat_message_shell.dart';
import '../../core/widgets/media_bubble.dart';
import '../../core/widgets/message_interaction_sheet.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class ChatDetailScreen extends ConsumerStatefulWidget {
  const ChatDetailScreen({
    super.key,
    required this.targetId,
    required this.name,
    this.avatarUrl,
    this.isCommunity = false,
    this.isOfficial = false,
  });

  final String targetId;
  final String name;
  final String? avatarUrl;
  final bool isCommunity;
  final bool isOfficial;

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();
  final _chatRepo = ChatRepository();
  Map<String, dynamic>? _replyingTo;

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    try {
      if (widget.isCommunity) {
        await _chatRepo.sendCommunityMessage(
          communityId: widget.targetId,
          content: text,
          replyToId: _replyingTo?['id']?.toString(),
        );
      } else {
        await _chatRepo.sendDirectMessage(
          receiverId: widget.targetId,
          content: text,
          replyToId: _replyingTo?['id']?.toString(),
        );
      }
      _textController.clear();
      setState(() => _replyingTo = null);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final currentUserId = Supabase.instance.client.auth.currentUser?.id;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundImage: widget.avatarUrl != null 
                  ? NetworkImage(widget.avatarUrl!) 
                  : null,
              child: widget.avatarUrl == null ? const Icon(Icons.person) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                widget.name,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          Positioned(
            top: 100,
            right: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: theme.colorScheme.primary.withValues(alpha: 0.03),
              ),
            ),
          ),
          Column(
            children: [
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: widget.isCommunity 
                      ? _chatRepo.watchCommunityMessages(widget.targetId)
                      : _chatRepo.watchRawMessages(widget.targetId),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final messages = snapshot.data ?? [];
                    
                    return ListView.builder(
                      controller: _scrollController,
                      reverse: true,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                      itemCount: messages.length,
                      itemBuilder: (context, index) {
                        final msg = messages[index];
                        final isMe = msg['sender_id'] == currentUserId;
                        
                        final nextMsg = index > 0 ? messages[index - 1] : null;
                        final prevMsg = index < messages.length - 1 ? messages[index + 1] : null;
                        
                        final startsGroup = prevMsg == null || prevMsg['sender_id'] != msg['sender_id'];
                        final endsGroup = nextMsg == null || nextMsg['sender_id'] != msg['sender_id'];

                        return _MessageBubble(
                          message: msg,
                          isMe: isMe,
                          startsGroup: startsGroup,
                          endsGroup: endsGroup,
                          isCommunity: widget.isCommunity,
                          onReply: () => setState(() => _replyingTo = msg),
                        );
                      },
                    );
                  },
                ),
              ),
              if (_replyingTo != null)
                _ReplyPreview(
                  message: _replyingTo!,
                  onCancel: () => setState(() => _replyingTo = null),
                ),
              if (widget.isOfficial)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    border: Border(top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1))),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.1)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.lock_outline_rounded, size: 16, color: theme.colorScheme.primary),
                          const SizedBox(width: 10),
                          Text(
                            'Only admins can post announcements',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                _ChatInput(
                  controller: _textController,
                  onSend: _sendMessage,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isMe,
    required this.startsGroup,
    required this.endsGroup,
    required this.isCommunity,
    required this.onReply,
  });

  final Map<String, dynamic> message;
  final bool isMe;
  final bool startsGroup;
  final bool endsGroup;
  final bool isCommunity;
  final VoidCallback onReply;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final showSender = !isMe && (startsGroup || !isCommunity);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            _buildAvatar(context, message['sender_name'], message['sender_avatar']),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: BaseChatMessageShell(
              messageKey: Key(message['id'].toString()),
              onSwipeReply: onReply,
              onLongPress: () {
                MessageInteractionSheet.show(
                  context,
                  title: message['sender_name'] ?? 'Message',
                  onEmoji: (emoji) {
                    // Logic for reactions if supported
                  },
                  onReply: onReply,
                  canDelete: isMe,
                );
              },
              child: Container(
                margin: EdgeInsets.only(
                  bottom: endsGroup ? 8 : 1,
                  top: startsGroup ? 4 : 0,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: isMe
                      ? theme.colorScheme.primary
                      : theme.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(20),
                    topRight: const Radius.circular(20),
                    bottomLeft: Radius.circular(isMe ? 20 : (endsGroup ? 4 : 20)),
                    bottomRight: Radius.circular(isMe ? (endsGroup ? 4 : 20) : 20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (showSender)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          message['sender_name'] ?? 'User',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    if (message['reply_to_text'] != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          message['reply_to_text'],
                          style: theme.textTheme.bodySmall,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    
                    // NEW: Image Handling
                    if (message['image_url'] != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: MediaBubble(
                          networkUrl: message['image_url'],
                          maxWidth: 240,
                          maxHeight: 180,
                          borderRadius: 12,
                        ),
                      ),

                    if (message['content'] != null && message['content'] != '📷')
                      Text(
                        message['content'],
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isMe
                              ? theme.colorScheme.onPrimary
                              : theme.colorScheme.onSurface,
                        ),
                      ),
                    const SizedBox(height: 2),
                    Text(
                      TimeFormatter.format(
                        DateTime.tryParse(message['created_at'] ?? '') ??
                            DateTime.now(),
                      ),
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 9,
                        color: (isMe
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.onSurface)
                            .withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (isMe) ...[
            const SizedBox(width: 8),
            _buildAvatar(context, 'Me', null),
          ],
        ],
      ),
    );
  }

  Widget _buildAvatar(BuildContext context, String? name, String? avatarUrl) {
    final theme = Theme.of(context);
    final initials = (name ?? 'U').isNotEmpty ? name![0].toUpperCase() : 'U';

    return Opacity(
      opacity: endsGroup ? 1.0 : 0.0,
      child: CircleAvatar(
        radius: 12,
        backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
        backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
        child: avatarUrl == null
            ? Text(
                initials,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              )
            : null,
      ),
    );
  }
}

class _ChatInput extends StatelessWidget {
  const _ChatInput({required this.controller, required this.onSend});
  final TextEditingController controller;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.1))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: TextField(
                  controller: controller,
                  style: theme.textTheme.bodyMedium,
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.4),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.primary.withValues(alpha: 0.8),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: onSend,
                icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReplyPreview extends StatelessWidget {
  const _ReplyPreview({required this.message, required this.onCancel});
  final Map<String, dynamic> message;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: theme.colorScheme.surfaceContainerHighest,
      child: Row(
        children: [
          const Icon(Icons.reply_rounded, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Replying to...',
                  style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary),
                ),
                Text(
                  message['content'] ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20),
            onPressed: onCancel,
          ),
        ],
      ),
    );
  }
}
