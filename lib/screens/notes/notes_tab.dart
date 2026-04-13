import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../theme/avatar_helper.dart';
import 'upload_note_screen.dart';
import 'note_detail_screen.dart';

class NotesTab extends StatefulWidget {
  const NotesTab({super.key});

  @override
  State<NotesTab> createState() => _NotesTabState();
}

class _NotesTabState extends State<NotesTab> {
  int _selectedFilter = 0;
  final List<String> _filters = [
    'All',
    'Downloaded',
    'Bookmarks',
    'Math',
    'Physics',
    'CS',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            floating: false,
            pinned: true,
            backgroundColor: AppTheme.primary,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFF3B82F6),
                      Color(0xFF1D4ED8),
                      Color(0xFF1E40AF),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -30,
                      top: -20,
                      child: Icon(
                        Icons.auto_stories_rounded,
                        size: 180,
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                    Positioned(
                      left: 24,
                      right: 24,
                      bottom: 24,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Notes Sharing',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.5,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Access shared resources from the campus community.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(
                                      Icons.assignment_turned_in_rounded,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'Assignment Tracker',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
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
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: AppTheme.softShadow,
                    ),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search notes, subjects...',
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: AppTheme.textSecondary,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 40,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _filters.length,
                      itemBuilder: (context, index) {
                        final isSelected = _selectedFilter == index;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedFilter = index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(right: 10),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              gradient: isSelected
                                  ? AppTheme.primaryGradient
                                  : null,
                              color: isSelected ? null : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: isSelected
                                  ? null
                                  : Border.all(color: AppTheme.cardBorder),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: AppTheme.primary.withValues(
                                          alpha: 0.3,
                                        ),
                                        blurRadius: 8,
                                        offset: const Offset(0, 3),
                                      ),
                                    ]
                                  : [],
                            ),
                            child: Center(
                              child: Text(
                                _filters[index],
                                style: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : AppTheme.textSecondary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _buildNoteCard(
                  context,
                  subject: 'MATHEMATICS',
                  subjectColor: AppTheme.primary,
                  time: '12 min ago',
                  title: 'Advanced Vector Calculus: Week 4 Summary',
                  description:
                      'Comprehensive breakdown of Green\'s theorem with solved examples.',
                  author: 'Jordan Davies',
                  noteIcon: Icons.functions_rounded,
                  noteIconColors: const [Color(0xFF3B82F6), Color(0xFF1E40AF)],
                  fileSize: '4.2 MB',
                  downloads: 47,
                ),
                const SizedBox(height: 18),
                _buildNoteCard(
                  context,
                  subject: 'QUANTUM PHYSICS',
                  subjectColor: AppTheme.anonPurple,
                  time: '2 hours ago',
                  title: 'Particle Duality & Schrödinger\'s Equation',
                  description:
                      'Digital lecture notes covering core concepts of matter waves.',
                  author: 'Aisha Lindholm',
                  noteIcon: Icons.science_rounded,
                  noteIconColors: const [Color(0xFF7C3AED), Color(0xFF5B21B6)],
                  fileSize: '2.8 MB',
                  downloads: 23,
                ),
                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const UploadNoteScreen()),
        ),
        backgroundColor: AppTheme.primary,
        elevation: 8,
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ),
    );
  }

  Widget _buildNoteCard(
    BuildContext context, {
    required String subject,
    required Color subjectColor,
    required String time,
    required String title,
    required String description,
    required String author,
    required IconData noteIcon,
    required List<Color> noteIconColors,
    required String fileSize,
    required int downloads,
  }) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => NoteDetailScreen(
            title: title,
            subject: subject,
            subjectColor: subjectColor,
            author: author,
            downloads: downloads,
          ),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: AppTheme.softShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gradient header instead of network image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(22),
              ),
              child: Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: noteIconColors,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: -20,
                      bottom: -20,
                      child: Icon(
                        noteIcon,
                        size: 100,
                        color: Colors.white.withValues(alpha: 0.1),
                      ),
                    ),
                    Center(
                      child: Icon(noteIcon, size: 44, color: Colors.white),
                    ),
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          subject,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.picture_as_pdf_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              fileSize,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(fontSize: 17),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(fontSize: 13),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      avatarWidget(author, radius: 15),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              author,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            Text(
                              time,
                              style: const TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppTheme.inputBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.download_rounded,
                              size: 14,
                              color: AppTheme.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '$downloads',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.inputBg,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.bookmark_outline_rounded,
                          size: 16,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
