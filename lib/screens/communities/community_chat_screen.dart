import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../core/providers/community_provider.dart';
import '../../core/utils/time_formatter.dart';
import '../../core/network/logger.dart';
import '../../core/widgets/base_chat_message_shell.dart';
import '../../core/widgets/media_bubble.dart';
import '../../core/widgets/message_interaction_sheet.dart';
import 'community_admin_screen.dart';

class CommunityChatScreen extends ConsumerStatefulWidget {
  final String communityId;
  const CommunityChatScreen({super.key, required this.communityId});

  @override
  ConsumerState<CommunityChatScreen> createState() =>
      _CommunityChatScreenState();
}

class _CommunityChatScreenState extends ConsumerState<CommunityChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final AudioRecorder _audioRecorder = AudioRecorder();
  bool _isRecording = false;
  Map<String, dynamic>? _replyingTo;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(activeCommunityIdProvider.notifier).state = widget.communityId;
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _audioRecorder.dispose();
    super.dispose();
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final directory = await getApplicationDocumentsDirectory();
        final path = p.join(directory.path, 'voice_note.m4a');

        await _audioRecorder.start(const RecordConfig(), path: path);
        setState(() => _isRecording = true);
      }
    } catch (e) {
      AppLogger.error('Recording Error: $e');
    }
  }

  Future<void> _stopAndSendRecording() async {
    final path = await _audioRecorder.stop();
    setState(() => _isRecording = false);

    if (path != null) {
      await ref
          .read(communityRepositoryProvider)
          .sendMessage(
            communityId: widget.communityId,
            type: 'voice',
            filePath: path,
          );
    }
  }

  Future<void> _pickAndSendImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      await ref
          .read(communityRepositoryProvider)
          .sendMessage(
            communityId: widget.communityId,
            type: 'image',
            filePath: image.path,
          );
    }
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    ref
        .read(communityRepositoryProvider)
        .sendMessage(
          communityId: widget.communityId,
          type: 'text',
          content: _messageController.text.trim(),
          replyToId: _replyingTo?['id'],
        );
    _messageController.clear();
    setState(() => _replyingTo = null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final messagesAsync = ref.watch(communityMessagesProvider);
    final membershipStatusAsync = ref.watch(communityMembershipStatusProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Community'),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              Icons.admin_panel_settings_outlined,
              color: theme.colorScheme.primary,
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    CommunityAdminScreen(communityId: widget.communityId),
              ),
            ),
          ),
        ],
      ),
      body: membershipStatusAsync.when(
        data: (status) {
          if (status != 'member') {
            return _buildAccessDenied(status);
          }
          return Column(
            children: [
              Expanded(
                child: ColoredBox(
                  color: theme.brightness == Brightness.light
                      ? theme.colorScheme.surfaceContainerLow
                      : theme.scaffoldBackgroundColor,
                  child: messagesAsync.when(
                  data: (messages) => ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: EdgeInsets.fromLTRB(
                      16,
                      8,
                      16,
                      8 + MediaQuery.viewInsetsOf(context).bottom,
                    ),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      return _buildMessageBubble(message);
                    },
                  ),
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (e, r) =>
                      Text('Error: $e', style: theme.textTheme.bodyLarge),
                ),
                ),
              ),
              if (_replyingTo != null) _buildReplyPreview(),
              _buildInputArea(),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, r) => const Center(child: Text('Error loading status')),
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final theme = Theme.of(context);
    final isMe =
        message['sender_id'] ==
        ref.read(communityRepositoryProvider).supabase.auth.currentUser?.id;
    final type = message['message_type'];
    final reactions = Map<String, dynamic>.from(message['reactions'] ?? {});
    final createdAt = DateTime.parse(message['created_at']);

    final bubbleBg = isMe
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.surfaceContainerHighest;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: isMe
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          Align(
            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
            child: BaseChatMessageShell(
              messageKey: Key(message['id'].toString()),
              maxWidthFactor: 0.78,
              onSwipeReply: () => setState(() => _replyingTo = message),
              onLongPress: () {
                MessageInteractionSheet.show(
                  context,
                  title: 'Message',
                  onEmoji: (emoji) {
                    ref
                        .read(communityRepositoryProvider)
                        .toggleReaction(message['id'], emoji)
                        .whenComplete(() {
                      if (context.mounted) {
                        ref.invalidate(communityMessagesProvider);
                      }
                    });
                  },
                  onReply: () => setState(() => _replyingTo = message),
                  onDelete: isMe == true
                      ? () => _deleteMessage(message['id'].toString())
                      : null,
                  canDelete: isMe == true,
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: bubbleBg,
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(18),
                    topRight: const Radius.circular(18),
                    bottomRight: Radius.circular(isMe == true ? 4 : 18),
                    bottomLeft: Radius.circular(isMe == true ? 18 : 4),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (message['reply_to_id'] != null)
                      _buildQuotedMessage(theme),
                    _buildMessageContent(message, type, theme),
                  ],
                ),
              ),
            ),
          ),
          if (reactions.isNotEmpty) _buildReactionsRow(reactions, theme),
          Padding(
            padding: EdgeInsets.only(
              top: 6,
              left: isMe ? 0 : 4,
              right: isMe ? 4 : 0,
            ),
            child: Text(
              TimeFormatter.format(createdAt),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuotedMessage(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.reply, size: 12, color: theme.colorScheme.primary),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              'Replying to a message',
              style: theme.textTheme.labelSmall,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReactionsRow(Map<String, dynamic> reactions, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        children: reactions.entries.map((e) {
          final users = List.from(e.value);
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '${e.key} ${users.length}',
              style: theme.textTheme.labelSmall,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildReplyPreview() {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.9),
      child: ListTile(
        dense: true,
        leading: Icon(Icons.reply_rounded, color: theme.colorScheme.primary),
        title: Text(
          _replyingTo?['content']?.toString() ?? 'Media',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.bodyMedium,
        ),
        trailing: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => setState(() => _replyingTo = null),
        ),
      ),
    );
  }

  void _deleteMessage(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Message?'),
        content: const Text('This will permanently delete your message.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(communityRepositoryProvider).deleteMessage(id);
    }
  }

  Widget _buildMessageContent(
    Map<String, dynamic> message,
    String type,
    ThemeData theme,
  ) {
    final fg = theme.colorScheme.onSurface;
    switch (type) {
      case 'image':
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Flexible(
                  child: MediaBubble(
                    networkUrl: message['file_url']?.toString(),
                    maxWidth: MediaQuery.sizeOf(context).width * 0.68,
                    maxHeight: 240,
                    borderRadius: 12,
                  ),
                ),
              ],
            ),
            if (message['content'] != null) ...[
              const SizedBox(height: 8),
              Text(
                message['content'].toString(),
                style: theme.textTheme.bodyMedium?.copyWith(color: fg),
              ),
            ],
          ],
        );
      case 'voice':
        return VoiceMessagePlayer(url: message['file_url'].toString());
      default:
        return Text(
          message['content']?.toString() ?? '',
          style: theme.textTheme.bodyLarge?.copyWith(color: fg, height: 1.35),
        );
    }
  }

  Widget _buildInputArea() {
    final theme = Theme.of(context);
    return Material(
      elevation: 8,
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 10, 8, 12),
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.image_outlined),
              color: theme.colorScheme.primary,
              onPressed: _pickAndSendImage,
            ),
            Expanded(
              child: TextField(
                controller: _messageController,
                style: theme.textTheme.bodyLarge,
                decoration: InputDecoration(
                  hintText: 'Type a message…',
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                ),
              ),
            ),
            GestureDetector(
              onLongPress: _startRecording,
              onLongPressUp: _stopAndSendRecording,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _isRecording
                      ? theme.colorScheme.error
                      : theme.colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _isRecording ? Icons.mic : Icons.mic_none,
                  color: _isRecording
                      ? theme.colorScheme.onError
                      : theme.colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            if (!_isRecording)
              IconButton.filled(
                onPressed: _sendMessage,
                icon: const Icon(Icons.send_rounded),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildAccessDenied(String? status) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.lock_person_outlined,
              size: 80,
              color: Colors.white24,
            ),
            const SizedBox(height: 24),
            const Text(
              'Private Community',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              status == 'pending'
                  ? 'Your request is pending approval.'
                  : 'You must join this community to see the messages.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white60),
            ),
            const SizedBox(height: 32),
            if (status != 'pending')
              ElevatedButton(
                onPressed: () => ref
                    .read(communityRepositoryProvider)
                    .joinCommunity(widget.communityId, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                ),
                child: const Text('Request to Join'),
              ),
          ],
        ),
      ),
    );
  }
}

