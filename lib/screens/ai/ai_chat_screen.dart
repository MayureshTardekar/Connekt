import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/ai_provider.dart';

class AIChatScreen extends ConsumerStatefulWidget {
  const AIChatScreen({super.key});

  @override
  ConsumerState<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends ConsumerState<AIChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, String>> _messages = [
    {
      'role': 'ai',
      'text': 'Hello! I\'m your Connekt AI Assistant. I can help you summarize campus notes, find events, or just chat. How can I help you today?'
    }
  ];
  bool _isLoading = false;

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _isLoading = true;
    });
    _messageController.clear();

    try {
      final response = await ref.read(aiRepositoryProvider).getChatResponse(text);
      setState(() {
        _messages.add({'role': 'ai', 'text': response});
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add({'role': 'ai', 'text': 'Sorry, I encountered an error. Please check your API key.'});
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A), // Deep dark slate
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.cyan, Colors.blueAccent],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            const Text(
              'Connekt AI',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded, color: Colors.white60),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isAI = msg['role'] == 'ai';
                return _buildMessageBubble(msg['text']!, isAI);
              },
            ),
          ),
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.cyan),
                ),
              ),
            ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String text, bool isAI) {
    return Align(
      alignment: isAI ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: isAI ? const Color(0xFF1E293B) : Colors.cyan.withOpacity(0.15),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isAI ? 4 : 20),
            bottomRight: Radius.circular(isAI ? 20 : 4),
          ),
          border: isAI 
              ? Border.all(color: Colors.white.withOpacity(0.05))
              : Border.all(color: Colors.cyan.withOpacity(0.3)),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isAI ? Colors.white.withOpacity(0.9) : Colors.cyanAccent,
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Ask anything...',
                hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
                border: InputBorder.none,
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Colors.cyan, Colors.blueAccent],
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: IconButton(
              icon: const Icon(Icons.send_rounded, color: Colors.white),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}
