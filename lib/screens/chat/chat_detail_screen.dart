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
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

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
  bool _isSendingLocally = false;

  // Voice recording state
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  String? _recordingPath;

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
      await ref
          .read(chatRepositoryProvider)
          .sendMessage(
            widget.conversation.id,
            message,
            conversation: widget.conversation,
          );
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
        final dir = await getTemporaryDirectory();
        final path = '${dir.path}/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';
        
        const config = RecordConfig();
        await _audioRecorder.start(config, path: path);
        
        setState(() {
          _isRecording = true;
          _recordingPath = path;
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
        final file = File(path);
        final bytes = await file.readAsBytes();
        
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
    final messagesAsync = ref.watch(
      chatMessagesProvider(widget.conversation.id),
    );
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
                    final startsGroup =
                        previous == null ||
                        previous.senderId != message.senderId;

                    return _MessageBubble(
                      message: message,
                      isFromMe: isMe,
                      showSender: isCommunity && !isMe && startsGroup,
                      isSending: _sendingIds.contains(message.id),
                      hasFailed: _failedIds.contains(message.id),
                      onRetry: () => _sendMessage(message),
                      onReact: (emoji) => ref.read(chatRepositoryProvider).toggleReaction(message.id, emoji),
                    );
                  },
                );
              },
            ),
          ),
          _MessageComposer(
            controller: _messageController,
            onSend: _sendCurrentMessage,
            isRecording: _isRecording,
            onStartRecording: _startRecording,
            onStopRecording: _stopRecording,
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
  });

  final ChatMessage message;
  final bool isFromMe;
  final bool showSender;
  final bool isSending;
  final bool hasFailed;
  final VoidCallback onRetry;
  final Function(String) onReact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bubbleColor = isFromMe
        ? theme.colorScheme.primary
        : theme.colorScheme.surface;
    final textColor = isFromMe
        ? Colors.white
        : theme.textTheme.bodyLarge?.color;

    final hasAudio = message.audioUrl != null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Align(
        alignment: isFromMe ? Alignment.centerRight : Alignment.centerLeft,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.78,
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
              GestureDetector(
                onLongPress: () => _showReactionPicker(context),
                child: Container(
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
                          Text(
                            _statusText(),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: isFromMe
                                  ? Colors.white.withValues(alpha: 0.72)
                                  : theme.textTheme.bodySmall?.color,
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(width: 4),
                          if (isFromMe && !isSending && !hasFailed)
                            Icon(
                              Icons.done_all_rounded,
                              size: 12,
                              color: message.isRead 
                                ? Colors.blueAccent 
                                : Colors.white.withValues(alpha: 0.5),
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
              ),
              if (message.reactions.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Wrap(
                    spacing: 4,
                    children: message.reactions.entries.map((e) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: theme.dividerColor, width: 0.5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(e.key, style: const TextStyle(fontSize: 12)),
                            const SizedBox(width: 2),
                            Text(
                              e.value.length.toString(),
                              style: theme.textTheme.bodySmall?.copyWith(fontSize: 10),
                            ),
                          ],
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

  void _showReactionPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: ['❤️', '👍', '😂', '🔥', '😮', '😢'].map((emoji) {
            return GestureDetector(
              onTap: () {
                onReact(emoji);
                Navigator.pop(context);
              },
              child: Text(emoji, style: const TextStyle(fontSize: 28)),
            );
          }).toList(),
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
  });

  final TextEditingController controller;
  final VoidCallback onSend;
  final bool isRecording;
  final VoidCallback onStartRecording;
  final VoidCallback onStopRecording;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasInput = controller.text.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        border: Border(top: BorderSide(color: theme.dividerColor)),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!isRecording) ...[
              IconButton(
                icon: const Icon(Icons.add_circle_outline_rounded),
                onPressed: () {}, // For future image support
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
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.mic, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Recording...',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(width: 8),
            GestureDetector(
              onLongPressStart: (_) => onStartRecording(),
              onLongPressEnd: (_) => onStopRecording(),
              child: IconButton.filled(
                onPressed: hasInput ? onSend : null,
                icon: Icon(hasInput ? Icons.send : Icons.mic_rounded),
                style: IconButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  disabledBackgroundColor: theme.dividerColor,
                  foregroundColor: Colors.white,
                  fixedSize: const Size(48, 48),
                ),
              ),
            ),
          ],
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
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(_isPlaying ? Icons.pause : Icons.play_arrow, 
               color: widget.isMe ? Colors.white : Theme.of(context).colorScheme.primary),
          onPressed: () async {
            if (_isPlaying) {
              await _player.pause();
            } else {
              await _player.play(UrlSource(widget.url));
            }
            setState(() => _isPlaying = !_isPlaying);
          },
        ),
        SizedBox(
          width: 120,
          child: Slider(
            value: _position.inMilliseconds.toDouble(),
            max: _duration.inMilliseconds.toDouble() > 0 ? _duration.inMilliseconds.toDouble() : 1.0,
            activeColor: widget.isMe ? Colors.white : Theme.of(context).colorScheme.primary,
            inactiveColor: widget.isMe ? Colors.white.withValues(alpha: 0.3) : Colors.grey[300],
            onChanged: (v) => _player.seek(Duration(milliseconds: v.toInt())),
          ),
        ),
      ],
    );
  }
}
