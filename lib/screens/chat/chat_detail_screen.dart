import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/app_states.dart';
import '../../core/providers/chat_provider.dart';
import '../../core/models/chat_conversation.dart';
import '../../core/models/chat_message.dart';
import '../../theme/avatar_helper.dart';
import '../../core/repositories/chat_repository.dart';

class ChatDetailScreen extends ConsumerStatefulWidget {
  final ChatConversation conversation;

  const ChatDetailScreen({super.key, required this.conversation});

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<ChatMessage> _localMessages = [];
  bool _hasLoadedInitialMessages = false;
  ChatMessage? _replyingTo;
  int _memberCount = 0;
  bool _isLoadingCount = true;

  @override
  void initState() {
    super.initState();
    _fetchMemberCount();
  }

  Future<void> _fetchMemberCount() async {
    final count = await ChatRepository().getMemberCount(widget.conversation.id);
    if (mounted) {
      setState(() {
        _memberCount = count;
        _isLoadingCount = false;
      });
    }
  }

  void _showCommunityInfo() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1B4B) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: Icon(Icons.groups_rounded, color: Colors.white),
                ),
                const SizedBox(width: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Campus Community',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '$_memberCount Active Members',
                      style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),
            const Text(
              'About this Community',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'This is the official space for everyone at your campus. Share updates, ask questions, and connect with fellow students.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    
    final user = Supabase.instance.client.auth.currentUser;
    final senderId = user?.id ?? '00000000-0000-0000-0000-000000000000';
    final senderName = user?.userMetadata?['full_name'] ?? user?.email?.split('@').first ?? 'User';

    final newMessage = ChatMessage(
      id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
      senderId: senderId,
      senderName: senderName,
      text: text,
      timestamp: DateTime.now(),
      isFromMe: true,
      isRead: false,
      replyToId: _replyingTo?.id,
      replyToText: _replyingTo?.text,
      replyToName: _replyingTo?.senderName,
    );

    // Optimistic update
    setState(() {
      _localMessages.add(newMessage);
      _messageController.clear();
      _replyingTo = null; // Clear reply after sending
    });

    // Send to Supabase
    ref.read(chatRepositoryProvider).sendMessage(
      widget.conversation.id,
      newMessage,
    );

    // Auto-scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _toggleReaction(String messageId, String emoji) {
    setState(() {
      // Find message in local list
      final localIdx = _localMessages.indexWhere((m) => m.id == messageId);
      if (localIdx != -1) {
        final msg = _localMessages[localIdx];
        final currentReactions = Map<String, int>.from(msg.reactions);
        if (currentReactions.containsKey(emoji) && currentReactions[emoji]! > 0) {
          currentReactions[emoji] = currentReactions[emoji]! - 1;
          if (currentReactions[emoji] == 0) currentReactions.remove(emoji);
        } else {
          currentReactions[emoji] = (currentReactions[emoji] ?? 0) + 1;
        }
        _localMessages[localIdx] = msg.copyWith(reactions: currentReactions);
      }
    });
  }

  void _showStickerPanel() {
    // Hide keyboard safely before showing the panel
    FocusScope.of(context).unfocus();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.45,
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Tabs for Stickers vs GIFs
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(
                    'Stickers',
                    style: AppTypography.heading3.copyWith(
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    'GIFs',
                    style: AppTypography.heading3.copyWith(
                      color: AppColors.textHint,
                    ),
                  ),
                  Text(
                    'Memes',
                    style: AppTypography.heading3.copyWith(
                      color: AppColors.textHint,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Dummy Grid for Stickers
              Expanded(
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: 16, // Dummy sticker count
                  itemBuilder: (context, index) {
                    final emojis = [
                      '🐶',
                      '🐱',
                      '🔥',
                      '🚀',
                      '🍔',
                      '🎉',
                      '🎸',
                      '😂',
                      '😎',
                      '💡',
                      '💯',
                      '🤔',
                      '🙌',
                      '👀',
                      '💖',
                      '💤',
                    ];
                    return GestureDetector(
                      onTap: () {
                        Navigator.pop(context); // Close panel
                        _messageController.text +=
                            emojis[index]; // Append sticker text (or send a real sticker graphic)
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.background,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          emojis[index],
                          style: const TextStyle(fontSize: 32),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showAttachmentPanel() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: const BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textHint.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildAttachOption(
                    Icons.image_rounded,
                    'Gallery',
                    Colors.purple,
                  ),
                  _buildAttachOption(
                    Icons.camera_alt_rounded,
                    'Camera',
                    Colors.blue,
                  ),
                  _buildAttachOption(
                    Icons.insert_drive_file_rounded,
                    'Document',
                    Colors.orange,
                  ),
                  _buildAttachOption(
                    Icons.location_on_rounded,
                    'Location',
                    Colors.green,
                  ),
                ],
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAttachOption(IconData icon, String label, Color color) {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 28),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Watch messages provider
    final messagesAsync = ref.watch(
      chatMessagesProvider(widget.conversation.id),
    );

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Stack(
              children: [
                avatarWidget(widget.conversation.participantName, radius: 18),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.success,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.conversation.participantName,
                  style: AppTypography.heading3.copyWith(
                    fontSize: 16,
                    color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                Text(
                  _isLoadingCount ? 'Typing...' : '$_memberCount members • Community',
                  style: const TextStyle(
                    color: AppColors.success,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            onPressed: _showCommunityInfo,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              ),
              error: (err, stack) => AppErrorState(
                message: err.toString(),
                onRetry: () => ref.invalidate(chatMessagesProvider(widget.conversation.id)),
              ),
              data: (serverMessages) {
                // Force messages to come alive by merging server data with local optimistic updates
                final List<ChatMessage> allMessages = [...serverMessages];
                final userId = Supabase.instance.client.auth.currentUser?.id;

                for (final local in _localMessages) {
                  final isAlreadyInServer = allMessages.any((m) => 
                    m.id == local.id || 
                    (m.text == local.text && m.timestamp.difference(local.timestamp).inSeconds.abs() < 5)
                  );
                  if (!isAlreadyInServer) {
                    allMessages.add(local);
                  }
                }
                
                // Sort by timestamp and reverse for reverse ListView
                allMessages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
                final displayMessages = allMessages.reversed.toList();

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                  itemCount: displayMessages.length,
                  itemBuilder: (context, index) {
                    final msg = displayMessages[index];
                    final isSent = msg.isFromMe || 
                                   msg.senderId == 'me' || 
                                   msg.senderId == '00000000-0000-0000-0000-000000000000' || 
                                   (userId != null && msg.senderId == userId);
                    final isCommunity = widget.conversation.participantId == 'community';
                    final showAvatar =
                        !isSent &&
                        (index == 0 || (displayMessages[index - 1].senderId != msg.senderId));
                    final String timeFormat =
                        '${msg.timestamp.hour}:${msg.timestamp.minute.toString().padLeft(2, "0")}';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        mainAxisAlignment: isSent
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (!isSent)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: showAvatar
                                  ? avatarWidget(
                                      isCommunity ? (msg.senderName ?? 'User') : widget.conversation.participantName,
                                      radius: 14,
                                    )
                                  : const SizedBox(width: 28),
                            ),
                          Flexible(
                            child: Column(
                              crossAxisAlignment: isSent ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                              children: [
                                if (isCommunity && !isSent && showAvatar)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 4, bottom: 4),
                                    child: Text(
                                      msg.senderName ?? 'User',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.primary.withValues(alpha: 0.8),
                                      ),
                                    ),
                                  ),
                                GestureDetector(
                                  onDoubleTap: () =>
                                      _toggleReaction(msg.id, '👍'), // Quick Like
                              onLongPress: () {
                                // Simple bottom sheet reaction picker mock
                                showModalBottomSheet(
                                  context: context,
                                  backgroundColor: Colors.transparent,
                                  builder: (_) => Container(
                                    margin: const EdgeInsets.all(20),
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1B4B) : AppColors.surface,
                                      borderRadius: BorderRadius.circular(30),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        for (final r in [
                                          '👍',
                                          '👎',
                                          '😂',
                                          '🔥',
                                          '❤️',
                                        ])
                                          GestureDetector(
                                            onTap: () {
                                              Navigator.pop(context);
                                              _toggleReaction(msg.id, r);
                                            },
                                            child: Text(
                                              r,
                                              style: const TextStyle(
                                                fontSize: 32,
                                              ),
                                            ),
                                          ),
                                        const VerticalDivider(color: Colors.white24, indent: 8, endIndent: 8),
                                        IconButton(
                                          icon: const Icon(Icons.reply_rounded, color: Colors.white, size: 28),
                                          onPressed: () {
                                            Navigator.pop(context);
                                            setState(() {
                                              _replyingTo = msg;
                                            });
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                              child: Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    margin: EdgeInsets.only(
                                      bottom: msg.reactions.isNotEmpty ? 12 : 0,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isSent
                                          ? AppColors.primary
                                          : (Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1B4B) : AppColors.surface),
                                      borderRadius: BorderRadius.only(
                                        topLeft: const Radius.circular(20),
                                        topRight: const Radius.circular(20),
                                        bottomLeft: Radius.circular(
                                          isSent ? 20 : 6,
                                        ),
                                        bottomRight: Radius.circular(
                                          isSent ? 6 : 20,
                                        ),
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color:
                                              (isSent
                                                      ? AppColors.primary
                                                      : Colors.black)
                                                  .withValues(alpha: 0.08),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        if (msg.replyToId != null)
                                          Container(
                                            margin: const EdgeInsets.only(bottom: 8),
                                            padding: const EdgeInsets.all(8),
                                            width: double.infinity,
                                            decoration: BoxDecoration(
                                              color: (isSent ? Colors.black : AppColors.primary).withValues(alpha: 0.1),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border(
                                                left: BorderSide(
                                                  color: isSent ? Colors.white : AppColors.primary,
                                                  width: 3,
                                                ),
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  msg.replyToName ?? 'User',
                                                  style: TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 11,
                                                    color: isSent ? Colors.white : AppColors.primary,
                                                  ),
                                                ),
                                                Text(
                                                  msg.replyToText ?? '',
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: isSent ? Colors.white70 : AppColors.textSecondary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        if (msg.sharedCardType ==
                                                SharedCardType.note &&
                                            msg.sharedData != null) ...[
                                          Container(
                                            margin: const EdgeInsets.only(
                                              bottom: 8,
                                            ),
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: isSent
                                                  ? Colors.white.withValues(
                                                      alpha: 0.15,
                                                    )
                                                  : AppColors.primary
                                                        .withValues(alpha: 0.05),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: isSent
                                                    ? Colors.white.withValues(
                                                        alpha: 0.2,
                                                      )
                                                    : AppColors.primary
                                                          .withValues(alpha: 0.2),
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.stretch,
                                              children: [
                                                Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                            8,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: isSent
                                                            ? Colors.white
                                                            : AppColors.primary,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              8,
                                                            ),
                                                      ),
                                                      child: Icon(
                                                        Icons
                                                            .picture_as_pdf_rounded,
                                                        color: isSent
                                                            ? AppColors.primary
                                                            : Colors.white,
                                                        size: 20,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Flexible(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            msg.sharedData!['title'],
                                                            style: TextStyle(
                                                              color: isSent
                                                                  ? Colors.white
                                                                  : (Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.textPrimary),
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                            ),
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                          ),
                                                          const SizedBox(
                                                            height: 2,
                                                          ),
                                                          Text(
                                                            '${msg.sharedData!['pages']} Pages • ${msg.sharedData!['author']}',
                                                            style: TextStyle(
                                                              color: isSent
                                                                  ? Colors
                                                                        .white70
                                                                  : AppColors
                                                                        .textSecondary,
                                                              fontSize: 11,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 12),
                                                GestureDetector(
                                                  onTap: () {
                                                    ScaffoldMessenger.of(
                                                      context,
                                                    ).showSnackBar(
                                                      const SnackBar(
                                                        content: Text(
                                                          'Opening Note module...',
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                  child: Container(
                                                    padding:
                                                        const EdgeInsets.symmetric(
                                                          vertical: 8,
                                                        ),
                                                    alignment: Alignment.center,
                                                    decoration: BoxDecoration(
                                                      color: isSent
                                                          ? Colors.white
                                                          : AppColors.primary,
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                            8,
                                                          ),
                                                    ),
                                                    child: Text(
                                                      'Open Note',
                                                      style: TextStyle(
                                                        color: isSent
                                                            ? AppColors.primary
                                                            : Colors.white,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                        // EVENT SHARED CARD
                                        if (msg.sharedCardType ==
                                                SharedCardType.event &&
                                            msg.sharedData != null) ...[
                                          Container(
                                            margin: const EdgeInsets.only(
                                              bottom: 8,
                                            ),
                                            padding: const EdgeInsets.all(12),
                                            decoration: BoxDecoration(
                                              color: isSent
                                                  ? Colors.white.withValues(
                                                      alpha: 0.15,
                                                    )
                                                  : AppColors.accent
                                                        .withValues(alpha: 0.1),
                                              borderRadius:
                                                  BorderRadius.circular(12),
                                              border: Border.all(
                                                color: isSent
                                                    ? Colors.white.withValues(
                                                        alpha: 0.2,
                                                      )
                                                    : AppColors.accent
                                                          .withValues(alpha: 0.3),
                                              ),
                                            ),
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.stretch,
                                              children: [
                                                Row(
                                                  children: [
                                                    Container(
                                                      padding:
                                                          const EdgeInsets.all(
                                                            10,
                                                          ),
                                                      decoration: BoxDecoration(
                                                        color: isSent
                                                            ? Colors.white
                                                            : AppColors.accent,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                              10,
                                                            ),
                                                      ),
                                                      child: Icon(
                                                        Icons.event_rounded,
                                                        color: isSent
                                                            ? AppColors.accent
                                                            : Colors.white,
                                                        size: 24,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 12),
                                                    Expanded(
                                                      child: Column(
                                                        crossAxisAlignment:
                                                            CrossAxisAlignment
                                                                .start,
                                                        children: [
                                                          Text(
                                                            msg.sharedData!['title'],
                                                            style: TextStyle(
                                                              color: isSent
                                                                  ? Colors.white
                                                                  : AppColors
                                                                        .textPrimary,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              fontSize: 14,
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            height: 2,
                                                          ),
                                                          Text(
                                                            '${msg.sharedData!['date']} • ${msg.sharedData!['location']}',
                                                            style: TextStyle(
                                                              color: isSent
                                                                  ? Colors
                                                                        .white70
                                                                  : AppColors
                                                                        .textSecondary,
                                                              fontSize: 11,
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 12),
                                                Row(
                                                  children: [
                                                    Text(
                                                      '🔥 ${msg.sharedData!['attendees']} Going',
                                                      style: TextStyle(
                                                        color: isSent
                                                            ? Colors.white
                                                            : AppColors.accent,
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                      ),
                                                    ),
                                                    const Spacer(),
                                                    GestureDetector(
                                                      onTap: () {
                                                        ScaffoldMessenger.of(
                                                          context,
                                                        ).showSnackBar(
                                                          const SnackBar(
                                                            content: Text(
                                                              'RSVP marked as Going!',
                                                            ),
                                                          ),
                                                        );
                                                      },
                                                      child: Container(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 16,
                                                              vertical: 6,
                                                            ),
                                                        decoration: BoxDecoration(
                                                          color: isSent
                                                              ? Colors.white
                                                              : AppColors.accent,
                                                          borderRadius:
                                                              BorderRadius.circular(
                                                                20,
                                                              ),
                                                        ),
                                                        child: Text(
                                                          'RSVP',
                                                          style: TextStyle(
                                                            color: isSent
                                                                ? AppColors.accent
                                                                : Colors.white,
                                                            fontWeight:
                                                                FontWeight.bold,
                                                            fontSize: 12,
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                        Text(
                                          msg.text,
                                          style: TextStyle(
                                            color: isSent
                                                ? Colors.white
                                                : AppColors.textPrimary,
                                            fontSize: 15,
                                            height: 1.4,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              timeFormat,
                                              style: TextStyle(
                                                color: isSent
                                                    ? Colors.white60
                                                    : AppColors.textHint,
                                                fontSize: 10,
                                              ),
                                            ),
                                            if (isSent) ...[
                                              const SizedBox(width: 4),
                                              Icon(
                                                msg.isRead
                                                    ? Icons.done_all_rounded
                                                    : Icons.check_rounded,
                                                size: 14,
                                                color: msg.isRead
                                                    ? AppColors.accent
                                                    : Colors.white.withValues(alpha: 
                                                        0.7,
                                                      ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  // Reaction Badge rendering mapped correctly
                                  if (msg.reactions.isNotEmpty)
                                    Positioned(
                                      bottom: 0,
                                      right: isSent ? 10 : null,
                                      left: isSent ? null : 10,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withValues(alpha: 
                                                0.05,
                                              ),
                                              blurRadius: 4,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                        ),
                                        child: Row(
                                          children: msg.reactions.entries
                                              .map(
                                                (e) => Padding(
                                                  padding:
                                                      const EdgeInsets.symmetric(
                                                        horizontal: 2.0,
                                                      ),
                                                  child: Text(
                                                    '${e.key} ${e.value}',
                                                    style: const TextStyle(
                                                      fontSize: 10,
                                                    ),
                                                  ),
                                                ),
                                              )
                                              .toList(),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),

          // Chat Input Component
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1E1B4B) : AppColors.surface,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.2 : 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_replyingTo != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    color: Theme.of(context).brightness == Brightness.dark
                        ? const Color(0xFF1E1B4B).withValues(alpha: 0.8)
                        : Colors.grey[100],
                    child: Row(
                      children: [
                        const Icon(Icons.reply_rounded,
                            color: AppColors.primary, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _replyingTo!.senderName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: AppColors.primary),
                              ),
                              Text(
                                _replyingTo!.text,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 12, color: AppColors.textSecondary),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded, size: 20),
                          onPressed: () => setState(() => _replyingTo = null),
                        ),
                      ],
                    ),
                  ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                children: [
                  GestureDetector(
                    onTap: _showAttachmentPanel,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : AppColors.background,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.add_rounded,
                        color: AppColors.textSecondary,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).brightness == Brightness.dark ? Colors.white10 : AppColors.background,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _messageController,
                              style: TextStyle(
                                color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
                              ),
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Type a message...',
                                hintStyle: TextStyle(
                                  color: AppColors.textHint,
                                  fontSize: 14,
                                ),
                              ),
                              onSubmitted: (_) => _sendMessage(),
                            ),
                          ),
                          GestureDetector(
                            onTap: _showStickerPanel,
                            child: const Icon(
                              Icons.emoji_emotions_outlined,
                              color: AppColors.textHint,
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  ],
),
);
  }
}
