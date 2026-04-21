import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
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
                expandedHeight: 180,
                floating: false,
                pinned: true,
                backgroundColor: theme.scaffoldBackgroundColor,
                surfaceTintColor: Colors.transparent,
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      Positioned(
                        top: -50,
                        right: -50,
                        child: Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: theme.colorScheme.primary.withValues(alpha: 0.08),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 80, 24, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Academic Notes',
                              style: theme.textTheme.displaySmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.8,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Premium repository of your campus resources.',
                              style: theme.textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                actions: [
                  Container(
                    margin: const EdgeInsets.only(right: 16),
                    child: IconButton(
                      onPressed: () => context.push(AppRoutes.noteUpload),
                      style: IconButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                      ),
                      icon: const Icon(Icons.add_rounded),
                    ),
                  ),
                ],
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
                          hintText: 'Search subjects or authors...',
                          fillColor: isDark 
                              ? const Color(0xFF1E232E) 
                              : const Color(0xFFF1F5F9),
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

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E232E) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF2B313D) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.push(AppRoutes.noteDetail, extra: note),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [accent, accent.withValues(alpha: 0.7)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.description_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  note.title,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  note.category,
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: accent,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            TimeFormatter.format(note.createdAt),
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                      if (note.description.trim().isNotEmpty) ...[
                        const SizedBox(height: 12),
                        Text(
                          note.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 13,
                            color: isDark ? Colors.white70 : Colors.black87,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.black26 : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            avatarWidget(
                              note.author,
                              radius: 10,
                              imageUrl: note.authorAvatar,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                note.author,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? Colors.white60 : Colors.black54,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Edit button for author
                if (note.authorId == ref.read(currentUserProvider)?.id)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: IconButton(
                      onPressed: () => _showEditNoteDialog(note),
                      style: IconButton.styleFrom(
                        backgroundColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.8),
                        padding: const EdgeInsets.all(8),
                      ),
                      icon: Icon(
                        Icons.edit_rounded,
                        size: 18,
                        color: theme.colorScheme.primary,
                      ),
                    ),
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
