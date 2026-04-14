import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_theme.dart';
import '../../core/providers/ai_provider.dart';

class AIChatScreen extends ConsumerStatefulWidget {
  final String? initialPrompt;
  const AIChatScreen({super.key, this.initialPrompt});

  @override
  ConsumerState<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends ConsumerState<AIChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final List<Map<String, String>> _messages = [];
  bool _isLoading = false;
  DateTime? _lastInputTime;
  DateTime? _lastErrorTime;
  bool _showErrorBanner = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialPrompt != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _messageController.text = widget.initialPrompt!;
        _sendMessage();
      });
    }
  }

  Future<void> _sendMessage([String? predefinedText]) async {
    final text = predefinedText ?? _messageController.text.trim();
    if (text.isEmpty || _isLoading) return;

    // Spam filter: Block rapid user inputs within 2 seconds
    if (_lastInputTime != null && DateTime.now().difference(_lastInputTime!).inSeconds < 2) {
      return;
    }
    _lastInputTime = DateTime.now();

    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _isLoading = true;
      _showErrorBanner = false;
    });
    if (predefinedText == null) {
      _messageController.clear();
    }

    try {
      final response = await ref.read(aiRepositoryProvider).getChatResponse(text);
      if (!mounted) return;
      
      final isFailure = response.contains('Coffee break') || response.contains('super busy') || response.contains('overwhelmed');

      if (isFailure) {
        if (_lastErrorTime != null && DateTime.now().difference(_lastErrorTime!).inSeconds < 60) {
          // Already showed failure in <60s window. Show banner ONLY, no repeat bubble.
           setState(() {
              _isLoading = false;
              _showErrorBanner = true;
           });
           return;
        }
        _lastErrorTime = DateTime.now();
      }

      setState(() {
        _messages.add({'role': 'ai', 'text': response});
        if (isFailure) _showErrorBanner = true; // Still show banner if we showed the bubble
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _showErrorBanner = true; 
        if (_lastErrorTime == null || DateTime.now().difference(_lastErrorTime!).inSeconds > 60) {
          _messages.add({'role': 'ai', 'text': 'Oops, I encountered an error checking the campus intel.'});
          _lastErrorTime = DateTime.now();
        }
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF161A25), // Binance Dark Slate
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.auto_awesome, color: Color(0xFF9000FF), size: 20),
            const SizedBox(width: 8),
            const Text(
              'Connekt Ai',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ],
        ),
        actions: const [],
      ),
      body: Column(
        children: [
          if (_showErrorBanner)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: const Color(0xFF2B313F),
              width: double.infinity,
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Color(0xFFF0B90B), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'AI temporarily unavailable, use Notes/Event suggestions.',
                      style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => setState(() => _showErrorBanner = false),
                    child: Icon(Icons.close, color: Colors.white.withOpacity(0.5), size: 16),
                  )
                ],
              ),
            ),
          Expanded(
            child: _messages.isEmpty ? _buildSuggestionsArea() : _buildChatList(),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildSuggestionsArea() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Hi there, here's today's pick for you:",
            style: TextStyle(
              color: Color(0xFF9000FF), // Soft purple accent
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          _buildSuggestionCard(
            title: "Today's Campus News",
            subtitle: "Library hours extended. Upcoming sports meet. Registration deadline approaching...",
            icon: Icons.article_rounded,
            color: Colors.transparent,
            onTap: () => _sendMessage("What is today's campus news?"),
          ),
          _buildSuggestionCard(
            title: "Lost & Found Alerts",
            subtitle: "Check recent items found on campus",
            icon: Icons.notifications_active_rounded,
            color: const Color(0xFFFCD535),
            onTap: () => _sendMessage("Show me the latest lost and found items."),
          ),
          _buildSuggestionCard(
            title: "Campus Events Update",
            subtitle: "View latest technical and cultural events",
            icon: Icons.event_available_rounded,
            color: const Color(0xFFF0B90B),
            onTap: () => _sendMessage("What are the upcoming events on campus?"),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF2B313F),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            if (color != Colors.transparent)
              Container(
                margin: const EdgeInsets.only(right: 12),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: color.withOpacity(0.15), shape: BoxShape.circle),
                child: Icon(icon, color: color, size: 20),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Color(0xFF848E9C), fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF848E9C), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildChatList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length + (_isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _messages.length) {
          return _buildTypingIndicator();
        }
        final msg = _messages[index];
        final isAI = msg['role'] == 'ai';
        return _buildMessageBubble(msg['text']!, isAI);
      },
    );
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAIAvatar(isThinking: true),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text('Thought for a sec', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13)),
                  Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.5), size: 16),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: List.generate(3, (index) {
                  return Container(
                    margin: const EdgeInsets.only(right: 4),
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                  );
                }),
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAIAvatar({bool isThinking = false}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      // If thinking, simulate a small "look down" or shrink effect using scaling
      transform: isThinking ? (Matrix4.identity()..scale(0.9)) : Matrix4.identity(),
      transformAlignment: Alignment.center,
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: const Color(0xFF2B313F),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.auto_awesome, color: Color(0xFF9000FF), size: 18),
    );
  }

  Widget _buildMessageBubble(String text, bool isAI) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        mainAxisAlignment: isAI ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isAI) ...[
            _buildAIAvatar(),
            const SizedBox(width: 12),
          ],
          Flexible(
            child: Container(
              padding: isAI ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: isAI
                  ? null
                  : BoxDecoration(
                      color: const Color(0xFF2B313F),
                      borderRadius: BorderRadius.circular(16),
                    ),
              child: Text(
                text,
                style: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: const BoxDecoration(color: Color(0xFF161A25)),
      child: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF2B313F),
            borderRadius: BorderRadius.circular(24),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                  decoration: InputDecoration(
                    hintText: 'Ask Connekt Ai...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14),
                    border: InputBorder.none,
                    filled: false,
                    fillColor: Colors.transparent,
                    hoverColor: Colors.transparent,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 8),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              GestureDetector(
                onTap: _isLoading ? null : () => _sendMessage(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: _isLoading ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.1), shape: BoxShape.circle),
                  child: Icon(Icons.arrow_upward_rounded, color: _isLoading ? Colors.white.withOpacity(0.3) : Colors.white, size: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

