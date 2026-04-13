import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/providers/chat_provider.dart';
import '../../core/models/chat_conversation.dart';
import '../../core/models/chat_message.dart';
import '../../theme/avatar_helper.dart';

class ChatDetailScreen extends ConsumerStatefulWidget {
  final ChatConversation conversation;

  const ChatDetailScreen({super.key, required this.conversation});

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<ChatMessage> _localMessages = [];
  bool _hasLoadedInitialMessages = false;

  @override
  void dispose() { 
    _messageController.dispose(); 
    _scrollController.dispose(); 
    super.dispose(); 
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    setState(() { 
      _localMessages.add(ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: 'me',
        senderName: 'Me',
        text: _messageController.text.trim(),
        timestamp: DateTime.now(),
        isFromMe: true,
        isRead: false,
      )); 
      _messageController.clear(); 
    });
    
    // Auto-scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
            _scrollController.position.maxScrollExtent, 
            duration: const Duration(milliseconds: 300), 
            curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Watch messages provider
    final messagesAsync = ref.watch(chatMessagesProvider(widget.conversation.id));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: AppColors.textPrimary), 
            onPressed: () => Navigator.pop(context)),
        title: Row(
          children: [
            Stack(
              children: [
                avatarWidget(widget.conversation.participantName, radius: 18),
                Positioned(
                    bottom: 0, right: 0, 
                    child: Container(
                        width: 10, height: 10, 
                        decoration: BoxDecoration(
                            color: AppColors.success, 
                            shape: BoxShape.circle, 
                            border: Border.all(color: Colors.white, width: 2)))),
              ],
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.conversation.participantName, style: AppTypography.heading3.copyWith(fontSize: 16)),
                const Text('Online', style: TextStyle(color: AppColors.success, fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ),
        actions: [
          Container(
              margin: const EdgeInsets.only(right: 8), 
              padding: const EdgeInsets.all(8), 
              decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)), 
              child: const Icon(Icons.videocam_rounded, color: AppColors.textSecondary, size: 20)),
          Container(
              margin: const EdgeInsets.only(right: 16), 
              padding: const EdgeInsets.all(8), 
              decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)), 
              child: const Icon(Icons.call_rounded, color: AppColors.textSecondary, size: 20)),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: messagesAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (err, stack) => Center(child: Text('Error: $err')),
              data: (serverMessages) {
                // Populate local state once to allow injecting new mock messages in the view directly
                if (!_hasLoadedInitialMessages) {
                  _localMessages = List.from(serverMessages);
                  // We defer the boolean switch to avoid setState during build
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if(mounted) {
                      setState(() {
                         _hasLoadedInitialMessages = true;
                      });
                      // Scroll to bottom immediately upon loading
                       if (_scrollController.hasClients) {
                          _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
                       }
                    }
                  });
                }
                
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  itemCount: _localMessages.length,
                  itemBuilder: (context, index) {
                    final msg = _localMessages[index];
                    final isSent = msg.isFromMe;
                    final showAvatar = !isSent && (index == 0 || (_localMessages[index - 1].isFromMe));
                    final String timeFormat = '${msg.timestamp.hour}:${msg.timestamp.minute.toString().padLeft(2, "0")}';

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        mainAxisAlignment: isSent ? MainAxisAlignment.end : MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (!isSent)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: showAvatar ? avatarWidget(widget.conversation.participantName, radius: 14) : const SizedBox(width: 28),
                            ),
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              decoration: BoxDecoration(
                                color: isSent ? AppColors.primary : AppColors.surface,
                                borderRadius: BorderRadius.only(
                                  topLeft: const Radius.circular(20), topRight: const Radius.circular(20),
                                  bottomLeft: Radius.circular(isSent ? 20 : 6), bottomRight: Radius.circular(isSent ? 6 : 20),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                      color: (isSent ? AppColors.primary : Colors.black).withOpacity(0.08), 
                                      blurRadius: 8, 
                                      offset: const Offset(0, 2))
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(msg.text, style: TextStyle(color: isSent ? Colors.white : AppColors.textPrimary, fontSize: 15, height: 1.4)),
                                  const SizedBox(height: 4),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(timeFormat, style: TextStyle(color: isSent ? Colors.white60 : AppColors.textHint, fontSize: 10)),
                                      if (isSent) ...[
                                          const SizedBox(width: 4), 
                                          Icon(
                                              msg.isRead ? Icons.done_all_rounded : Icons.check_rounded, 
                                              size: 14, 
                                              color: msg.isRead ? AppColors.secondary : Colors.white.withOpacity(0.7)
                                          )
                                      ],
                                    ],
                                  ),
                                ],
                              ),
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
                color: AppColors.surface, 
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, -2))
                ]
            ),
            child: SafeArea(
              child: Row(
                children: [
                   // Placeholder piece for future expressive actions (Phase 2 Additions)
                  Container(
                      padding: const EdgeInsets.all(10), 
                      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(12)), 
                      child: const Icon(Icons.add_rounded, color: AppColors.textSecondary, size: 22)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(color: AppColors.background, borderRadius: BorderRadius.circular(24)),
                      child: TextField(
                          controller: _messageController, 
                          decoration: const InputDecoration(
                              border: InputBorder.none, 
                              hintText: 'Type a message...', 
                              hintStyle: TextStyle(color: AppColors.textHint, fontSize: 14)), 
                          onSubmitted: (_) => _sendMessage()),
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
                              BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))
                          ]),
                      child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
