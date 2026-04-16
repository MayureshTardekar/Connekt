import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../core/providers/campus_provider.dart';

class CampusManagementScreen extends ConsumerStatefulWidget {
  final String campusId;
  final String campusName;

  const CampusManagementScreen({
    super.key,
    required this.campusId,
    required this.campusName,
  });

  @override
  ConsumerState<CampusManagementScreen> createState() => _CampusManagementScreenState();
}

class _CampusManagementScreenState extends ConsumerState<CampusManagementScreen> {
  bool _isLoadingBanner = false;
  int _memberCount = 0;
  List<Map<String, dynamic>> _members = [];
  bool _isLoadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    setState(() => _isLoadingStats = true);
    try {
      final repo = ref.read(campusRepositoryProvider);
      final count = await repo.getMemberCount(widget.campusId);
      final members = await repo.getCampusMembers(widget.campusId);
      setState(() {
        _memberCount = count;
        _members = members;
        _isLoadingStats = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading stats: $e')),
        );
      }
      setState(() => _isLoadingStats = false);
    }
  }

  Future<void> _pickAndUploadBanner() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        withData: true,
      );

      if (result != null && result.files.first.bytes != null) {
        setState(() => _isLoadingBanner = true);
        
        final repo = ref.read(campusRepositoryProvider);
        final bannerUrl = await repo.uploadCampusBanner(
          widget.campusId,
          result.files.first.bytes!,
        );
        
        await repo.updateCampusBanner(widget.campusId, bannerUrl);
        
        // Refresh campus data to update the dashboard
        ref.invalidate(myMembershipsProvider);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Banner updated successfully!')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to upload banner: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingBanner = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              widget.campusName,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  'ADMIN CONSOLE',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ],
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: _isLoadingStats
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadStats,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                children: [
                  // Health Check Segment
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          theme.colorScheme.primary.withValues(alpha: 0.1),
                          theme.colorScheme.secondary.withValues(alpha: 0.05),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary.withValues(
                                  alpha: 0.1,
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.insights_rounded,
                                color: theme.colorScheme.primary,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Campus Status',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    'Systems active & connected',
                                    style: theme.textTheme.labelSmall,
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Text(
                                'HEALTHY',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Banner Management Card
                  _buildSectionTitle(context, 'Campus Appearance'),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: _pickAndUploadBanner,
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      height: 140,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: theme.cardColor,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: theme.dividerColor),
                        image: const DecorationImage(
                          image: NetworkImage(
                            'https://picsum.photos/seed/connekt/1000/600',
                          ),
                          fit: BoxFit.cover,
                          opacity: 0.2,
                        ),
                      ),
                      child: Center(
                        child: _isLoadingBanner
                            ? const CircularProgressIndicator()
                            : Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary
                                          .withValues(alpha: 0.1),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.camera_alt_rounded,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Change Spotlight Image',
                                    style: theme.textTheme.labelLarge?.copyWith(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Stats Section
                  _buildSectionTitle(context, 'Impact Overview'),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildStatCard(
                        context,
                        'Members',
                        _memberCount.toString(),
                        Icons.people_alt_rounded,
                        Colors.blue,
                      ),
                      const SizedBox(width: 16),
                      _buildStatCard(
                        context,
                        'Notes Shared',
                        '12', // Mocked till we have actual count
                        Icons.description_rounded,
                        Colors.purple,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _buildStatCard(
                        context,
                        'Engagement',
                        'High',
                        Icons.bolt_rounded,
                        Colors.amber,
                      ),
                      const SizedBox(width: 16),
                      _buildStatCard(
                        context,
                        'Growth',
                        '+12%',
                        Icons.auto_graph_rounded,
                        Colors.green,
                      ),
                    ],
                  ),

                  const SizedBox(height: 40),

                  // Settings Toggle Mock
                  _buildSectionTitle(context, 'Quick Settings'),
                  const SizedBox(height: 16),
                  _buildSettingTile(
                    context,
                    'Anonymous Space',
                    'Enable Ghost posts for this campus',
                    true,
                  ),
                  _buildSettingTile(
                    context,
                    'Resource Hub',
                    'Allow peers to upload study notes',
                    true,
                  ),
                  _buildSettingTile(
                    context,
                    'Auto-moderation',
                    'Scan posts for toxic content',
                    false,
                  ),

                  const SizedBox(height: 40),

                  // Members List
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionTitle(
                        context,
                        'Directory (${_members.length})',
                      ),
                      TextButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.sort_rounded, size: 16),
                        label: const Text('Sort'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...(_members.isEmpty
                      ? [const Center(child: Text('No members found.'))]
                      : _members.map(
                        (member) => _buildMemberTile(context, member),
                      )),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildSettingTile(
    BuildContext context,
    String title,
    String subtitle,
    bool value,
  ) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.1)),
        ),
        child: SwitchListTile(
          value: value,
          onChanged: (v) {},
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          subtitle: Text(subtitle, style: theme.textTheme.labelSmall),
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 16),
            Text(
              value,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Text(
              label,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.textTheme.bodySmall?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberTile(BuildContext context, Map<String, dynamic> member) {
    final profile = member['profiles'] ?? {};
    final name = profile['full_name'] ?? 'Member';
    final role = member['role'] ?? 'member';
    final branch = member['branch'] ?? 'N/A';
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.dividerColor.withValues(alpha: 0.05)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.1),
              child: Text(name[0], style: TextStyle(color: theme.colorScheme.primary)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(
                    '$branch • ${branch != 'N/A' ? member['course'] : ''}',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: role == 'owner'
                    ? Colors.orange.withValues(alpha: 0.1)
                    : theme.dividerColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                role.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: role == 'owner' ? Colors.orange : theme.disabledColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
