import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/models/academic_note.dart';
import '../../core/providers/campus_provider.dart';
import '../../core/routing/app_routes.dart';
import '../../core/widgets/app_states.dart';
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

    return notesAsync.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
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
          ...notes.map((note) => note.category.trim()).where((it) => it.isNotEmpty),
        }.toList();
        final effectiveCategory =
            categories.contains(_selectedCategory) ? _selectedCategory : 'All';
        final query = _searchController.text.trim().toLowerCase();

        final filteredNotes = notes.where((note) {
          final matchesCategory =
              effectiveCategory == 'All' || note.category == effectiveCategory;
          final matchesSearch = query.isEmpty ||
              note.title.toLowerCase().contains(query) ||
              note.author.toLowerCase().contains(query) ||
              note.category.toLowerCase().contains(query) ||
              note.description.toLowerCase().contains(query);
          return matchesCategory && matchesSearch;
        }).toList();

        return Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Notes',
                            style: Theme.of(context).textTheme.displaySmall,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Search real uploads from your campus and share what is actually useful.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      onPressed: () => context.push(AppRoutes.noteUpload),
                      style: IconButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.surface,
                        side: BorderSide(color: Theme.of(context).dividerColor),
                      ),
                      icon: const Icon(Icons.upload_file_rounded),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search_rounded),
                    hintText: 'Search notes, authors, or subjects',
                  ),
                ),
                if (categories.length > 1) ...[
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 42,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (context, index) {
                        final category = categories[index];
                        final isSelected = effectiveCategory == category;
                        return ChoiceChip(
                          label: Text(category),
                          selected: isSelected,
                          onSelected: (_) {
                            setState(() => _selectedCategory = category);
                          },
                          backgroundColor:
                              Theme.of(context).colorScheme.surface,
                          selectedColor: Theme.of(
                            context,
                          ).colorScheme.primary.withValues(alpha: 0.12),
                          side: BorderSide(color: Theme.of(context).dividerColor),
                          labelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: isSelected
                                    ? Theme.of(context).colorScheme.primary
                                    : Theme.of(context).textTheme.bodySmall?.color,
                                fontWeight:
                                    isSelected ? FontWeight.w600 : FontWeight.w500,
                              ),
                        );
                      },
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemCount: categories.length,
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                Text(
                  '${filteredNotes.length} notes',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 14),
                if (filteredNotes.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: Theme.of(context).dividerColor),
                    ),
                    child: Text(
                      'No notes match your current search.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  )
                else
                  ...filteredNotes.map(_buildNoteCard),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNoteCard(AcademicNote note) {
    final theme = Theme.of(context);
    final accent = _categoryColor(note.category);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        onTap: () => context.push(AppRoutes.noteDetail, extra: note),
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: theme.dividerColor),
            boxShadow: AppTheme.softShadow,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(
                  Icons.description_rounded,
                  color: accent,
                  size: 26,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            note.category,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: accent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          DateFormat('dd MMM').format(note.createdAt),
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      note.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 16,
                      ),
                    ),
                    if (note.description.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        note.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        avatarWidget(note.author, radius: 10),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            note.author,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${note.pages} pages',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _categoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'mathematics':
      case 'math':
        return const Color(0xFF2563EB);
      case 'computer science':
      case 'cs':
        return const Color(0xFF7C3AED);
      case 'physics':
        return const Color(0xFFD97706);
      default:
        return AppTheme.primary;
    }
  }
}
