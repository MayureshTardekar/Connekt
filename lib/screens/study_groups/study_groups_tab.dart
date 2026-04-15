import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/models/study_group.dart';
import '../../core/providers/campus_provider.dart';
import '../../core/repositories/study_groups_repository.dart';
import '../../core/routing/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../theme/avatar_helper.dart';

class StudyGroupsTab extends ConsumerStatefulWidget {
  const StudyGroupsTab({super.key});

  @override
  ConsumerState<StudyGroupsTab> createState() => _StudyGroupsTabState();
}

class _StudyGroupsTabState extends ConsumerState<StudyGroupsTab> {
  int _selectedTab = 0;
  final _groupRepo = StudyGroupsRepository();
  Map<String, String> _userMemberships = {};


  @override
  void initState() {
    super.initState();
    _fetchUserMemberships();
  }

  Future<void> _fetchUserMemberships() async {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return;

    setState(() {});
    try {
      final List<dynamic> data = await Supabase.instance.client
          .from('study_group_members')
          .select('group_id, status')
          .eq('user_id', userId);

      if (mounted) {
        setState(() {
          _userMemberships = {
            for (var m in data) m['group_id'] as String: m['status'] as String,
          };

        });
      }
    } catch (e) {
      if (mounted) setState(() {});
    }
  }

  void _manageGroup(StudyGroup group) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text('Manage ${group.subject}', style: AppTheme.heading2),
            const SizedBox(height: 12),
            const Text('Accept or remove members from your group.'),
            const Divider(height: 32),
            Expanded(
              child: FutureBuilder(
                future: Supabase.instance.client
                    .from('study_group_members')
                    .select('*, profiles(full_name)')
                    .eq('group_id', group.id),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final members = snapshot.data as List;
                  if (members.isEmpty) {
                    return const Center(child: Text('No members yet.'));
                  }

                  return ListView.builder(
                    itemCount: members.length,
                    itemBuilder: (context, i) {
                      final m = members[i];
                      final isPending = m['status'] == 'pending';
                      final profileName =
                          m['profiles']?['full_name'] ??
                          'User ${m['user_id'].toString().substring(0, 5)}';

                      return ListTile(
                        leading: avatarWidget(profileName[0], radius: 18),
                        title: Text(
                          profileName,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(isPending ? 'Wants to join' : 'Member'),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isPending)
                              IconButton(
                                icon: const Icon(
                                  Icons.check_circle,
                                  color: Colors.green,
                                ),
                                onPressed: () async {
                                  await _groupRepo.approveMember(
                                    group.id,
                                    m['user_id'],
                                  );
                                  if (context.mounted) Navigator.pop(context);
                                },
                              ),
                            IconButton(
                              icon: const Icon(Icons.cancel, color: Colors.red),
                              onPressed: () async {
                                await _groupRepo.removeMember(
                                  group.id,
                                  m['user_id'],
                                );
                                if (context.mounted) Navigator.pop(context);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedCampus = ref.watch(selectedCampusProvider);
    if (selectedCampus == null) {
      return Scaffold(
        backgroundColor: AppTheme.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.location_on_rounded,
                  size: 48,
                  color: AppTheme.coral,
                ),
                const SizedBox(height: 16),
                Text(
                  'Choose a campus first to view or create study groups.',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => context.push(AppRoutes.campusSelect),
                  child: const Text('Select Campus'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            // ... (flexible space header remains same)
            expandedHeight: 180,
            floating: false,
            pinned: true,
            backgroundColor: AppTheme.coral,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_back_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              onPressed: () => context.pop(),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Color(0xFFF43F5E),
                      Color(0xFFE11D48),
                      Color(0xFFBE123C),
                    ],
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
                        Icons.groups_3_rounded,
                        size: 160,
                        color: Colors.white.withValues(alpha: 0.06),
                      ),
                    ),
                    Positioned(
                      left: 24,
                      right: 24,
                      bottom: 24,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Study Groups',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            'Find your study tribe & learn together.',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 14,
                            ),
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
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: AppTheme.softShadow,
                ),
                child: Row(
                  children: [
                    _buildTabBtn('All Groups', 0),
                    _buildTabBtn('My Groups', 1),
                  ],
                ),
              ),
            ),
          ),

          StreamBuilder<List<Map<String, dynamic>>>(
            stream: _groupRepo.getGroupsStream(selectedCampus['campus_id']),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                );
              }
              final groups =
                  snapshot.data?.map((e) => StudyGroup.fromJson(e)).toList() ??
                  [];
              final filtered = _selectedTab == 0
                  ? groups
                  : groups
                        .where(
                          (g) =>
                              g.creatorId ==
                              Supabase.instance.client.auth.currentUser?.id,
                        )
                        .toList();

              if (filtered.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(child: Text('No groups found. Start one!')),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final group = filtered[index];
                    final status = _userMemberships[group.id];
                    final isOwner =
                        group.creatorId ==
                        Supabase.instance.client.auth.currentUser?.id;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _buildGroupCard(
                        context,
                        group: group,
                        status: status,
                        isOwner: isOwner,
                      ),
                    );
                  }, childCount: filtered.length),
                ),
              );
            },
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 80)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(AppRoutes.studyGroupsCreate),
        backgroundColor: AppTheme.coral,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Create',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }

  Widget _buildTabBtn(String label, int index) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            gradient: isSelected
                ? const LinearGradient(
                    colors: [Color(0xFFF43F5E), Color(0xFFE11D48)],
                  )
                : null,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textSecondary,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGroupCard(
    BuildContext context, {
    required StudyGroup group,
    String? status,
    required bool isOwner,
  }) {
    final isFull = group.memberCount >= group.maxMembers;
    final isApproved = status == 'approved';
    final isPending = status == 'pending';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                group.subject,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              _buildTag(
                isFull
                    ? 'Full'
                    : '${group.maxMembers - group.memberCount} spots',
                isFull ? Colors.red : Colors.green,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            group.description,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Icon(
                Icons.calendar_today,
                size: 14,
                color: AppTheme.textSecondary,
              ),
              const SizedBox(width: 4),
              Text(group.dateTime, style: const TextStyle(fontSize: 12)),
              const Spacer(),
              Icon(Icons.location_on, size: 14, color: AppTheme.textSecondary),
              const SizedBox(width: 4),
              Text(group.location, style: const TextStyle(fontSize: 12)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                '${group.memberCount}/${group.maxMembers} members',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              if (isOwner)
                ElevatedButton(
                  onPressed: () => _manageGroup(group),
                  child: const Text('Manage'),
                )
              else if (isApproved)
                const Text(
                  'Joined',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                )
              else if (isPending)
                const Text(
                  'Requested',
                  style: TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                )
              else if (!isFull)
                ElevatedButton(
                  onPressed: () async {
                    await _groupRepo.requestToJoin(group.id);
                    _fetchUserMemberships(); // Refresh statuses
                  },
                  child: const Text('Join'),
                )
              else
                const Text('Group Full', style: TextStyle(color: Colors.red)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
