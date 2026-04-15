import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/models/academic_note.dart';
import '../../core/routing/app_routes.dart';
import '../../core/utils/ai_prompts.dart';
import '../../theme/app_theme.dart';

class NoteDetailScreen extends StatelessWidget {
  const NoteDetailScreen({
    super.key,
    required this.note,
  });

  final AcademicNote note;

  Color get _categoryColor {
    switch (note.category.toLowerCase()) {
      case 'mathematics':
      case 'math':
        return const Color(0xFF2563EB);
      case 'computer science':
      case 'cs':
        return const Color(0xFF7C3AED);
      case 'physics':
        return const Color(0xFFF59E0B);
      default:
        return AppTheme.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final fileUrl = note.fileUrl?.trim() ?? '';

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppTheme.cardBorder),
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: AppTheme.textPrimary,
              size: 20,
            ),
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    _categoryColor,
                    _categoryColor.withValues(alpha: 0.78),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      note.category,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    note.title,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Uploaded by ${note.author}',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('dd MMM yyyy, h:mm a').format(note.createdAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: Colors.white.withValues(alpha: 0.72),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _NoteInfoCard(
              title: 'About this note',
              color: theme.colorScheme.surface,
              showShadow: !isDark,
              child: Text(
                note.description.isNotEmpty
                    ? note.description
                    : 'No description was provided for this note.',
                style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
              ),
            ),
            const SizedBox(height: 16),
            _NoteInfoCard(
              title: 'Details',
              color: theme.colorScheme.surface,
              showShadow: !isDark,
              child: Column(
                children: [
                  _DetailRow(
                    icon: Icons.menu_book_rounded,
                    label: 'Pages',
                    value: '${note.pages}',
                  ),
                  const SizedBox(height: 12),
                  _DetailRow(
                    icon: Icons.link_rounded,
                    label: 'File link',
                    value: fileUrl.isNotEmpty ? 'Available' : 'Not attached',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (fileUrl.isNotEmpty)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: fileUrl));
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('File link copied.')),
                    );
                  },
                  icon: const Icon(Icons.copy_rounded),
                  label: const Text('Copy File Link'),
                ),
              ),
            if (fileUrl.isNotEmpty) const SizedBox(height: 16),
            Text(
              'Connekt AI Tools',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _AICardButton(
                    label: 'Summarize',
                    color: const Color(0xFF06B6D4),
                    icon: Icons.auto_awesome_rounded,
                    onTap: () => context.push(
                      AppRoutes.aiChat,
                      extra: AIPrompts.summarizeNote(note.title, note.category),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _AICardButton(
                    label: 'Generate Quiz',
                    color: const Color(0xFF8B5CF6),
                    icon: Icons.quiz_rounded,
                    onTap: () => context.push(
                      AppRoutes.aiChat,
                      extra: AIPrompts.generateQuiz(note.title, note.category),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _NoteInfoCard extends StatelessWidget {
  const _NoteInfoCard({
    required this.title,
    required this.child,
    required this.color,
    required this.showShadow,
  });

  final String title;
  final Widget child;
  final Color color;
  final bool showShadow;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: showShadow ? AppTheme.softShadow : const [],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
        ),
      ],
    );
  }
}

class _AICardButton extends StatelessWidget {
  const _AICardButton({
    required this.label,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.18)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 10),
            Text(
              label,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
