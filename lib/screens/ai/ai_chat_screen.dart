import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../core/providers/ai_provider.dart';
import '../../core/services/ai_context_bridge.dart';

class AIChatScreen extends ConsumerStatefulWidget {
  final String? initialPrompt;
  final ScrollController? scrollController;

  const AIChatScreen({super.key, this.initialPrompt, this.scrollController});

  @override
  ConsumerState<AIChatScreen> createState() => _AIChatScreenState();
}

class _AIChatScreenState extends ConsumerState<AIChatScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final stt.SpeechToText _speech = stt.SpeechToText();
  final List<Map<String, String>> _messages = [];
  /// Supabase + local campus context (loadAiPromptContext) — runs before getChatResponse.
  bool _isLoadingContext = false;
  /// LLM request in flight.
  bool _isLoading = false;
  DateTime? _lastErrorTime;
  bool _showErrorBanner = false;
  bool _speechReady = false;
  bool _isListening = false;
  late final AnimationController _micPulseController;
  /// Shown in the top banner for debugging (e.g. CORS, network).
  String? _bannerErrorText;
  /// After a failed Gemini call, block sending until the user taps Retry (no auto re-fire).
  bool _blockSendUntilRetry = false;

  /// Debug-friendly: show server/repo text as-is (e.g. `Error: 429`).
  String _bannerTextForDisplay(String? raw) {
    if (raw == null || raw.isEmpty) return 'Unknown error';
    return raw.length > 320 ? '${raw.substring(0, 320)}…' : raw;
  }

  MarkdownStyleSheet _markdownStyle(ThemeData theme) {
    final base = theme.textTheme.bodyMedium ??
        TextStyle(color: theme.colorScheme.onSurface, fontSize: 14);
    return MarkdownStyleSheet(
      p: base.copyWith(height: 1.5),
      strong: base.copyWith(fontWeight: FontWeight.bold),
      listBullet: base,
      code: base.copyWith(
        fontFamily: 'monospace',
        backgroundColor: theme.colorScheme.surfaceContainerHighest,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _micPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _initSpeech();
    if (widget.initialPrompt != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _messageController.text = widget.initialPrompt!;
        _sendMessage();
      });
    }
  }

  Future<void> _initSpeech() async {
    if (kIsWeb) return;
    try {
      final ok = await _speech.initialize(
        onError: (e) => debugPrint('Speech error: $e'),
        onStatus: (s) {
          if (s == 'done' || s == 'notListening') {
            _applyListening(false);
          }
        },
      );
      if (mounted) setState(() => _speechReady = ok);
    } catch (e) {
      debugPrint('Speech init failed: $e');
    }
  }

  @override
  void dispose() {
    _micPulseController.dispose();
    _speech.stop();
    _messageController.dispose();
    super.dispose();
  }

  void _applyListening(bool listening) {
    if (!mounted) return;
    setState(() => _isListening = listening);
    if (listening) {
      _micPulseController.repeat(reverse: true);
    } else {
      _micPulseController.stop();
      _micPulseController.reset();
    }
  }

  void _tryAgainAfterError() {
    final repo = ref.read(aiRepositoryProvider);
    repo.clearSessionHistory();
    repo.resetGeminiCooldown();
    setState(() {
      _messages.clear();
      _showErrorBanner = false;
      _lastErrorTime = null;
      _bannerErrorText = null;
      _blockSendUntilRetry = false;
    });
  }

  /// Single-tap toggle: start / stop listening; pulse on mic only.
  Future<void> _toggleMic() async {
    if (kIsWeb) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Voice input is available on iOS and Android.'),
          ),
        );
      }
      return;
    }
    if (!_speechReady || _isLoading || _isLoadingContext) return;

    if (_isListening) {
      await _speech.stop();
      _applyListening(false);
      return;
    }

    HapticFeedback.lightImpact();
    _applyListening(true);
    await _speech.listen(
      onResult: (res) {
        if (!mounted) return;
        final t = res.recognizedWords;
        setState(() {
          _messageController.value = TextEditingValue(
            text: t,
            selection: TextSelection.collapsed(offset: t.length),
          );
        });
      },
      listenFor: const Duration(seconds: 60),
      pauseFor: const Duration(seconds: 4),
      listenOptions: stt.SpeechListenOptions(
        partialResults: true,
        cancelOnError: true,
        listenMode: stt.ListenMode.dictation,
        autoPunctuation: true,
      ),
    );
  }

  Future<void> _sendMessage([String? predefinedText]) async {
    final text = predefinedText ?? _messageController.text.trim();
    if (text.isEmpty || _isLoading || _isLoadingContext) {
      return;
    }
    if (_blockSendUntilRetry) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tap Retry on the banner to try again.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _isLoadingContext = true;
      _isLoading = false;
      _showErrorBanner = false;
      _bannerErrorText = null;
    });
    if (predefinedText == null) {
      _messageController.clear();
    }

    try {
      // Campus "brain": always load Supabase/local context before the LLM call.
      final liveContext = await loadAiPromptContext(ref);
      if (!mounted) return;
      setState(() {
        _isLoadingContext = false;
        _isLoading = true;
      });

      final response = await ref
          .read(aiRepositoryProvider)
          .getChatResponse(text, context: liveContext);
      if (!mounted) return;

      final lower = response.toLowerCase().trim();
      final isFailure = lower.startsWith('error:') ||
          lower.contains('coffee break') ||
          lower.contains('super busy') ||
          lower.contains('overwhelmed') ||
          lower.contains("isn't set up") ||
          lower.contains('needs a gemini key') ||
          lower.contains('could not get an answer') ||
          lower.contains('could not reach') ||
          lower.contains('could not complete') ||
          lower.contains("didn't work") ||
          lower.contains("isn't available") ||
          lower.contains('something went wrong on our side');

      if (isFailure) {
        if (_lastErrorTime != null &&
            DateTime.now().difference(_lastErrorTime!).inSeconds < 60) {
          setState(() {
            _isLoadingContext = false;
            _isLoading = false;
            _showErrorBanner = true;
            _blockSendUntilRetry = true;
            _bannerErrorText = response.length > 400
                ? '${response.substring(0, 400)}…'
                : response;
          });
          return;
        }
        _lastErrorTime = DateTime.now();
      }

      setState(() {
        _messages.add({'role': 'ai', 'text': response});
        if (isFailure) {
          _showErrorBanner = true;
          _blockSendUntilRetry = true;
          _bannerErrorText = response.length > 400
              ? '${response.substring(0, 400)}…'
              : response;
        } else {
          _blockSendUntilRetry = false;
        }
        _isLoadingContext = false;
        _isLoading = false;
      });

      if (mounted) {
        ref.read(aiRepositoryProvider).addToHistory(text, response);
      }
    } catch (e, st) {
      debugPrint('AIChatScreen: request failed: $e');
      debugPrint('$st');
      if (!mounted) return;
      setState(() {
        _showErrorBanner = true;
        _blockSendUntilRetry = true;
        _bannerErrorText = e.toString();
        if (_lastErrorTime == null ||
            DateTime.now().difference(_lastErrorTime!).inSeconds > 60) {
          _messages.add({
            'role': 'ai',
            'text': 'Error: $e',
          });
          _lastErrorTime = DateTime.now();
        }
        _isLoadingContext = false;
        _isLoading = false;
      });
    }
  }

  void _close() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.go('/dashboard');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.history_rounded, color: cs.onSurface),
          onPressed: _showHistorySheet,
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_awesome, color: cs.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              'Connekt AI',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.close_rounded, color: cs.onSurface.withValues(alpha: 0.7)),
            onPressed: _close,
          ),
        ],
      ),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
                if (widget.scrollController == null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 4),
                    child: Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: cs.onSurface.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                if (_showErrorBanner)
                  Material(
                    color: cs.surfaceContainerHighest.withValues(alpha: 0.95),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: cs.tertiary,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _bannerTextForDisplay(_bannerErrorText),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: cs.onSurface,
                                height: 1.2,
                              ),
                            ),
                          ),
                          TextButton(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 0,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: _tryAgainAfterError,
                            child: const Text('Retry'),
                          ),
                          IconButton(
                            visualDensity: VisualDensity.compact,
                            icon: Icon(
                              Icons.close,
                              size: 18,
                              color: cs.onSurface.withValues(alpha: 0.45),
                            ),
                            onPressed: () => setState(() {
                              _showErrorBanner = false;
                              _bannerErrorText = null;
                            }),
                          ),
                        ],
                      ),
                    ),
                  ),
                Expanded(
                  child: _messages.isEmpty
                      ? _buildSuggestionsArea(theme)
                      : _buildChatList(theme),
                ),
            _buildInputArea(theme),
          ],
        ),
      ),
    );
  }

  Widget _buildSuggestionsArea(ThemeData theme) {
    final cs = theme.colorScheme;
    return SingleChildScrollView(
      controller: widget.scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Hi there — pick a starter or use the mic:",
            style: theme.textTheme.titleMedium?.copyWith(
              color: cs.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 24),
          _buildSuggestionCard(
            theme: theme,
            title: 'Summarize campus activity',
            subtitle:
                'Briefing from live notes, events, lost & found, and communities.',
            icon: Icons.auto_awesome_motion_rounded,
            accent: cs.primary,
            onTap: () => _sendMessage(
              "Summarize what's happening on my campus using the data you have.",
            ),
          ),
          _buildSuggestionCard(
            theme: theme,
            title: 'Lost & Found',
            subtitle: 'Ask about phones, wallets, or anything reported missing.',
            icon: Icons.search_rounded,
            accent: cs.tertiary,
            onTap: () => _sendMessage(
              'Are there any recent lost or found reports, especially phones?',
            ),
          ),
          _buildSuggestionCard(
            theme: theme,
            title: 'Communities',
            subtitle: 'What groups exist and which are public?',
            icon: Icons.groups_rounded,
            accent: cs.secondary,
            onTap: () => _sendMessage(
              'What communities are listed for my campus, and which are private?',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestionCard({
    required ThemeData theme,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accent,
    required VoidCallback onTap,
  }) {
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: accent, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          color: cs.onSurface,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: cs.onSurface.withValues(alpha: 0.75),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right, color: cs.onSurface.withValues(alpha: 0.4)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChatList(ThemeData theme) {
    final hasTail = _isLoadingContext || _isLoading;
    return ListView.builder(
      controller: widget.scrollController,
      reverse: true,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      padding: const EdgeInsets.all(16),
      itemCount: _messages.length + (hasTail ? 1 : 0),
      itemBuilder: (context, index) {
        if (hasTail && index == 0) {
          if (_isLoadingContext) {
            return _buildContextSyncIndicator(theme);
          }
          return _buildTypingIndicator(theme);
        }
        final offset = hasTail ? 1 : 0;
        final msgIndex = _messages.length - 1 - (index - offset);
        if (msgIndex < 0 || msgIndex >= _messages.length) {
          return const SizedBox.shrink();
        }
        final msg = _messages[msgIndex];
        final isAI = msg['role'] == 'ai';
        return _buildMessageBubble(theme, msg['text']!, isAI);
      },
    );
  }

  /// Shown while loadAiPromptContext (Supabase + local providers) runs.
  Widget _buildContextSyncIndicator(ThemeData theme) {
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildAIAvatar(theme, thinking: true),
          const SizedBox(width: 12),
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: cs.primary,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Gathering campus data…',
              style: theme.textTheme.bodySmall?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(ThemeData theme) {
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildAIAvatar(theme, thinking: true),
          const SizedBox(width: 12),
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: cs.outline.withValues(alpha: 0.12),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Thinking…',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: cs.onSurface.withValues(alpha: 0.65),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 10),
                  _AiThinkingTypingDots(theme: theme),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAIAvatar(ThemeData theme, {bool thinking = false}) {
    final cs = theme.colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      transform: thinking
          ? Matrix4.diagonal3Values(0.92, 0.92, 1)
          : Matrix4.identity(),
      transformAlignment: Alignment.center,
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(Icons.auto_awesome, color: cs.primary, size: 18),
    );
  }

  Widget _buildMessageBubble(ThemeData theme, String text, bool isAI) {
    final cs = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Row(
        mainAxisAlignment:
            isAI ? MainAxisAlignment.start : MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isAI) ...[_buildAIAvatar(theme), const SizedBox(width: 12)],
          Flexible(
            child: Container(
              padding: isAI
                  ? EdgeInsets.zero
                  : const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: isAI
                  ? null
                  : BoxDecoration(
                      color: cs.primary,
                      borderRadius: BorderRadius.circular(16),
                    ),
              child: isAI
                  ? MarkdownBody(data: text, styleSheet: _markdownStyle(theme))
                  : Text(
                      text,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: cs.onPrimary,
                        height: 1.5,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(ThemeData theme) {
    final cs = theme.colorScheme;
    final fill = cs.surfaceContainerHighest.withValues(alpha: 0.55);
    final busy = _isLoading || _isLoadingContext;
    final sendLocked = busy || _blockSendUntilRetry;
    return Material(
      color: theme.scaffoldBackgroundColor,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        child: Material(
            color: fill,
            elevation: 0,
            shadowColor: Colors.transparent,
            surfaceTintColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(26),
              side: BorderSide(color: cs.outline.withValues(alpha: 0.12)),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(4, 2, 4, 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (!kIsWeb)
                    Padding(
                      padding: const EdgeInsets.only(left: 2, bottom: 4),
                      child: ScaleTransition(
                        scale: Tween<double>(begin: 1.0, end: 1.12).animate(
                          CurvedAnimation(
                            parent: _micPulseController,
                            curve: Curves.easeInOut,
                          ),
                        ),
                        child: IconButton(
                          onPressed: busy || !_speechReady ? null : _toggleMic,
                          icon: Icon(
                            _isListening
                                ? Icons.mic_rounded
                                : Icons.mic_none_rounded,
                            color: !_speechReady
                                ? cs.onSurface.withValues(alpha: 0.35)
                                : (_isListening
                                    ? Colors.redAccent
                                    : cs.primary),
                            size: 26,
                          ),
                          tooltip: _isListening
                              ? 'Stop listening'
                              : 'Start voice input',
                        ),
                      ),
                    ),
                  Expanded(
                    child: Theme(
                      data: theme.copyWith(
                        inputDecorationTheme: const InputDecorationTheme(
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          filled: false,
                        ),
                      ),
                      child: TextField(
                        controller: _messageController,
                        minLines: 1,
                        maxLines: 3,
                        textCapitalization: TextCapitalization.sentences,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: cs.onSurface,
                        ),
                        decoration: InputDecoration(
                          hintText: _isListening
                              ? 'Listening... Speak now'
                              : 'Message… (tap mic to speak)',
                          hintStyle: theme.textTheme.bodyMedium?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.45),
                          ),
                          filled: false,
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          errorBorder: InputBorder.none,
                          focusedErrorBorder: InputBorder.none,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 12,
                          ),
                        ),
                        scrollPadding: const EdgeInsets.only(bottom: 32),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 2, bottom: 2),
                    child: IconButton.filled(
                      onPressed: sendLocked ? null : () => _sendMessage(),
                      style: IconButton.styleFrom(
                        backgroundColor: cs.primary,
                        foregroundColor: cs.onPrimary,
                        disabledBackgroundColor: cs.surfaceContainerHighest,
                        disabledForegroundColor: cs.onSurface.withValues(alpha: 0.35),
                      ),
                      icon: const Icon(Icons.send_rounded, size: 22),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
    );
  }

  void _showHistorySheet() {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final history = ref.read(aiRepositoryProvider).getRecentHistory();

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: cs.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.55,
          minChildSize: 0.35,
          maxChildSize: 0.9,
          builder: (ctx, scrollController) {
            return Material(
              color: cs.surface,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: Column(
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: cs.onSurface.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Recent (48h)',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: cs.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${history.length}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: cs.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: history.isEmpty
                        ? Center(
                            child: Text(
                              'No recent chats.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: cs.onSurface.withValues(alpha: 0.5),
                              ),
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            itemCount: history.length,
                            itemBuilder: (context, index) {
                              final session = history[index];
                              return ListTile(
                                onTap: () {
                                  setState(() {
                                    _messages.clear();
                                    _messages.add({
                                      'role': 'user',
                                      'text': session['query'] as String,
                                    });
                                    _messages.add({
                                      'role': 'ai',
                                      'text': session['response'] as String,
                                    });
                                  });
                                  Navigator.pop(ctx);
                                },
                                leading: Icon(Icons.chat_bubble_outline_rounded, color: cs.primary),
                                title: Text(
                                  session['query'] as String,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(color: cs.onSurface),
                                ),
                                subtitle: Text(
                                  '${DateTime.now().difference(session['timestamp'] as DateTime).inHours}h ago',
                                  style: TextStyle(
                                    color: cs.onSurface.withValues(alpha: 0.55),
                                    fontSize: 12,
                                  ),
                                ),
                                trailing: Icon(Icons.chevron_right, color: cs.onSurface.withValues(alpha: 0.35)),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/// Staggered bounce “typing” dots for the Gemini thinking state.
class _AiThinkingTypingDots extends StatefulWidget {
  const _AiThinkingTypingDots({required this.theme});

  final ThemeData theme;

  @override
  State<_AiThinkingTypingDots> createState() => _AiThinkingTypingDotsState();
}

class _AiThinkingTypingDotsState extends State<_AiThinkingTypingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = widget.theme.colorScheme;
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final phase = _c.value * 2 * math.pi + i * 0.9;
            final bounce = (math.sin(phase) + 1) / 2;
            final dy = -5.0 * bounce;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Transform.translate(
                offset: Offset(0, dy),
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Color.lerp(
                      cs.onSurface.withValues(alpha: 0.35),
                      cs.primary.withValues(alpha: 0.95),
                      bounce,
                    ),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
