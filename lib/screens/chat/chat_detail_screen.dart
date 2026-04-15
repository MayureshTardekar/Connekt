import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/models/chat_conversation.dart';
import '../../core/models/chat_message.dart';
import '../../core/providers/chat_provider.dart';
import '../../core/widgets/app_states.dart';
import '../../theme/app_theme.dart';
import '../../theme/avatar_helper.dart';

class ChatDetailScreen extends ConsumerStatefulWidget {
  const ChatDetailScreen({super.key, required this.conversation});

  final ChatConversation conversation;

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  static const int _maxMessageLength = 1000;

  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _localMessages = [];
  final Set<String> _sendingIds = {};
  final Set<String> _failedIds = {};

  @override
  void initState() {
    super.initState();
    _messageController.addListener(_handleInputChanged);
  }

  @override
  void dispose() {
    _messageController
      ..removeListener(_handleInputChanged)
      ..dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleInputChanged() => setState(() {});

  Future<void> _sendCurrentMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in again to send messages.')),
      );
      return;
    }

    final message = ChatMessage(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      senderId: user.id,
      senderName: user.userMetadata?['full_name'] ??
          user.userMetadata?['name'] ??
          user.email?.split('@').first ??
          'Student',
      text: text,
      timestamp: DateTime.now(),
      isFromMe: true,
    );

    _messageController.clear();
    await _sendMessage(message);
  }

  Future<void> _sendMessage(ChatMessage message) async {
    setState(() {
      if (!_localMessages.any((local) => local.id == message.id)) {
        _localMessages.add(message);
      }
      _failedIds.remove(message.id);
      _sendingIds.add(message.id);
    });
    _scrollToLatest();

    try {
      await ref.read(chatRepositoryProvider).sendMessage(
            widget.conversation.id,
            message,
            conversation: widget.conversation,
          );
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _sendingIds.remove(message.id);
        _failedIds.add(message.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Message not sent. Check your connection.')),
      );
    }
  }

  void _scrollToLatest() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  List<ChatMessage> _mergeMessages(List<ChatMessage> serverMessages) {
    final merged = [...serverMessages];
    final deliveredIds = <String>{};

    for (final local in _localMessages) {
      final existsOnServer = serverMessages.any(
        (server) => _looksLikeDeliveredCopy(server, local),
      );

      if (existsOnServer) {
        deliveredIds.add(local.id);
      } else {
        merged.add(local);
      }
    }

    if (deliveredIds.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        setState(() {
          _localMessages.removeWhere(
            (message) => deliveredIds.contains(message.id),
          );
          _sendingIds.removeAll(deliveredIds);
          _failedIds.removeAll(deliveredIds);
        });
      });
    }

    merged.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    return merged;
  }

  bool _looksLikeDeliveredCopy(ChatMessage server, ChatMessage local) {
    if (server.id == local.id) return true;
    final sameSender = server.senderId == local.senderId;
    final sameText = server.text.trim() == local.text.trim();
    final closeTimestamp =
        server.timestamp.difference(local.timestamp).inSeconds.abs() <= 15;
    return sameSender && sameText && closeTimestamp;
  }

  bool _isFromMe(ChatMessage message) {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    return message.isFromMe ||
        message.senderId == userId ||
        message.senderId == 'me';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final messagesAsync = ref.watch(chatMessagesProvider(widget.conversation.id));
    final hasInput = _messageController.text.trim().isNotEmpty;
    final isCommunity = widget.conversation.participantId == 'community';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
        titleSpacing: 0,
        title: Row(
          children: [
            isCommunity
                ? Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.groups_rounded,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                  )
                : avatarWidget(widget.conversation.participantName, radius: 19),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.conversation.participantName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isCommunity ? 'Campus-wide conversation' : 'Conversation',
                    style: theme.textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              loading: () =>
                  const AppLoadingState(message: 'Loading conversation...'),
              error: (error, _) => AppErrorState(
                message: error.toString(),
                onRetry: () => ref.invalidate(
                  chatMessagesProvider(widget.conversation.id),
                ),
              ),
              data: (serverMessages) {
                final messages = _mergeMessages(serverMessages);
                if (messages.isEmpty) {
                  return AppEmptyState(
                    icon: Icons.chat_bubble_outline_rounded,
                    title: 'No messages yet',
                    subtitle: isCommunity
                        ? 'Start a useful campus thread when there is something real to share.'
                        : 'Send the first message when you are ready.',
                  );
                }

                _scrollToLatest();
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 22),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = _isFromMe(message);
                    final previous = index > 0 ? messages[index - 1] : null;
                    final startsGroup = previous == null ||
                        previous.senderId != message.senderId;

                    return _MessageBubble(
                      message: message,
                      isFromMe: isMe,
                      showSender: isCommunity && !isMe && startsGroup,
                      isSending: _sendingIds.contains(message.id),
                      hasFailed: _failedIds.contains(message.id),
                      onRetry: () => _sendMessage(message),
                    );
                  },
                );
              },
            ),
          ),
          _MessageComposer(
            controller: _messageController,
            enabled: hasInput,
            maxLength: _maxMessageLength,
            onSend: _sendCurrentMessage,
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({
    required this.message,
    required this.isFromMe,
    required this.showSender,
    required this.isSending,
    required this.hasFailed,
    required this.onRetry,
  });

  final ChatMessage message;
  final bool isFromMe;
  final bool showSender;
  final bool isSending;
  final bool hasFailed;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bubbleColor =
        isFromMe ? theme.colorScheme.primary : theme.colorScheme.surface;
    final textColor = isFromMe ? Colors.white : theme.textTheme.bodyLarge?.color;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Align(
        alignment: isFromMe ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78,
          ),
          child: Column(
            crossAxisAlignment:
                isFromMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              if (showSender) ...[
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 4),
                  child: Text(
                    message.senderName,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: bubbleColor,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomLeft: Radius.circular(isFromMe ? 18 : 6),
                    bottomRight: Radius.circular(isFromMe ? 6 : 18),
                  ),
                  border: Border.all(
                    color: hasFailed
                        ? AppTheme.coral
                        : isFromMe
                            ? Colors.transparent
                            : theme.dividerColor,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.text,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: textColor,
                        height: 1.42,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _statusText(),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: isFromMe
                                ? Colors.white.withValues(alpha: 0.72)
                                : theme.textTheme.bodySmall?.color,
                            fontSize: 10,
                          ),
                        ),
                        if (hasFailed) ...[
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: onRetry,
                            child: Text(
                              'Retry',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isFromMe ? Colors.white : AppTheme.coral,
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _statusText() {
    if (hasFailed) return 'Not sent';
    if (isSending) return 'Sending';
    return DateFormat('h:mm a').format(message.timestamp);
  }
}

class _MessageComposer extends StatelessWidget {
  const _MessageComposer({
    required this.controller,
    required this.enabled,
    required this.maxLength,
    required this.onSend,
  });

  final TextEditingController controller;
  final bool enabled;
  final int maxLength;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 5,
                maxLength: maxLength,
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.newline,
                decoration: InputDecoration(
                  hintText: 'Write a message',
                  counterText: '',
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide(color: theme.dividerColor),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            IconButton.filled(
              onPressed: enabled ? onSend : null,
              icon: const Icon(Icons.arrow_upward_rounded),
              style: IconButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                disabledBackgroundColor: theme.dividerColor,
                foregroundColor: Colors.white,
                disabledForegroundColor: theme.textTheme.bodySmall?.color,
                fixedSize: const Size(48, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