class VoiceMessagePlayer extends StatefulWidget {
  final String url;
  const VoiceMessagePlayer({super.key, required this.url});

  @override
  State<VoiceMessagePlayer> createState() => _VoiceMessagePlayerState();
}

class _VoiceMessagePlayerState extends State<VoiceMessagePlayer> {
  late AudioPlayer _audioPlayer;
  bool _isPlaying = false;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();
    _audioPlayer.onDurationChanged.listen((d) => setState(() => _duration = d));
    _audioPlayer.onPositionChanged.listen((p) => setState(() => _position = p));
    _audioPlayer.onPlayerComplete.listen(
      (_) => setState(() => _isPlaying = false),
    );
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  void _togglePlay() async {
    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play(UrlSource(widget.url));
    }
    setState(() => _isPlaying = !_isPlaying);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Icon(
            _isPlaying ? Icons.pause_circle : Icons.play_circle,
            color: Colors.white,
            size: 30,
          ),
          onPressed: _togglePlay,
        ),
        Expanded(
          child: Slider(
            value: _position.inSeconds.toDouble(),
            max: _duration.inSeconds.toDouble(),
            onChanged: (v) => _audioPlayer.seek(Duration(seconds: v.toInt())),
            activeColor: Colors.white,
            inactiveColor: Colors.white24,
          ),
        ),
      ],
    );
  }
}
