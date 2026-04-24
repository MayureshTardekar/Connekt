import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/models/academic_note.dart';
import '../../core/utils/time_formatter.dart';
import '../../core/providers/auth_provider.dart';
import '../../core/providers/campus_provider.dart';
import '../../core/routing/app_routes.dart';
import '../../core/widgets/app_states.dart';
import '../../core/widgets/notes_events_shimmer.dart';
import '../../theme/app_theme.dart';
import '../../theme/avatar_helper.dart';

class NotesTab extends ConsumerStatefulWidget {
  const NotesTab({super.key});

  @override
  ConsumerState<NotesTab> createState() => _NotesTabState();
}

class _NotesTabState extends ConsumerState<NotesTab> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final notesAsync = ref.watch(academicNotesProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return notesAsync.when(
      loading: () => buildNotesTabShimmer(context),
      error: (error, _) => Scaffold(
        body: Center(
          child: AppErrorState(
            message: error.toString(),
            onRetry: () => ref.invalidate(academicNotesProvider),
          ),
        ),
      ),
      data: (notes) {
        final categories = <String>{
          'All',
          ...notes
              .map((note) => note.category.trim())
              .where((it) => it.isNotEmpty),
        }.toList();
        final effectiveCategory = categories.contains(_selectedCategory)
            ? _selectedCategory
            : 'All';
        final query = _searchController.text.trim().toLowerCase();

        final filteredNotes = notes.where((note) {
          final matchesCategory =
              effectiveCategory == 'All' || note.category == effectiveCategory;
          final matchesSearch =
              query.isEmpty ||
              note.title.toLowerCase().contains(query) ||
              note.author.toLowerCase().contains(query) ||
              note.category.toLowerCase().contains(query) ||
              note.description.toLowerCase().contains(query);
          return matchesCategory && matchesSearch;
        }).toList();

        return Scaffold(
          body: CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 160,
                floating: false,
                pinned: true,
                backgroundColor: theme.scaffoldBackgroundColor,
                surfaceTintColor: Colors.transparent,
                flexibleSpace: FlexibleSpaceBar(
                  background: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 60, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.menu_book_rounded, color: theme.colorScheme.primary, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'NOTES LIBRARY',
                              style: TextStyle(
                                color: isDark ? Colors.white70 : Colors.black54,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Academic Notes',
                          style: theme.textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.8,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Premium repository of campus resources',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search_rounded),
                          suffixIcon: const Icon(Icons.tune_rounded), // Added filter icon
                          hintText: 'Search subjects or authors...',
                          filled: true,
                          fillColor: isDark 
                              ? const Color(0xFF1E1E1E) 
                              : const Color(0xFFF1F5F9),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      if (categories.length > 1) ...[
                        const SizedBox(height: 20),
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: categories.map((category) {
                              final isSelected = effectiveCategory == category;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(category),
                                  selected: isSelected,
                                  onSelected: (_) {
                                    setState(() => _selectedCategory = category);
                                  },
                                  showCheckmark: false,
                                  backgroundColor: Colors.transparent,
                                  selectedColor: theme.colorScheme.primary,
                                  labelStyle: TextStyle(
                                    color: isSelected 
                                      ? Colors.white 
                                      : theme.textTheme.bodyMedium?.color,
                                    fontWeight: isSelected 
                                      ? FontWeight.w600 
                                      : FontWeight.w500,
                                  ),
                                  side: BorderSide(
                                    color: isSelected 
                                      ? theme.colorScheme.primary 
                                      : theme.dividerColor,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Latest Uploads',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            '${filteredNotes.length} found',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              if (filteredNotes.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.search_off_rounded,
                          size: 64,
                          color: theme.dividerColor,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No notes found',
                          style: theme.textTheme.titleMedium,
                        ),
                      ],
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildNoteCard(filteredNotes[index]),
                      childCount: filteredNotes.length,
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 100)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNoteCard(AcademicNote note) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final accent = _categoryColor(note.category);
    final timeStr = TimeFormatter.format(note.createdAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161616) : Colors.white, // Darker background
        borderRadius: BorderRadius.circular(20),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => context.push(AppRoutes.noteDetail, extra: note),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left Document Image Placeholder
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF222222) : const Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(16),
                    image: const DecorationImage(
                      image: NetworkImage('https://images.unsplash.com/photo-1456513080510-7bf3a84b82f8?q=80&w=200'),
                      fit: BoxFit.cover,
                      opacity: 0.6,
                    ),
                  ),
                  child: Center(
                    child: Icon(Icons.description_rounded, color: isDark ? Colors.white70 : Colors.black54, size: 32),
                  ),
                ),
                const SizedBox(width: 16),
                
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: accent.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              note.category.toUpperCase(),
                              style: TextStyle(color: accent, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '•  $timeStr',
                            style: TextStyle(color: isDark ? Colors.white60 : Colors.black54, fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        note.title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          avatarWidget(
                            note.author,
                            radius: 8,
                            imageUrl: note.authorAvatar,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            note.author,
                            style: TextStyle(
                              color: isDark ? Colors.white70 : Colors.black87,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Right Download Icon
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: Icon(Icons.file_download_outlined, color: theme.colorScheme.primary),
                      onPressed: () async {
                        if (note.fileUrl == null) {
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No file associated with this note.')));
                          return;
                        }
                        final uri = Uri.parse(note.fileUrl!);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri, mode: LaunchMode.externalApplication);
                        } else {
                          if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open file.')));
                        }
                      },
                    ),
                    if (note.authorId == ref.read(currentUserProvider)?.id)
                      IconButton(
                        icon: const Icon(Icons.edit_rounded, size: 18, color: Colors.grey),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () => _showEditNoteDialog(note),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditNoteDialog(AcademicNote note) {
    final titleController = TextEditingController(text: note.title);
    final descController = TextEditingController(text: note.description);
    String selectedCategory = note.category;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Edit Note'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descController,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Description'),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    prefixIcon: Icon(Icons.category_rounded),
                  ),
                  items: ['Exam', 'Lecture', 'Assignment', 'Resource', 'General']
                      .toSet() 
                      .followedBy([selectedCategory]) // Ensure the current value is always in the list
                      .toSet() // Remove duplicates if selectedCategory was already in the list
                      .map((c) => DropdownMenuItem(
                            value: c,
                            child: Text(c.isEmpty ? 'General' : c),
                          ))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) {
                      setDialogState(() => selectedCategory = v);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Delete Note?'),
                    content: const Text('This will permanently remove the note and its file.'),
                    actions: [
                      TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                      TextButton(
                        onPressed: () => Navigator.pop(context, true), 
                        child: const Text('Delete', style: TextStyle(color: Colors.red)),
                      ),
                    ],
                  ),
                );

                if (confirmed == true) {
                  try {
                    await ref.read(notesRepositoryProvider).deleteNote(note.id);
                    if (context.mounted) {
                      Navigator.pop(context); // Close edit dialog
                      ref.invalidate(academicNotesProvider);
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                    }
                  }
                }
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await ref.read(campusRepositoryProvider).updateNote(
                    noteId: note.id,
                    title: titleController.text,
                    description: descController.text,
                    category: selectedCategory,
                  );
                  if (context.mounted) {
                    Navigator.pop(context);
                    ref.invalidate(academicNotesProvider);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Note updated!')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Error: $e')),
                    );
                  }
                }
              },
              child: const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  Color _categoryColor(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('math')) return const Color(0xFF2563EB);
    if (lower.contains('cs') || lower.contains('computer')) return const Color(0xFF7C3AED);
    if (lower.contains('physic')) return const Color(0xFFD97706);
    if (lower.contains('chem')) return const Color(0xFF059669);
    return AppTheme.primary;
  }
}
