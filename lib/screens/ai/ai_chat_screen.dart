import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../core/providers/ai_provider.dart';

class AIChatScreen extends ConsumerStatefulWidget {
  final String? initialPrompt;
  final ScrollController? scrollController;

  const AIChatScreen({super.key, this.initialPrompt, this.scrollController});

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

  static final MarkdownStyleSheet _markdownStyle = MarkdownStyleSheet(
    p: const TextStyle(color: Colors.white, fontSize: 14, height: 1.5),
    strong: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
    listBullet: const TextStyle(color: Colors.white, fontSize: 14),
  );

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

    if (_lastInputTime != null &&
        DateTime.now().difference(_lastInputTime!).inSeconds < 2) {
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
      // Fetch actual campus data context to ground the AI's response in reality
      final campusContext = await ref.read(campusSummaryProvider.future);

      final response = await ref
          .read(aiRepositoryProvider)
          .getChatResponse(text, context: campusContext);
      if (!mounted) return;

      final isFailure =
          response.contains('Coffee break') ||
          response.contains('super busy') ||
          response.contains('overwhelmed');

      if (isFailure) {
        if (_lastErrorTime != null &&
            DateTime.now().difference(_lastErrorTime!).inSeconds < 60) {
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
        if (isFailure) _showErrorBanner = true;
        _isLoading = false;
      });

      // Save to history
      if (mounted) {
        ref.read(aiRepositoryProvider).addToHistory(text, response);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _showErrorBanner = true;
        if (_lastErrorTime == null ||
            DateTime.now().difference(_lastErrorTime!).inSeconds > 60) {
          _messages.add({
            'role': 'ai',
            'text': 'Oops, I encountered an error checking the campus intel.',
          });
          _lastErrorTime = DateTime.now();
        }
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Color(0xFF161A25),
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(
                      Icons.history_rounded,
                      color: Colors.white70,
                    ),
                    onPressed: _showHistorySheet,
                  ),
                  Row(
                    children: [
                      const Icon(
                        Icons.auto_awesome,
                        color: Color(0xFF9000FF),
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Connekt Ai',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white38),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            if (_showErrorBanner)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                color: const Color(0xFF2B313F),
                width: double.infinity,
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Color(0xFFF0B90B),
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'AI temporarily unavailable, use Notes/Event suggestions.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 13,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _showErrorBanner = false),
                      child: Icon(
                        Icons.close,
                        color: Colors.white.withValues(alpha: 0.5),
                        size: 16,
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(
              child: _messages.isEmpty
                  ? _buildSuggestionsArea()
                  : _buildChatList(),
            ),
            _buildInputArea(),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionsArea() {
    return SingleChildScrollView(
      controller: widget.scrollController, // Link to draggable sheet
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Hi there, here's today's pick for you:",
            style: TextStyle(
              color: Color(0xFF9000FF),
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          _buildSuggestionCard(
            title: "Summarize Campus Activities",
            subtitle:
                "Get a quick briefing on the latest events and news posted by students.",
            icon: Icons.auto_awesome_motion_rounded,
            color: const Color(0xFF9000FF),
            onTap: () => _sendMessage("Give me a summary of what's happening on campus based on recent posts."),
          ),
          _buildSuggestionCard(
            title: "Lost & Found Search",
            subtitle: "Looking for something? Ask AI to scan recent reports for you.",
            icon: Icons.search_rounded,
            color: const Color(0xFFFCD535),
            onTap: () =>
                _sendMessage("Are there any recent reports in Lost & Found?"),
          ),
          _buildSuggestionCard(
            title: "Academic Assistance",
            subtitle: "Need study notes or details about a course? I can help find them.",
            icon: Icons.menu_book_rounded,
            color: const Color(0xFF00D1FF),
            onTap: () =>
                _sendMessage("How can I find the best study notes for my courses?"),
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
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF848E9C),
                      fontSize: 13,
                    ),
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
      controller: widget.scrollController, // Link to draggable sheet
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
                  Text(
                    'Thought for a sec',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 13,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: Colors.white.withValues(alpha: 0.5),
                    size: 16,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Row(
                children: [
                  _TypingDot(delay: 0),
                  _TypingDot(delay: 1),
                  _TypingDot(delay: 2),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAIAvatar({bool isThinking = false}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 500),
      transform: isThinking
          ? Matrix4.diagonal3Values(0.9, 0.9, 1.0)
          : Matrix4.identity(),
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
        mainAxisAlignment: isAI
            ? MainAxisAlignment.start
            : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isAI) ...[_buildAIAvatar(), const SizedBox(width: 12)],
          Flexible(
            child: Container(
              padding: isAI
                  ? EdgeInsets.zero
                  : const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: isAI
                  ? null
                  : BoxDecoration(
                      color: const Color(0xFF2B313F),
                      borderRadius: BorderRadius.circular(16),
                    ),
              child: isAI
                  ? MarkdownBody(data: text, styleSheet: _markdownStyle)
                  : Text(
                      text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        height: 1.5,
                      ),
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
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.4),
                      fontSize: 14,
                    ),
                    border: InputBorder.none,
                    filled: false,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 15,
                      horizontal: 8,
                    ),
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              GestureDetector(
                onTap: _isLoading ? null : () => _sendMessage(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _isLoading
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.arrow_upward_rounded,
                    color: _isLoading
                        ? Colors.white.withValues(alpha: 0.3)
                        : Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showHistorySheet() {
    final history = ref.read(aiRepositoryProvider).getRecentHistory();

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1F242F),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Sessions (48h)',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${history.length} items',
                  style: const TextStyle(color: Colors.white38, fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 20),
            if (history.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 30.0),
                  child: Text(
                    'No recent chats in the last 48 hours.',
                    style: TextStyle(color: Colors.white24),
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  itemCount: history.length,

                  itemBuilder: (context, index) {
                    final session = history[index];
                    return ListTile(
                      onTap: () {
                        setState(() {
                          _messages.clear();
                          _messages.add({
                            'role': 'user',
                            'text': session['query'],
                          });
                          _messages.add({
                            'role': 'ai',
                            'text': session['response'],
                          });
                        });
                        Navigator.pop(context);
                      },
                      leading: const Icon(
                        Icons.chat_bubble_outline_rounded,
                        color: Color(0xFF9000FF),
                        size: 20,
                      ),
                      title: Text(
                        session['query'],
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                      subtitle: Text(
                        '${DateTime.now().difference(session['timestamp'] as DateTime).inHours}h ago',
                        style: const TextStyle(
                          color: Colors.white24,
                          fontSize: 11,
                        ),
                      ),
                      trailing: const Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: Colors.white12,
                        size: 14,
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TypingDot extends StatelessWidget {
  final int delay;
  const _TypingDot({required this.delay});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.3),
        shape: BoxShape.circle,
      ),
    );
  }
}
