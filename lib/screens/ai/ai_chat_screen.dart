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
import '../../core/widgets/premium_background.dart';

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
  late final FocusNode _focusNode;
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
    _focusNode = FocusNode();
    _micPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _initSpeech();
    _focusNode.addListener(() {
      if (mounted) setState(() {});
    });
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
    _focusNode.dispose();
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
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;
    final surfaceColor = isDark ? const Color(0xFF18181B) : Colors.white;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: Colors.transparent,
      body: PremiumBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              // Top App Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Back Button
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: onSurface.withValues(alpha: 0.05),
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: onSurface.withValues(alpha: 0.1)),
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: Icon(Icons.arrow_back, color: onSurface, size: 20),
                        onPressed: _close,
                      ),
                    ),
                    // Title
                    Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF9047FF), Color(0xFF6B3DFF)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF9047FF)
                                    .withValues(alpha: 0.4),
                                blurRadius: 12,
                              ),
                            ],
                          ),
                          child: const Icon(Icons.auto_awesome,
                              color: Colors.white, size: 14),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Connekt AI',
                          style: TextStyle(
                            color: onSurface,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                    // History Button
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: onSurface.withValues(alpha: 0.05),
                        shape: BoxShape.circle,
                        border:
                            Border.all(color: onSurface.withValues(alpha: 0.1)),
                      ),
                      child: IconButton(
                        padding: EdgeInsets.zero,
                        icon: Icon(Icons.history_rounded,
                            color: onSurface, size: 20),
                        onPressed: _showHistorySheet,
                      ),
                    ),
                  ],
                ),
              ),
              if (_showErrorBanner)
                Material(
                  color: Colors.redAccent.withValues(alpha: 0.15),
                  child: Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline_rounded,
                            color: Colors.redAccent, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _bannerTextForDisplay(_bannerErrorText),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: onSurface, fontSize: 12),
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
                            color: theme.colorScheme.onSurface
                                .withValues(alpha: 0.45),
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
      ),
    );
  }

  Widget _buildSuggestionsArea(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    return SingleChildScrollView(
      controller: widget.scrollController,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // AI Online Indicator
          Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: const Color(0xFF00E676),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00E676).withValues(alpha: 0.5),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Text(
                'AI ONLINE',
                style: TextStyle(
                  color: Color(0xFF9F9FA9),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Greeting Text
          Text(
            'Hi there —',
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black87,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              height: 1.1,
              letterSpacing: -1,
            ),
          ),
          Text(
            'ask me anything.',
            style: TextStyle(
              color: isDark ? const Color(0xFF9F9FA9) : Colors.black54,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              height: 1.1,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 32),
        ],
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

  Widget _buildContextSyncIndicator(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildAIAvatar(theme, thinking: true),
          const SizedBox(width: 12),
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF6B3DFF),
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Gathering campus data…',
              style: TextStyle(
                color: Color(0xFF9F9FA9),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingIndicator(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final surfaceColor = isDark ? const Color(0xFF18181B) : Colors.white;
    final onSurface = theme.colorScheme.onSurface;
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
                color: surfaceColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: onSurface.withValues(alpha: 0.1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Thinking…',
                    style: TextStyle(
                      color: onSurface.withValues(alpha: 0.65),
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      transform: thinking
          ? Matrix4.diagonal3Values(0.92, 0.92, 1)
          : Matrix4.identity(),
      transformAlignment: Alignment.center,
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF9047FF), Color(0xFF6B3DFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF9047FF).withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.auto_awesome, color: Colors.white, size: 16),
    );
  }

  Widget _buildMessageBubble(ThemeData theme, String text, bool isAI) {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Row(
        mainAxisAlignment: isAI ? MainAxisAlignment.start : MainAxisAlignment.end,
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
                      gradient: const LinearGradient(
                        colors: [Color(0xFF9047FF), Color(0xFF6B3DFF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF9047FF).withValues(alpha: 0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
              child: isAI
                  ? MarkdownBody(
                      data: text, 
                      styleSheet: MarkdownStyleSheet(
                        p: TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontSize: 15,
                            height: 1.5),
                        strong: TextStyle(
                            color: theme.colorScheme.onSurface,
                            fontWeight: FontWeight.bold),
                        listBullet:
                            TextStyle(color: theme.colorScheme.onSurface),
                        code: TextStyle(
                          color: theme.brightness == Brightness.dark
                              ? const Color(0xFF00E676)
                              : const Color(0xFF00C853),
                          backgroundColor: theme.colorScheme.onSurface
                              .withValues(alpha: 0.1),
                          fontFamily: 'monospace',
                        ),
                      ),
                    )
                  : Text(
                      text,
                      style: const TextStyle(color: Colors.white, fontSize: 15, height: 1.5),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea(ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;
    final onSurface = theme.colorScheme.onSurface;
    final surfaceColor = isDark ? const Color(0xFF18181B) : Colors.white;
    final busy = _isLoading || _isLoadingContext;
    final sendLocked = busy || _blockSendUntilRetry;
    final isFocused = _focusNode.hasFocus;

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom > 0 ? 12 : 32,
        top: 12,
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            if (isFocused)
              BoxShadow(
                color: const Color(0xFF9047FF).withValues(alpha: 0.25),
                blurRadius: 20,
                spreadRadius: 2,
              ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(32),
          child: Container(
            padding: const EdgeInsets.all(1),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32),
              gradient: LinearGradient(
                colors: [
                  const Color(0xFF9047FF).withValues(alpha: 0.5),
                  const Color(0xFF6B3DFF).withValues(alpha: 0.2),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              decoration: BoxDecoration(
                color: surfaceColor.withValues(alpha: isDark ? 0.85 : 0.95),
                borderRadius: BorderRadius.circular(31),
                boxShadow: _focusNode.hasFocus
                    ? [
                        BoxShadow(
                          color: const Color(0xFF9047FF)
                              .withValues(alpha: isDark ? 0.25 : 0.15),
                          blurRadius: 20,
                          spreadRadius: 2,
                        )
                      ]
                    : [
                        BoxShadow(
                          color:
                              Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        )
                      ],
                border: Border.all(
                  color: _focusNode.hasFocus
                      ? const Color(0xFF9047FF).withValues(alpha: 0.4)
                      : onSurface.withValues(alpha: 0.08),
                  width: 1.5,
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Row(
                children: [
                  // Professional Voice Input Button
                  GestureDetector(
                    onTap: busy || !_speechReady ? null : _toggleMic,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: _isListening
                            ? Colors.redAccent.withValues(alpha: 0.15)
                            : (isDark
                                ? const Color(0xFF1E1B2E)
                                : theme.colorScheme.primary
                                    .withValues(alpha: 0.05)),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _isListening
                              ? Colors.redAccent.withValues(alpha: 0.3)
                              : (isDark
                                  ? Colors.white.withValues(alpha: 0.1)
                                  : theme.colorScheme.primary
                                      .withValues(alpha: 0.1)),
                        ),
                      ),
                      child: ScaleTransition(
                        scale: Tween<double>(begin: 1.0, end: 1.2).animate(
                          CurvedAnimation(
                              parent: _micPulseController,
                              curve: Curves.easeInOut),
                        ),
                        child: Icon(
                          _isListening
                              ? Icons.mic_rounded
                              : Icons.mic_none_rounded,
                          color: _isListening
                              ? Colors.redAccent
                              : (isDark
                                  ? Colors.white70
                                  : theme.colorScheme.primary),
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Floating Input Field
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: TextField(
                        controller: _messageController,
                        focusNode: _focusNode,
                        minLines: 1,
                        maxLines: 4,
                        textCapitalization: TextCapitalization.sentences,
                        style: TextStyle(
                          color: onSurface,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText:
                              _isListening ? 'Listening...' : 'Ask anything...',
                          hintStyle: TextStyle(
                            color: onSurface.withValues(alpha: 0.35),
                            fontSize: 15,
                          ),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // Send Button
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF9047FF), Color(0xFF6B3DFF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF9047FF).withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: IconButton(
                      onPressed: sendLocked ? null : () => _sendMessage(),
                      icon: const Icon(Icons.arrow_upward_rounded,
                          color: Colors.white, size: 24),
                    ),
                  ),
                ],
              ),
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
