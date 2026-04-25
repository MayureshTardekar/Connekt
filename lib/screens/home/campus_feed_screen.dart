import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/providers/campus_provider.dart';
import '../../core/repositories/campus_repository.dart';
import '../../core/utils/time_formatter.dart';

final _campusFeedProvider =
    StreamProvider.family<List<Map<String, dynamic>>, String>((ref, campusId) {
  return CampusRepository().watchCampusFeedPosts(campusId);
});

class CampusFeedScreen extends ConsumerStatefulWidget {
  const CampusFeedScreen({super.key});

  @override
  ConsumerState<CampusFeedScreen> createState() => _CampusFeedScreenState();
}

class _CampusFeedScreenState extends ConsumerState<CampusFeedScreen> {
  final _repo = CampusRepository();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final campusMembership = ref.watch(selectedCampusProvider);
    final campusId = campusMembership?['campus_id'] as String?;
    final isAdmin = ref.watch(isCampusCreatorProvider);
    final campusName =
        campusMembership?['campuses']?['name'] as String? ?? 'Campus';

    if (campusId == null) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.photo_library_outlined,
                  size: 56, color: theme.colorScheme.primary.withValues(alpha: 0.5)),
              const SizedBox(height: 16),
              Text('Join a campus to see the feed',
                  style: theme.textTheme.bodyLarge),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: ref.watch(_campusFeedProvider(campusId)).when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(
              child: Text('Error loading feed: $e',
                  style: const TextStyle(color: Colors.red)),
            ),
            data: (posts) => RefreshIndicator(
              onRefresh: () async =>
                  ref.invalidate(_campusFeedProvider(campusId)),
              child: CustomScrollView(
                slivers: [
                  // ── App Bar ──────────────────────────────────────────────
                  SliverAppBar(
                    floating: true,
                    snap: true,
                    backgroundColor: theme.scaffoldBackgroundColor,
                    elevation: 0,
                    leading: IconButton(
                      icon: Icon(
                        Icons.arrow_back,
                        color: theme.colorScheme.onSurface,
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
                    title: Text(
                      '$campusName Feed',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    actions: [
                      IconButton(
                        icon: const Icon(Icons.add_photo_alternate_rounded),
                        tooltip: 'Share a moment',
                        onPressed: () => _showCreatePostSheet(
                            context, campusId),
                      ),
                    ],
                  ),

                  // ── Empty state ──────────────────────────────────────────
                  if (posts.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyFeedView(
                        onPost: () =>
                            _showCreatePostSheet(context, campusId),
                      ),
                    )
                  else
                    // ── Post list ────────────────────────────────────────
                    SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final post = posts[index];
                          return _FeedPostCard(
                            post: post,
                            isAdmin: isAdmin,
                            onDelete: isAdmin ||
                                    _isMyPost(post)
                                ? () async {
                                    await _repo
                                        .deleteFeedPost(post['id'] as String);
                                  }
                                : null,
                            onLike: () async {
                              await _repo.toggleFeedPostLike(
                                  post['id'] as String);
                              ref.invalidate(_campusFeedProvider(campusId));
                            },
                          );
                        },
                        childCount: posts.length,
                      ),
                    ),
                ],
              ),
            ),
          ),
      // FAB to post
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'feed_post_fab',
        onPressed: () => _showCreatePostSheet(context, campusId),
        icon: const Icon(Icons.add_photo_alternate_rounded),
        label: const Text('Share'),
      ),
    );
  }

  bool _isMyPost(Map<String, dynamic> post) {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    return post['author_id'] == userId;
  }

  void _showCreatePostSheet(BuildContext context, String campusId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CreatePostSheet(campusId: campusId, repo: _repo),
    );
  }
}

// ─── Create Post Sheet ────────────────────────────────────────────────────────

class _CreatePostSheet extends StatefulWidget {
  const _CreatePostSheet({required this.campusId, required this.repo});

  final String campusId;
  final CampusRepository repo;

