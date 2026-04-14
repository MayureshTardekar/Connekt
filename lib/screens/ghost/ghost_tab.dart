import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/repositories/auth_repository.dart';
import '../../core/theme/app_colors.dart';
import '../../core/providers/campus_provider.dart';
import '../../core/models/ghost_post.dart';

class GhostTab extends ConsumerStatefulWidget {
  const GhostTab({super.key});

  @override
  ConsumerState<GhostTab> createState() => _GhostTabState();
}

class _GhostTabState extends ConsumerState<GhostTab> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isShadowMode = true; // Default to anonymous

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      String? alias;
      if (_isShadowMode) {
        alias = AuthRepository().currentGhostAlias ?? 'Anon';
      } else {
        // Real Identity Mode: [Name] @ [Campus]
        final fullName = user.userMetadata?['full_name'] ?? user.userMetadata?['name'] ?? 'Connekt User';
        final campusData = ref.read(selectedCampusProvider);
        final campusName = campusData?['campuses']?['name'] ?? 'Global';
        alias = '$fullName @ $campusName';
      }

      final post = GhostPost(
        id: '', 
        text: text,
        mood: 'World Chat',
        createdAt: DateTime.now().toUtc(),
        authorId: user.id,
        authorAlias: alias,
      );

      _messageController.clear();
      await ref.read(ghostRepositoryProvider).createPost(post);
      
      // Auto scroll to bottom
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      debugPrint('Ghost Send Error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to send: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      resizeToAvoidBottomInset: true, // Fix for keyboard pushing UI
      body: Stack(
        children: [
          // Background Glow
          Positioned(
            top: -100,
            left: -100,
            child: Container(
              width: 400,
              height: 400,
              decoration: BoxDecoration(
                color: AppColors.ghostPrimary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                Expanded(
                  child: ref.watch(ghostPostsProvider).when(
                        data: (posts) {
                          if (posts.isEmpty) {
                            return Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.chat_bubble_outline_rounded,
                                      color: Colors.white24, size: 64),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'Welcome to World Chat!\nBe the first to speak.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.white54, fontSize: 13),
                                  ),
                                ],
                              ),
                            );
                          }

                          return ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                            reverse: true,
                            itemCount: posts.length,
                            itemBuilder: (context, index) {
                              return _buildChatBubble(posts[index]);
                            },
                          );
                        },
                        loading: () => const Center(
                          child: CircularProgressIndicator(
                              color: AppColors.ghostPrimary),
                        ),
                        error: (err, stack) => Center(
                          child: Text(
                            'Error: $err',
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ),
                ),
                _buildInputArea(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    final currentAlias = AuthRepository().currentGhostAlias;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF161129) : Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
                Text(
                  '🌎 World Chat',
                  style: TextStyle(
                      color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.textPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold),
                ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                        color: Colors.greenAccent, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  const Text('Refreshes daily at 12:00 AM UTC',
                      style: TextStyle(color: Colors.white38, fontSize: 11)),
                ],
              ),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {
              setState(() => _isShadowMode = !_isShadowMode);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(_isShadowMode ? 'Switched to Shadow Mode 👻' : 'Switched to Public Identity 🆔'),
                  duration: const Duration(seconds: 1),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: _isShadowMode ? AppColors.ghostPrimary : Colors.blueAccent,
                ),
              );
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _isShadowMode 
                    ? AppColors.ghostPrimary.withValues(alpha: 0.1) 
                    : Colors.blueAccent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: (_isShadowMode ? AppColors.ghostPrimary : Colors.blueAccent).withValues(alpha: 0.3)
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _isShadowMode ? Icons.masks_rounded : Icons.face_retouching_natural,
                    color: _isShadowMode ? AppColors.ghostPrimary : Colors.blueAccent,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isShadowMode ? 'Shadow' : 'Identity',
                    style: TextStyle(
                      color: _isShadowMode ? AppColors.ghostPrimary : Colors.blueAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white38, size: 20),
            onPressed: _showAliasDialog,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildChatBubble(GhostPost post) {
    final isMe =
        post.authorId == Supabase.instance.client.auth.currentUser?.id;
    final String displayName = post.authorAlias ??
        'Anon#${(post.authorId ?? 'anon').substring(0, 4).toUpperCase()}';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment:
            isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          if (!isMe)
            Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 4),
              child: Text(
                displayName,
                style: const TextStyle(color: Colors.white38, fontSize: 10),
              ),
            ),
          Container(
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isMe
                  ? AppColors.ghostPrimary
                  : (Theme.of(context).brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.05)),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(isMe ? 20 : 0),
                bottomRight: Radius.circular(isMe ? 0 : 20),
              ),
            ),
            child: Text(
              post.text,
              style: TextStyle(
                color: isMe ? Colors.white : (Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.textPrimary), 
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            DateFormat('HH:mm').format(post.createdAt),
            style: const TextStyle(color: Colors.white24, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF161129) : Theme.of(context).cardColor,
        border: Border(top: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.1))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.05) : Colors.black.withValues(alpha: 0.02),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Theme.of(context).dividerColor.withValues(alpha: 0.1)),
              ),
              child: TextField(
                style: TextStyle(
                  color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black, 
                  fontSize: 14,
                ),
                cursorColor: AppColors.ghostPrimary,
                decoration: const InputDecoration(
                  hintText: 'Say something anonymous...',
                  hintStyle: TextStyle(color: Colors.white24, fontSize: 13),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.ghostPrimary,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.ghostPrimary.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ],
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  void _showAliasDialog() {
    final TextEditingController aliasController = TextEditingController(
      text: AuthRepository().currentGhostAlias,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1F1B2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: const Text('World Chat Identity',
            style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Change your display name in world chat. Keep it clean!',
              style: TextStyle(color: Colors.white60, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: aliasController,
              autofocus: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'e.g. NeonGhost',
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.white38)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.ghostPrimary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () async {
              final result = await AuthRepository()
                  .updateGhostAlias(aliasController.text.trim());
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(result['message']),
                    backgroundColor:
                        result['success'] ? Colors.green : Colors.red,
                  ),
                );
                setState(() {});
              }

            },
            child:
                const Text('Save Alias', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
