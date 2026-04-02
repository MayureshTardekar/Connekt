import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../theme/avatar_helper.dart';

class ChatDetailScreen extends StatefulWidget {
  final String userName;
  final String userInitial;
  final Color avatarColor;

  const ChatDetailScreen({super.key, required this.userName, required this.userInitial, required this.avatarColor});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, dynamic>> _messages = [
    {'text': 'Hey! Did you get the notes from today\'s lecture?', 'isSent': false, 'time': '10:30 AM'},
    {'text': 'Yes! I\'ll share them in a bit. The professor covered a lot today.', 'isSent': true, 'time': '10:32 AM'},
    {'text': 'That would be amazing, thanks! 🙏', 'isSent': false, 'time': '10:33 AM'},
    {'text': 'Also, are you coming to the study group tomorrow?', 'isSent': false, 'time': '10:33 AM'},
    {'text': 'Definitely! Library Room 302 at 4 PM right?', 'isSent': true, 'time': '10:35 AM'},
    {'text': 'Yep, that\'s the one. See you there! 📚', 'isSent': false, 'time': '10:36 AM'},
  ];

  @override
  void dispose() { _messageController.dispose(); _scrollController.dispose(); super.dispose(); }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    setState(() { _messages.add({'text': _messageController.text.trim(), 'isSent': true, 'time': 'Just now'}); _messageController.clear(); });
    Future.delayed(const Duration(milliseconds: 100), () {
      _scrollController.animateTo(_scrollController.position.maxScrollExtent, duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F5F9),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimary), onPressed: () => Navigator.pop(context)),
        title: Row(
          children: [
            Stack(
              children: [
                avatarWidget(widget.userName, radius: 18),
                Positioned(bottom: 0, right: 0, child: Container(width: 10, height: 10, decoration: BoxDecoration(color: AppTheme.emerald, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 2)))),
              ],
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.userName, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16, fontWeight: FontWeight.w700)),
                const Text('Online now', style: TextStyle(color: AppTheme.emerald, fontSize: 12, fontWeight: FontWeight.w500)),
              ],
            ),
          ],
        ),
        actions: [
          Container(margin: const EdgeInsets.only(right: 8), padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppTheme.inputBg, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.videocam_rounded, color: AppTheme.textSecondary, size: 20)),
          Container(margin: const EdgeInsets.only(right: 16), padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: AppTheme.inputBg, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.call_rounded, color: AppTheme.textSecondary, size: 20)),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isSent = msg['isSent'] as bool;
                final showAvatar = !isSent && (index == 0 || (_messages[index - 1]['isSent'] as bool));
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    mainAxisAlignment: isSent ? MainAxisAlignment.end : MainAxisAlignment.start,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (!isSent)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: showAvatar ? avatarWidget(widget.userName, radius: 14) : const SizedBox(width: 28),
                        ),
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            gradient: isSent ? AppTheme.primaryGradient : null,
                            color: isSent ? null : Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(20), topRight: const Radius.circular(20),
                              bottomLeft: Radius.circular(isSent ? 20 : 6), bottomRight: Radius.circular(isSent ? 6 : 20),
                            ),
                            boxShadow: [BoxShadow(color: (isSent ? AppTheme.primary : Colors.black).withValues(alpha: 0.08), blurRadius: 8, offset: const Offset(0, 2))],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(msg['text'] as String, style: TextStyle(color: isSent ? Colors.white : AppTheme.textPrimary, fontSize: 15, height: 1.4)),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(msg['time'] as String, style: TextStyle(color: isSent ? Colors.white60 : AppTheme.textSecondary, fontSize: 10)),
                                  if (isSent) ...[const SizedBox(width: 4), Icon(Icons.done_all_rounded, size: 14, color: Colors.white.withValues(alpha: 0.7))],
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
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, -2))]),
            child: SafeArea(
              child: Row(
                children: [
                  Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: AppTheme.inputBg, borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.add_rounded, color: AppTheme.textSecondary, size: 22)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(color: AppTheme.inputBg, borderRadius: BorderRadius.circular(24)),
                      child: TextField(controller: _messageController, decoration: const InputDecoration(border: InputBorder.none, hintText: 'Type a message...', hintStyle: TextStyle(color: Color(0xFF94A3B8), fontSize: 14)), onSubmitted: (_) => _sendMessage()),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: _sendMessage,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(gradient: AppTheme.primaryGradient, borderRadius: BorderRadius.circular(14), boxShadow: [BoxShadow(color: AppTheme.primary.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))]),
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