  @override
  State<_CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<_CreatePostSheet> {
  final _captionCtrl = TextEditingController();
  Uint8List? _imageBytes;
  String? _imageExt;
  bool _uploading = false;
  final _picker = ImagePicker();

  @override
  void dispose() {
    _captionCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final file =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (file == null) return;

    final bytes = await file.readAsBytes();
    final ext = file.name.split('.').last.toLowerCase();
    setState(() {
      _imageBytes = bytes;
      _imageExt = ext;
    });
  }

  Future<void> _submit() async {
    if (_imageBytes == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image first')),
      );
      return;
    }
    setState(() => _uploading = true);
    try {
      final url = await widget.repo.uploadFeedPostImage(_imageBytes!, _imageExt ?? 'jpg');
      if (url == null) throw Exception('Failed to upload image');

      await widget.repo.createFeedPost(
        campusId: widget.campusId,
        imageUrl: url,
        caption: _captionCtrl.text.trim().isEmpty
            ? null
            : _captionCtrl.text.trim(),
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.dividerColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            Text(
              'Share a Moment',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 20),

            // Image picker
            GestureDetector(
              onTap: _pickImage,
              child: _imageBytes != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.memory(
                        _imageBytes!,
                        height: 240,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Container(
                      height: 180,
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: theme.dividerColor, style: BorderStyle.solid),
                        borderRadius: BorderRadius.circular(16),
                        color: theme.colorScheme.primary.withValues(alpha: 0.05),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined,
                              size: 48,
                              color: theme.colorScheme.primary.withValues(alpha: 0.5)),
                          const SizedBox(height: 8),
                          Text('Tap to select a photo',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.primary)),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: 16),

            // Caption
            TextField(
              controller: _captionCtrl,
              decoration: InputDecoration(
                hintText: 'Write a caption... (optional)',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              maxLines: 3,
              maxLength: 300,
            ),
            const SizedBox(height: 16),

            // Submit
            _uploading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton.icon(
                    onPressed: _submit,
                    icon: const Icon(Icons.send_rounded),
                    label: const Text('Post'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

// ─── Feed Post Card ────────────────────────────────────────────────────────────

class _FeedPostCard extends StatefulWidget {
  const _FeedPostCard({
    required this.post,
    required this.isAdmin,
    required this.onLike,
    this.onDelete,
  });

  final Map<String, dynamic> post;
  final bool isAdmin;
  final VoidCallback onLike;
  final VoidCallback? onDelete;

  @override
  State<_FeedPostCard> createState() => _FeedPostCardState();
}

class _FeedPostCardState extends State<_FeedPostCard> {
  bool _likedByMe = false;

  @override
  void initState() {
    super.initState();
    _checkLiked();
  }

  Future<void> _checkLiked() async {
    final liked =
        await CampusRepository().hasLikedFeedPost(widget.post['id'] as String);
    if (mounted) setState(() => _likedByMe = liked);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final post = widget.post;
    final imageUrl = post['image_url'] as String?;
    final caption = post['caption'] as String?;
    final authorName = post['author_name'] as String? ?? 'Student';
    final authorAvatar = post['author_avatar'] as String?;
    final likesCount = (post['likes_count'] as int?) ?? 0;
    final createdAt = post['created_at'] as String?;
    final timeAgo = createdAt != null
        ? TimeFormatter.format(DateTime.tryParse(createdAt) ?? DateTime.now())
        : '';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 8, 8),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: authorAvatar != null
                      ? CachedNetworkImageProvider(authorAvatar)
                      : null,
                  backgroundColor:
                      theme.colorScheme.primary.withValues(alpha: 0.2),
                  child: authorAvatar == null
                      ? Text(
                          authorName[0].toUpperCase(),
                          style: TextStyle(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w700),
                        )
                      : null,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(authorName,
                          style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w700)),
                      Text(timeAgo,
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.textTheme.bodySmall?.color
                                  ?.withValues(alpha: 0.6))),
                    ],
                  ),
                ),
                if (widget.onDelete != null)
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20),
                    color: Colors.red.shade300,
                    onPressed: () => _confirmDelete(context),
                  ),
              ],
            ),
          ),

          // ── Image ─────────────────────────────────────────────────────────
          if (imageUrl != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.zero),
              child: CachedNetworkImage(
                imageUrl: imageUrl,
                width: double.infinity,
                fit: BoxFit.cover,
                placeholder: (_, __) => Container(
                  height: 280,
                  color: theme.dividerColor.withValues(alpha: 0.3),
                  child: const Center(child: CircularProgressIndicator()),
                ),
                errorWidget: (_, __, ___) => Container(
                  height: 280,
                  color: theme.dividerColor.withValues(alpha: 0.2),
                  child: const Center(
                      child: Icon(Icons.broken_image_outlined, size: 48)),
                ),
              ),
            ),

          // ── Caption ────────────────────────────────────────────────────────
          if (caption != null && caption.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 4),
              child: RichText(
                text: TextSpan(
                  style: theme.textTheme.bodyMedium,
                  children: [
                    TextSpan(
                      text: '$authorName  ',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    TextSpan(text: caption),
                  ],
                ),
              ),
            ),

          // ── Actions ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 8),
            child: Row(
              children: [
                // Like
                IconButton(
                  icon: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      _likedByMe
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      key: ValueKey(_likedByMe),
                      color: _likedByMe ? Colors.red : null,
                    ),
                  ),
                  onPressed: () async {
                    setState(() => _likedByMe = !_likedByMe);
                    widget.onLike();
                  },
                ),
                Text(
                  '$likesCount',
                  style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext ctx) {
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: const Text('Delete Post?'),
        content: const Text('This will remove the post permanently.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.onDelete?.call();
            },
            child:
                const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// ─── Empty Feed View ──────────────────────────────────────────────────────────

class _EmptyFeedView extends StatelessWidget {
  const _EmptyFeedView({required this.onPost});

  final VoidCallback onPost;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.photo_library_outlined,
            size: 72,
            color: theme.colorScheme.primary.withValues(alpha: 0.35),
          ),
          const SizedBox(height: 16),
          Text('Nothing here yet',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            'Be the first to share a moment\nwith your campus!',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodySmall?.color,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: onPost,
            icon: const Icon(Icons.add_photo_alternate_outlined),
            label: const Text('Share a Photo'),
          ),
        ],
      ),
    );
  }
}

// ─── Note Viewer helper ───────────────────────────────────────────────────────
// Opens a note's file URL in the browser (no download required)

Future<void> launchNoteViewer(BuildContext context, String url) async {
  // For PDFs: use Google Docs Viewer for in-browser viewing
  String viewerUrl = url;
  if (url.toLowerCase().endsWith('.pdf')) {
    viewerUrl =
        'https://docs.google.com/gview?embedded=true&url=${Uri.encodeComponent(url)}';
  }

  final uri = Uri.parse(viewerUrl);
  if (await canLaunchUrl(uri)) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  } else if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not open file')),
    );
  }
}
