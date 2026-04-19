import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/models/chat_conversation.dart';
import '../../core/models/chat_message.dart';
import '../../core/providers/chat_provider.dart';
import '../../core/widgets/app_states.dart';
import '../../core/widgets/media_bubble.dart';
import '../../core/widgets/message_interaction_sheet.dart';
import '../../theme/app_theme.dart';
import '../../theme/avatar_helper.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

import 'dart:ui';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';


class ChatDetailScreen extends ConsumerStatefulWidget {
  const ChatDetailScreen({super.key, required this.conversation});

  final ChatConversation conversation;

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final List<ChatMessage> _localMessages = [];
  final Set<String> _sendingIds = {};
  final Set<String> _failedIds = {};
  bool _isSendingLocally = false;
  
  ChatMessage? _replyingTo;

  // Voice recording state
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;

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
    _audioRecorder.dispose();
    super.dispose();
  }

  void _handleInputChanged() => setState(() {});

  Future<void> _sendCurrentMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSendingLocally) return;

    HapticFeedback.lightImpact();
    setState(() => _isSendingLocally = true);

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      setState(() => _isSendingLocally = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sign in again to send messages.')),
      );
      return;
    }

    final message = ChatMessage(
      id: 'local-${DateTime.now().microsecondsSinceEpoch}',
      senderId: user.id,
      senderName:
          user.userMetadata?['full_name'] ??
          user.userMetadata?['name'] ??
          user.email?.split('@').first ??
          'Student',
      text: text,
      timestamp: DateTime.now(),
      isFromMe: true,
      replyToId: _replyingTo?.id,
      replyToText: _replyingTo?.text,
      replyToName: _replyingTo?.senderName,
    );

    _messageController.clear();
    setState(() => _replyingTo = null);
    await _sendMessage(message);
  }

  Future<void> _pickImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);
      
      if (image != null) {
        final bytes = await image.readAsBytes();
        final extension = image.path.split('.').last;
        final imageUrl = await ref.read(chatRepositoryProvider).uploadImage(bytes, extension);
        
        if (imageUrl != null) {
          final user = Supabase.instance.client.auth.currentUser;
          final message = ChatMessage(
            id: 'local-${DateTime.now().microsecondsSinceEpoch}',
            senderId: user?.id ?? 'me',
            senderName: user?.userMetadata?['full_name'] ?? 'Me',
            text: '📷 Image attached',
            imageUrl: imageUrl,
            timestamp: DateTime.now(),
            isFromMe: true,
            replyToId: _replyingTo?.id,
            replyToText: _replyingTo?.text,
            replyToName: _replyingTo?.senderName,
          );
          setState(() => _replyingTo = null);
          await _sendMessage(message);
        }
      }
    } catch (e) {
      debugPrint('Image pick error: $e');
    }
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
      await ref
          .read(chatRepositoryProvider)
          .sendMessage(
            widget.conversation.id,
            message,
            conversation: widget.conversation,
          );
      HapticFeedback.mediumImpact();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSendingLocally = false;
        _sendingIds.remove(message.id);
        _failedIds.add(message.id);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Send failed: ${e.toString()}'),
          duration: const Duration(seconds: 5),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSendingLocally = false);
      }
    }
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        const config = RecordConfig();
        // On web, path is ignored by the plugin, but we must handle it for mobile
        String? path;
        if (!kIsWeb) {
           final dir = await getTemporaryDirectory();
           path = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
        }
        
        await _audioRecorder.start(config, path: path ?? '');

        
        HapticFeedback.heavyImpact();
        setState(() {
          _isRecording = true;
        });
      }
    } catch (e) {
      debugPrint('Start recording error: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      setState(() => _isRecording = false);

      if (path != null) {
        Uint8List bytes;
        if (kIsWeb) {
          // On web, the path is a blob URL from the browser
          final response = await http.get(Uri.parse(path));
          bytes = response.bodyBytes;
        } else {
          // On mobile/desktop, use the standard crossing-platform byte fetch
          // We can't use File(path) because we removed dart:io
          // Using a help pattern or conditional import is better, 
          // but for now, we'll fetch via a helper in repository or use CrossFile (XFile)
          bytes = await XFile(path).readAsBytes();
        }

        
        final audioUrl = await ref.read(chatRepositoryProvider).uploadVoiceMessage(bytes);
        if (audioUrl != null) {
          final user = Supabase.instance.client.auth.currentUser;
          final message = ChatMessage(
            id: 'local-${DateTime.now().microsecondsSinceEpoch}',
            senderId: user?.id ?? 'me',
            senderName: user?.userMetadata?['full_name'] ?? 'Me',
            text: '🎤 Voice Message',
            audioUrl: audioUrl,
            audioDuration: 0, // Could calculate if needed
            timestamp: DateTime.now(),
            isFromMe: true,
          );
          await _sendMessage(message);
        }
      }
    } catch (e) {
      debugPrint('Stop recording error: $e');
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

  Future<void> _confirmDeleteMessage(ChatMessage message) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete message?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Delete',
              style: TextStyle(color: Theme.of(ctx).colorScheme.error),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await ref.read(chatRepositoryProvider).deleteMessage(message.id);
      ref.invalidate(chatMessagesProvider(widget.conversation.id));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not delete: $e')),
        );
      }
    }
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

  void _markAsReadIfNeeded(List<ChatMessage> messages) {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    for (final msg in messages) {
      if (!msg.isRead && msg.senderId != userId) {
        ref.read(chatRepositoryProvider).markAsRead(msg.id);
      }
    }
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
    final messagesAsync = ref.watch(
      chatMessagesProvider(widget.conversation.id),
    );
    final isCommunity = widget.conversation.participantId == 'community';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: ClipRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: AppBar(
              backgroundColor: theme.scaffoldBackgroundColor.withValues(alpha: 0.8),
              elevation: 0,
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
                            color: theme.colorScheme.primary.withValues(alpha: 0.15),
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
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: -0.5,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isCommunity ? 'Campus Connect' : 'Online',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ColoredBox(
              color: theme.brightness == Brightness.light
                  ? theme.colorScheme.surfaceContainerLow
                  : theme.scaffoldBackgroundColor,
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
                
                // Mark incoming messages as read
                _markAsReadIfNeeded(serverMessages);

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
                return AnimationLimiter(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: EdgeInsets.fromLTRB(
                      18,
                      18,
                      18,
                      22 + MediaQuery.viewInsetsOf(context).bottom,
                    ),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      final isMe = _isFromMe(message);
                      final previous = index > 0 ? messages[index - 1] : null;
                      final startsGroup =
                          previous == null ||
                          previous.senderId != message.senderId;

                      return AnimationConfiguration.staggeredList(
                        position: index,
                        duration: const Duration(milliseconds: 375),
                        child: SlideAnimation(
                          verticalOffset: 50.0,
                          child: FadeInAnimation(
                            child: _MessageBubble(
                              message: message,
                              isFromMe: isMe,
                              showSender: isCommunity && !isMe && startsGroup,
                              isSending: _sendingIds.contains(message.id),
                              hasFailed: _failedIds.contains(message.id),
                              onRetry: () => _sendMessage(message),
                              onReact: (emoji) {
                                HapticFeedback.selectionClick();
                                if (message.id.startsWith('local-')) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Wait until the message finishes sending before reacting.',
                                      ),
                                    ),
                                  );
                                  return;
                                }
                                ref
                                    .read(chatRepositoryProvider)
                                    .toggleReaction(message.id, emoji)
                                    .whenComplete(() {
                                  if (context.mounted) {
                                    ref.invalidate(
                                      chatMessagesProvider(
                                        widget.conversation.id,
                                      ),
                                    );
                                  }
                                });
                              },
                              onReply: (msg) {
                                HapticFeedback.mediumImpact();
                                setState(() => _replyingTo = msg);
                              },
                              onRequestDelete: isMe
                                  ? () => _confirmDeleteMessage(message)
                                  : null,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            ),
          ),
          _MessageComposer(
            controller: _messageController,
            onSend: _sendCurrentMessage,
            isRecording: _isRecording,
            onStartRecording: _startRecording,
            onStopRecording: _stopRecording,
            onPickImage: _pickImage,
            replyingTo: _replyingTo,
            onCancelReply: () => setState(() => _replyingTo = null),
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
    required this.onReact,
    required this.onReply,
    this.onRequestDelete,
  });

  final ChatMessage message;
  final bool isFromMe;
  final bool showSender;
  final bool isSending;
  final bool hasFailed;
  final VoidCallback onRetry;
  final Function(String) onReact;
  final Function(ChatMessage) onReply;
  final VoidCallback? onRequestDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    // Obsidian Luxe Color Palette
    final primaryGradient = LinearGradient(
      colors: [
        theme.colorScheme.primary,
        theme.colorScheme.primary.withValues(alpha: 0.8),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );
    
    final surfaceColor = isDark
        ? const Color(0xFF1C1C24)
        : theme.colorScheme.surface;

    final textColor = isFromMe
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.onSurface;

    final hasAudio = message.audioUrl != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Align(
        alignment: isFromMe ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.76,
          ),
          child: Column(
            crossAxisAlignment: isFromMe
                ? CrossAxisAlignment.end
                : CrossAxisAlignment.start,
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
              Dismissible(
                key: Key(message.id),
                direction: isFromMe ? DismissDirection.endToStart : DismissDirection.startToEnd,
                confirmDismiss: (_) async {
                  onReply(message);
                  return false;
                },
                background: const Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(padding: EdgeInsets.only(left: 16), child: Icon(Icons.reply_rounded)),
                ),
                secondaryBackground: const Align(
                  alignment: Alignment.centerRight,
                  child: Padding(padding: EdgeInsets.only(right: 16), child: Icon(Icons.reply_rounded)),
                ),
                child: GestureDetector(
                  onLongPress: () {
                    HapticFeedback.mediumImpact();
                    MessageInteractionSheet.show(
                      context,
                      title: 'Message',
                      onEmoji: onReact,
                      onReply: () => onReply(message),
                      onDelete: onRequestDelete,
                      canDelete:
                          isFromMe && onRequestDelete != null,
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      gradient: isFromMe ? primaryGradient : null,
                      color: isFromMe ? null : surfaceColor,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(22),
                        topRight: const Radius.circular(22),
                        bottomLeft: Radius.circular(isFromMe ? 22 : 4),
                        bottomRight: Radius.circular(isFromMe ? 4 : 22),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.shadowColor.withValues(alpha: isDark ? 0.28 : 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      border: Border.all(
                        color: hasFailed
                            ? AppTheme.coral
                            : isFromMe
                            ? theme.colorScheme.onPrimary.withValues(alpha: 0.12)
                            : theme.dividerColor.withValues(alpha: 0.05),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (message.replyToName != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            margin: const EdgeInsets.only(bottom: 6),
                            decoration: BoxDecoration(
                              color: isFromMe
                                  ? theme.colorScheme.onPrimary.withValues(alpha: 0.15)
                                  : theme.dividerColor.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(8),
                              border: Border(
                                left: BorderSide(
                                  color: isFromMe
                                      ? theme.colorScheme.onPrimary
                                      : theme.colorScheme.primary,
                                  width: 3,
                                ),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  message.replyToName!,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: isFromMe
                                        ? theme.colorScheme.onPrimary
                                        : theme.colorScheme.primary,
                                  ),
                                ),
                                Text(
                                  message.replyToText ?? '',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: textColor.withValues(alpha: 0.85),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (message.imageUrl != null) ...[
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Flexible(
                                child: MediaBubble(
                                  networkUrl: message.imageUrl,
                                  maxWidth: MediaQuery.sizeOf(context).width * 0.68,
                                  maxHeight: 240,
                                  borderRadius: 12,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                        ],
                        if (hasAudio)
                          _VoiceMessagePlayer(url: message.audioUrl!, isMe: isFromMe)
                        else
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
                          Flexible(
                            child: Text(
                              _statusText(),
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isFromMe
                                    ? theme.colorScheme.onPrimary.withValues(alpha: 0.75)
                                    : theme.textTheme.bodySmall?.color,
                                fontSize: 10,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          if (isFromMe && !isSending && !hasFailed)
                            Padding(
                              padding: const EdgeInsets.only(left: 4),
                              child: Icon(
                                message.isRead 
                                  ? Icons.done_all_rounded 
                                  : Icons.check_rounded,
                                size: 14,
                                color: message.isRead 
                                  ? theme.colorScheme.secondary
                                  : theme.colorScheme.onPrimary.withValues(alpha: 0.65),
                              ),
                            ),

                          if (hasFailed) ...[
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: onRetry,
                              child: Text(
                                'Retry',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: isFromMe
                                      ? theme.colorScheme.onPrimary
                                      : AppTheme.coral,
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
              ),
            ),
            if (message.reactions.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Wrap(
                    spacing: 4,
                    children: message.reactions.entries.map((e) {
                      return ZoomIn(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: theme.dividerColor.withValues(alpha: 0.35),
                              width: 0.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: theme.shadowColor.withValues(alpha: 0.12),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(e.key, style: const TextStyle(fontSize: 13)),
                              const SizedBox(width: 4),
                              Text(
                                e.value.length.toString(),
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
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
    required this.onSend,
    required this.isRecording,
    required this.onStartRecording,
    required this.onStopRecording,
    required this.onPickImage,
    this.replyingTo,
    required this.onCancelReply,
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final bool isRecording;
  final VoidCallback onStartRecording;
  final VoidCallback onStopRecording;
  final VoidCallback onPickImage;
  final ChatMessage? replyingTo;
  final VoidCallback onCancelReply;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasInput = controller.text.trim().isNotEmpty;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          decoration: BoxDecoration(
            color: theme.scaffoldBackgroundColor.withValues(alpha: 0.7),
            border: Border(
              top: BorderSide(
                color: theme.dividerColor.withValues(alpha: 0.35),
              ),
            ),
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (replyingTo != null)

              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border(left: BorderSide(color: theme.colorScheme.primary, width: 4)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Replying to ${replyingTo!.senderName}',
                            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12, color: theme.colorScheme.primary),
                          ),
                          Text(
                            replyingTo!.text,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 18),
                      onPressed: onCancelReply,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!isRecording) ...[
              IconButton(
                icon: const Icon(Icons.add_photo_alternate_rounded),
                onPressed: onPickImage,
                color: theme.colorScheme.primary,
              ),
              Expanded(
                child: TextField(
                  controller: controller,
                  minLines: 1,
                  maxLines: 5,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.newline,
                  decoration: InputDecoration(
                    hintText: 'Message...',
                    counterText: '',
                    filled: true,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    fillColor: theme.colorScheme.surface,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: theme.dividerColor),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide(color: theme.colorScheme.primary, width: 1.5),
                    ),
                  ),
                ),
              ),
            ] else 
              Expanded(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.2)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Pulse(
                        infinite: true,
                        child: const Icon(Icons.mic, color: Colors.redAccent, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Flash(
                        infinite: true,
                        duration: const Duration(seconds: 2),
                        child: Text(
                          'Recording Audio...',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(width: 12),
            GestureDetector(
              onLongPressStart: (_) => onStartRecording(),
              onLongPressEnd: (_) => onStopRecording(),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: IconButton.filled(
                  onPressed: hasInput ? onSend : null,
                  icon: Icon(hasInput ? Icons.send : Icons.mic_rounded, size: 22),
                  style: IconButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    minimumSize: const Size(54, 54),
                    disabledBackgroundColor: theme.dividerColor.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),
                ],
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
}

class _VoiceMessagePlayer extends StatefulWidget {
  final String url;
  final bool isMe;
  const _VoiceMessagePlayer({required this.url, required this.isMe});

  @override
  State<_VoiceMessagePlayer> createState() => _VoiceMessagePlayerState();
}

class _VoiceMessagePlayerState extends State<_VoiceMessagePlayer> {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _player.onDurationChanged.listen((d) => setState(() => _duration = d));
    _player.onPositionChanged.listen((p) => setState(() => _position = p));
    _player.onPlayerComplete.listen((_) => setState(() => _isPlaying = false));
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = widget.isMe
        ? theme.colorScheme.onPrimary
        : theme.colorScheme.primary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: widget.isMe
            ? theme.colorScheme.onPrimary.withValues(alpha: 0.12)
            : theme.colorScheme.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(30),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () async {
              HapticFeedback.lightImpact();
              if (_isPlaying) {
                await _player.pause();
              } else {
                await _player.play(UrlSource(widget.url));
              }
              if (mounted) setState(() => _isPlaying = !_isPlaying);
            },
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _isPlaying ? color : color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                color: _isPlaying
                    ? (widget.isMe
                        ? theme.colorScheme.primary
                        : theme.colorScheme.onPrimary)
                    : color,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: 140,
                height: 20,
                child: SliderTheme(
                  data: SliderThemeData(
                    trackHeight: 2,
                    thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
                    overlayShape: const RoundSliderOverlayShape(overlayRadius: 10),
                    activeTrackColor: color,
                    inactiveTrackColor: color.withValues(alpha: 0.1),
                    thumbColor: color,
                  ),
                  child: Slider(
                    value: _position.inMilliseconds.toDouble(),
                    max: _duration.inMilliseconds.toDouble() > 0 ? _duration.inMilliseconds.toDouble() : 1.0,
                    onChanged: (v) {
                      _player.seek(Duration(milliseconds: v.toInt()));
                    },
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(_position),
                      style: TextStyle(color: color.withValues(alpha: 0.5), fontSize: 8),
                    ),
                    const SizedBox(width: 90),
                    Text(
                      _formatDuration(_duration),
                      style: TextStyle(color: color.withValues(alpha: 0.5), fontSize: 8),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(width: 8),
        ],
      ),
    );
  }

  String _formatDuration(Duration d) {
    if (d == Duration.zero) return '0:00';
    final minutes = d.inMinutes.remainder(60).toString().padLeft(1, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}
