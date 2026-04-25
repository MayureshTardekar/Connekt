import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/repositories/study_groups_repository.dart';
import '../../core/models/study_group.dart';
import '../../core/widgets/media_bubble.dart';
import '../../core/widgets/base_chat_message_shell.dart';
import '../../core/widgets/message_interaction_sheet.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/utils/time_formatter.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/widgets/image_preview_send_sheet.dart';
import 'package:file_picker/file_picker.dart';

class StudyGroupChatScreen extends ConsumerStatefulWidget {
  const StudyGroupChatScreen({super.key, required this.group});
  final StudyGroup group;

  @override
  ConsumerState<StudyGroupChatScreen> createState() => _StudyGroupChatScreenState();
}

class _StudyGroupChatScreenState extends ConsumerState<StudyGroupChatScreen> {
  final _repo = StudyGroupsRepository();
  final _textCtrl = TextEditingController();
  final _scroll = ScrollController();
  Map<String, dynamic>? _replyingTo;

  @override
  void dispose() {
    _textCtrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _confirmDelete(String id) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete message?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Delete', style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
          ),
        ],
      ),
    );
    if (ok == true) await _repo.deleteGroupMessage(id);
  }

  Future<void> _sendText() async {
    final t = _textCtrl.text.trim();
    if (t.isEmpty) return;
    try {
      await _repo.sendGroupMessage(
        groupId: widget.group.id,
        messageType: 'text',
        content: t,
        replyToId: _replyingTo?['id']?.toString(),
      );
      _textCtrl.clear();
      setState(() => _replyingTo = null);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to send: $e')));
      }
    }
  }

  Future<void> _pickImage() async {
    final file = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (file == null || !mounted) return;
    final bytes = await file.readAsBytes();
    if (!mounted) return;
    var ext = file.path.contains('.') ? file.path.split('.').last.toLowerCase() : 'jpg';
    if (ext.isEmpty) ext = 'jpg';

    await showImagePreviewSendSheet(
      context: context,
      imageBytes: bytes,
      fileExtension: ext,
      initialCaption: _textCtrl.text,
      title: 'Send image',
      onConfirm: (b, e, caption) async {
        final safeName = 'img_${DateTime.now().millisecondsSinceEpoch}.$e';
        final url = await _repo.uploadGroupFile(b, safeName);
        if (url == null || !mounted) return;
        final text = caption.trim().isEmpty ? '📷' : caption.trim();
        await _repo.sendGroupMessage(
          groupId: widget.group.id,
          messageType: 'image',
          content: text,
          fileUrl: url,
          fileName: safeName,
          replyToId: _replyingTo?['id']?.toString(),
        );
        _textCtrl.clear();
        if (mounted) setState(() => _replyingTo = null);
      },
    );
  }

  Future<void> _pickPdf() async {
    final res = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    if (res == null || res.files.isEmpty) return;
    final f = res.files.first;
    final bytes = f.bytes;
    if (bytes == null) return;
    final url = await _repo.uploadGroupFile(bytes, f.name);
    if (url == null) return;
    await _repo.sendGroupMessage(
      groupId: widget.group.id,
      messageType: 'file',
      content: '📎 ${f.name}',
      fileUrl: url,
      fileName: f.name,
      replyToId: _replyingTo?['id']?.toString(),
    );
    setState(() => _replyingTo = null);
  }

  void _openActions(Map<String, dynamic> msg, bool isMe) {
    final pinned = msg['is_pinned'] == true;
    MessageInteractionSheet.show(
      context,
      title: widget.group.subject,
      onEmoji: (emoji) => _repo.toggleGroupMessageReaction(msg['id'].toString(), emoji),
      onReply: () => setState(() => _replyingTo = msg),
      onDelete: isMe ? () => _confirmDelete(msg['id'].toString()) : null,
      canDelete: isMe,
      onPin: () async {
        await _repo.setGroupMessagePinned(msg['id'].toString(), !pinned);
      },
      canPin: true,
      pinLabel: pinned ? 'Unpin' : 'Pin to top',
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final uid = Supabase.instance.client.auth.currentUser?.id;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(widget.group.subject, overflow: TextOverflow.ellipsis),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            size: 24,
          ),
          onPressed: () {
            if (Navigator.canPop(context)) {
              context.pop();
            } else {
              context.go('/dashboard');
            }
          },
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _repo.watchGroupMessages(widget.group.id),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Could not load chat. Run study_group_chat.sql in Supabase and set RLS policies.\n\n${snapshot.error}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                final messages = snapshot.data ?? [];
                final pinned = messages.where((m) => m['is_pinned'] == true).toList();
                final rest = messages.where((m) => m['is_pinned'] != true).toList();

                return ColoredBox(
                  color: theme.brightness == Brightness.light
                      ? theme.colorScheme.surfaceContainerLow
                      : theme.scaffoldBackgroundColor,
                  child: CustomScrollView(
                    controller: _scroll,
                    slivers: [
                      if (pinned.isNotEmpty)
                        SliverToBoxAdapter(
                          child: _PinnedStrip(pinned: pinned, theme: theme),
                        ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
                        sliver: SliverList(
                          delegate: SliverChildBuilderDelegate((context, index) {
                            final msg = rest[index];
                            final isMe = msg['sender_id'] == uid;
                            return _StudyMsgTile(
                              message: msg,
                              isMe: isMe,
                              theme: theme,
                              onSwipeReply: () {
                                HapticFeedback.lightImpact();
                                setState(() => _replyingTo = msg);
                              },
                              onLongPress: () => _openActions(msg, isMe),
                            );
                          }, childCount: rest.length),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          if (_replyingTo != null)
            Material(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.95),
              child: ListTile(
                dense: true,
                leading: Icon(Icons.reply_rounded, color: theme.colorScheme.primary),
                title: Text(
                  _replyingTo!['content']?.toString() ?? 'Message',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium,
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => setState(() => _replyingTo = null),
                ),
              ),
            ),
          SafeArea(
            top: false,
            child: Material(
              elevation: 6,
              color: theme.colorScheme.surface,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 6, 8, 10),
                child: Row(
                  children: [
                    IconButton(icon: const Icon(Icons.image_outlined), onPressed: _pickImage),
                    IconButton(icon: const Icon(Icons.picture_as_pdf_outlined), onPressed: _pickPdf),
                    Expanded(
                      child: TextField(
                        controller: _textCtrl,
                        minLines: 1,
                        maxLines: 4,
                        style: theme.textTheme.bodyLarge,
                        decoration: InputDecoration(
                          hintText: 'Message…',
                          filled: true,
                          fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                      ),
                    ),
                    IconButton.filled(onPressed: _sendText, icon: const Icon(Icons.send_rounded)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PinnedStrip extends StatelessWidget {
  const _PinnedStrip({required this.pinned, required this.theme});
  final List<Map<String, dynamic>> pinned;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(10, 8, 10, 4),
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.35)),
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.55),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.push_pin, size: 16, color: theme.colorScheme.primary),
                const SizedBox(width: 6),
                Text('Pinned', style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w800)),
              ],
            ),
            const SizedBox(height: 8),
            ...pinned.map((m) {
              final type = m['message_type']?.toString() ?? 'text';
              final preview = m['content']?.toString() ?? '';
              return Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Icon(
                      type == 'image' ? Icons.image : type == 'file' ? Icons.picture_as_pdf : Icons.short_text,
                      size: 18,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(preview, maxLines: 2, overflow: TextOverflow.ellipsis, style: theme.textTheme.bodySmall)),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _StudyMsgTile extends StatelessWidget {
  const _StudyMsgTile({required this.message, required this.isMe, required this.theme, required this.onSwipeReply, required this.onLongPress});
  final Map<String, dynamic> message;
  final bool isMe;
  final ThemeData theme;
  final VoidCallback onSwipeReply;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final type = message['message_type']?.toString() ?? 'text';
    final created = TimeFormatter.parseSupabaseTimestamp(message['created_at']);
    final reactions = Map<String, dynamic>.from(message['reactions'] ?? {});

    final bubbleColor = isMe ? theme.colorScheme.primaryContainer : theme.colorScheme.surfaceContainerHighest;
    final fg = isMe ? theme.colorScheme.onPrimaryContainer : theme.colorScheme.onSurface;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: BaseChatMessageShell(
          messageKey: Key(message['id'].toString()),
          maxWidthFactor: 0.82,
          onSwipeReply: onSwipeReply,
          onLongPress: onLongPress,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isMe ? 18 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 18),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isMe)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      message['sender_name']?.toString() ?? 'User',
                      style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.bold, letterSpacing: 0.2),
                    ),
                  ),
                if (type == 'image' && message['file_url'] != null)
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
                if (type == 'file' && message['file_url'] != null) ...[
                  Row(
                    children: [
                      Icon(Icons.attach_file, color: fg, size: 20),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          message['file_name']?.toString() ?? 'File',
                          style: theme.textTheme.bodyMedium?.copyWith(color: fg, fontWeight: FontWeight.w600),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                if (message['content'] != null && message['content'].toString().isNotEmpty)
                  Text(
                    message['content'].toString(),
                    style: theme.textTheme.bodyMedium?.copyWith(color: fg, height: 1.35),
                  ),
                if (created != null)
                  Text(
                    TimeFormatter.format(created),
                    style: theme.textTheme.labelSmall?.copyWith(color: fg.withValues(alpha: 0.65)),
                  ),
                if (reactions.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: reactions.entries.map((e) {
                        final n = (e.value is List) ? (e.value as List).length : 0;
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: theme.colorScheme.surface.withValues(alpha: 0.9), borderRadius: BorderRadius.circular(12)),
                          child: Text('${e.key} $n', style: const TextStyle(fontSize: 12)),
                        );
                      }).toList(),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
