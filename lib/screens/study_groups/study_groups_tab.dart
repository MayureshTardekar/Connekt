import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../theme/avatar_helper.dart';
import 'create_group_screen.dart';

class StudyGroupsTab extends StatefulWidget {
  const StudyGroupsTab({super.key});

  @override
  State<StudyGroupsTab> createState() => _StudyGroupsTabState();
}

class _StudyGroupsTabState extends State<StudyGroupsTab> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180, floating: false, pinned: true, backgroundColor: AppTheme.coral,
            leading: IconButton(
              icon: Container(padding: const EdgeInsets.all(6), decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle), child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20)),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(gradient: LinearGradient(colors: [Color(0xFFF43F5E), Color(0xFFE11D48), Color(0xFFBE123C)], begin: Alignment.topLeft, end: Alignment.bottomRight)),
                child: Stack(
                  children: [
                    Positioned(right: -20, bottom: -20, child: Icon(Icons.groups_3_rounded, size: 160, color: Colors.white.withValues(alpha: 0.06))),
                    Positioned(
                      left: 24, right: 24, bottom: 24,
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                        const Text('Study Groups', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: -0.5)),
                        const SizedBox(height: 6),
                        Text('Find your study tribe & learn together.', style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 14)),
                      ]),
                    ),
                  ],
                ),
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
              child: Column(children: [
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: AppTheme.softShadow),
                  child: Row(children: [_buildTabBtn('All Groups', 0), _buildTabBtn('My Groups', 1)]),
                ),
                const SizedBox(height: 20),
              ]),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                if (_selectedTab == 0) ...[
                  _buildGroupCard(context, subject: 'Advanced Calculus', description: 'Midterm prep — integration techniques & series.', creator: 'Jordan Davies', dateTime: 'Today, 4:00 PM', location: 'Library Room 302', memberCount: 3, maxMembers: 5, color: AppTheme.primary),
                  const SizedBox(height: 14),
                  _buildGroupCard(context, subject: 'Quantum Physics', description: 'Weekly session — wave mechanics & Schrödinger.', creator: 'Aisha Lindholm', dateTime: 'Tomorrow, 2:00 PM', location: 'Science Block Lab 4', memberCount: 5, maxMembers: 5, color: AppTheme.anonPurple),
                  const SizedBox(height: 14),
                  _buildGroupCard(context, subject: 'Data Structures', description: 'Trees, graphs & dynamic programming practice.', creator: 'Marcus Wright', dateTime: 'Wed, 6:00 PM', location: 'CS Lab 201', memberCount: 2, maxMembers: 6, color: AppTheme.emerald),
                  const SizedBox(height: 14),
                  _buildGroupCard(context, subject: 'Economics 101', description: 'Macro economics principles & case studies.', creator: 'Jamie Chen', dateTime: 'Thu, 3:00 PM', location: 'Student Center', memberCount: 4, maxMembers: 8, color: AppTheme.amber),
                ] else ...[
                  _buildGroupCard(context, subject: 'Advanced Calculus', description: 'Midterm prep — integration techniques & series.', creator: 'Jordan Davies', dateTime: 'Today, 4:00 PM', location: 'Library Room 302', memberCount: 3, maxMembers: 5, color: AppTheme.primary, isJoined: true),
                  const SizedBox(height: 14),
                  _buildGroupCard(context, subject: 'Data Structures', description: 'Trees, graphs & dynamic programming practice.', creator: 'Marcus Wright', dateTime: 'Wed, 6:00 PM', location: 'CS Lab 201', memberCount: 2, maxMembers: 6, color: AppTheme.emerald, isJoined: true),
                ],
                const SizedBox(height: 80),
              ]),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateGroupScreen())),
        backgroundColor: AppTheme.coral, elevation: 8,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text('Create', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
    );
  }

  Widget _buildTabBtn(String label, int index) {
    final isSelected = _selectedTab == index;
    return Expanded(child: GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(gradient: isSelected ? const LinearGradient(colors: [Color(0xFFF43F5E), Color(0xFFE11D48)]) : null, borderRadius: BorderRadius.circular(10)),
        child: Center(child: Text(label, style: TextStyle(color: isSelected ? Colors.white : AppTheme.textSecondary, fontWeight: FontWeight.w700, fontSize: 14))),
      ),
    ));
  }

  Widget _buildGroupCard(BuildContext context, {
    required String subject, required String description, required String creator,
    required String dateTime, required String location,
    required int memberCount, required int maxMembers, required Color color, bool isJoined = false,
  }) {
    final isFull = memberCount >= maxMembers;
    final spots = maxMembers - memberCount;
    final memberNames = ['Alex', 'Jordan', 'Aisha', 'Marcus', 'Jamie', 'Sam'];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: AppTheme.softShadow),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5), decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(8)), child: Text(subject, style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w800))),
          Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: isFull ? const Color(0xFFFEE2E2) : const Color(0xFFD1FAE5), borderRadius: BorderRadius.circular(6)), child: Text(isFull ? 'Full' : '$spots spots', style: TextStyle(color: isFull ? AppTheme.coral : AppTheme.emerald, fontSize: 11, fontWeight: FontWeight.w700))),
        ]),
        const SizedBox(height: 12),
        Text(description, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13, height: 1.4)),
        const SizedBox(height: 14),
        Row(children: [_buildMiniChip(Icons.calendar_today_rounded, dateTime), const SizedBox(width: 8), Expanded(child: _buildMiniChip(Icons.location_on_rounded, location))]),
        const SizedBox(height: 14),
        ClipRRect(borderRadius: BorderRadius.circular(3), child: LinearProgressIndicator(value: memberCount / maxMembers, backgroundColor: AppTheme.inputBg, color: isFull ? AppTheme.coral : color, minHeight: 5)),
        const SizedBox(height: 10),
        Row(children: [
          SizedBox(
            width: 48, height: 20,
            child: Stack(children: List.generate(memberCount.clamp(0, 3), (i) => Positioned(left: i * 14.0, child: CircleAvatar(radius: 10, backgroundColor: Colors.white, child: avatarWidget(memberNames[i], radius: 9))))),
          ),
          Text('$memberCount/$maxMembers', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.w600)),
          const Spacer(),
          GestureDetector(
            onTap: isFull && !isJoined ? null : () {},
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                gradient: isJoined ? const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]) : (isFull ? null : LinearGradient(colors: [color, color.withValues(alpha: 0.8)])),
                color: isFull && !isJoined ? AppTheme.inputBg : null,
                borderRadius: BorderRadius.circular(10),
                boxShadow: isFull && !isJoined ? [] : [BoxShadow(color: (isJoined ? AppTheme.emerald : color).withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 3))],
              ),
              child: Text(isJoined ? 'Joined ✓' : (isFull ? 'Full' : 'Join'), style: TextStyle(color: isFull && !isJoined ? AppTheme.textSecondary : Colors.white, fontWeight: FontWeight.w700, fontSize: 13)),
            ),
          ),
        ]),
      ]),
    );
  }

  Widget _buildMiniChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(color: AppTheme.inputBg, borderRadius: BorderRadius.circular(6)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 12, color: AppTheme.textSecondary),
        const SizedBox(width: 4),
        Flexible(child: Text(text, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.w600), overflow: TextOverflow.ellipsis)),
      ]),
    );
  }
}
