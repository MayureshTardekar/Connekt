import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/providers/auth_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:connekt/core/repositories/auth_repository.dart';
import '../../core/providers/campus_provider.dart';
import '../../core/routing/app_routes.dart';
import '../../theme/avatar_helper.dart';
import 'package:intl/intl.dart';
import '../../core/widgets/premium_background.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isLeavingCampus = false;

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final memberships = ref.watch(myMembershipsProvider);
    final avatarUrl = user?.userMetadata?['avatar_url'];

    String getUserName() {
      if (user == null) return 'Student';
      return user.userMetadata?['display_name'] ??
          user.userMetadata?['full_name'] ??
          user.userMetadata?['name'] ??
          user.email?.split('@').first ??
          'Student';
    }

    String getUserInitials() {
      final name = getUserName();
      final parts = name.split(' ');
      if (parts.length >= 2) {
        return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      }
      return name.isNotEmpty ? name[0].toUpperCase() : 'S';
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = theme.colorScheme.onSurface;
    final secondaryColor = theme.colorScheme.onSurface.withValues(alpha: 0.6);
    final cardColor = theme.colorScheme.surface;
    final surfaceColor = isDark ? theme.colorScheme.surface : const Color(0xFFF8F9FA);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: PremiumBackground(
        child: Stack(
          children: [
            // Top Bar
            Positioned(
              top: 50,
              left: 10,
              right: 10,
              child: SizedBox(
                height: 50,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Back Button
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: Icon(Icons.arrow_back, color: primaryColor),
                        onPressed: () {
                          if (Navigator.canPop(context)) {
                            context.pop();
                          } else {
                            context.go('/dashboard');
                          }
                        },
                      ),
                    ),
                    
                    // Centered Title
                    Text(
                      'PROFILE',
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                      ),
                    ),
                    
                    // Settings Button
                    Align(
                      alignment: Alignment.centerRight,
                      child: Padding(
                        padding: const EdgeInsets.only(right: 10),
                        child: _buildHeaderButton(Icons.settings_outlined, () {}, isDark, primaryColor),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 100, 24, 40),
                  child: Column(
                    children: [
                  // Profile Photo with Glow
                  Center(
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Container(
                          width: 130,
                          height: 130,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: theme.colorScheme.primary.withValues(alpha: 0.3),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: theme.colorScheme.primary.withValues(alpha: 0.15),
                                blurRadius: 30,
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                        ),
                        Hero(
                          tag: 'profile-pic',
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                            ),
                            child: avatarWidget(
                              getUserInitials(),
                              radius: 58,
                              imageUrl: avatarUrl,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 4,
                          child: GestureDetector(
                            onTap: () => _pickAndUploadImage(context),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                shape: BoxShape.circle,
                                border: Border.all(color: theme.colorScheme.surface, width: 2),
                              ),
                              child: Icon(Icons.camera_alt_rounded, size: 16, color: theme.colorScheme.onPrimary),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Name and Verification
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        getUserName(),
                        style: TextStyle(
                          color: primaryColor,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.verified_rounded, color: Color(0xFF4C87C4), size: 20),
                    ],
                  ),

                  const SizedBox(height: 4),

                  Text(
                    user?.email ?? '',
                    style: TextStyle(color: secondaryColor, fontSize: 14),
                  ),

                  const SizedBox(height: 20),

                  // Identity Badges (UID, Branch)
                  memberships.when(
                    data: (list) {
                      if (list.isEmpty) return const SizedBox();
                      final membership = list.first;
                      return Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _buildIdentityBadge(
                            Icons.badge_outlined,
                            membership['uid'] ?? 'No UID',
                            isDark,
                            primaryColor,
                          ),
                          _buildIdentityBadge(
                            Icons.school_outlined,
                            membership['branch'] ?? 'No Branch',
                            isDark,
                            primaryColor,
                          ),
                        ],
                      );
                    },
                    loading: () => const SizedBox(height: 30),
                    error: (_, __) => const SizedBox(),
                  ),

                  const SizedBox(height: 40),

                  // Campus Section
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Primary Campus',
                      style: TextStyle(
                        color: primaryColor,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                    memberships.when(
                      data: (list) {
                        if (list.isEmpty) return _buildEmptyState();
                        final membership = list.first;
                        final campusName = membership['campuses']?['name'] ?? 'Unknown Campus';
                        
                        return Column(
                          children: [
                            _buildPremiumCampusCard(campusName, membership, isDark, primaryColor, theme),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: _isLeavingCampus
                                    ? null
                                    : () => _confirmLeaveCampus(membership),
                                icon: _isLeavingCampus
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(Icons.logout_rounded),
                                label: Text(_isLeavingCampus ? 'Leaving...' : 'Leave Campus'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: const Color(0xFFE57373),
                                  side: BorderSide(
                                    color: const Color(0xFFE57373).withValues(alpha: 0.55),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                      loading: () => Center(child: CircularProgressIndicator(color: theme.colorScheme.primary)),
                      error: (e, _) => Text('Error: $e', style: const TextStyle(color: Colors.redAccent)),
                    ),

                  const SizedBox(height: 40),

                  // Logout Action
                  _buildMenuTile(
                    'Logout', 
                    Icons.logout_rounded, 
                    const Color(0xFFE57373), 
                    () => _handleLogout(context), 
                    isDark, 
                    primaryColor, 
                    theme.colorScheme.surfaceContainerHigh
                  ),
                ],
              ),
            ),
          ),
        ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderButton(
      IconData icon, VoidCallback onTap, bool isDark, Color primaryColor) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isDark
              ? theme.colorScheme.surface.withValues(alpha: 0.8)
              : Colors.white.withValues(alpha: 0.9),
          shape: BoxShape.circle,
          border: Border.all(color: primaryColor.withValues(alpha: 0.08)),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
        ),
        child: Icon(icon, color: primaryColor, size: 20),
      ),
    );
  }

  Widget _buildIdentityBadge(
      IconData icon, String label, bool isDark, Color primaryColor) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? theme.colorScheme.surface : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryColor.withValues(alpha: 0.08)),
        boxShadow: isDark
            ? null
            : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 14),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: primaryColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPremiumCampusCard(String name, dynamic membership, bool isDark, Color primaryColor, ThemeData theme) {
    return Container(
      height: 160,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: primaryColor.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background Image with Overlay
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage('https://images.unsplash.com/photo-1541339907198-e08756dedf3f?q=80&w=800'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      (isDark ? const Color(0xFF0B0812) : const Color(0xFF1A1A1A)).withValues(alpha: 0.8),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.star_rounded, color: theme.colorScheme.onPrimary, size: 12),
                          const SizedBox(width: 4),
                          Text(
                            'PRIMARY',
                            style: TextStyle(color: theme.colorScheme.onPrimary, fontSize: 9, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, color: Colors.white54),
                  ],
                ),
                const Spacer(),
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded, color: Colors.white70, size: 12),
                    const SizedBox(width: 6),
                    Text(
                      'Joined ${_formatJoinedDate(membership)}',
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmLeaveCampus(Map<String, dynamic> membership) async {
    final campusId = membership['campus_id']?.toString();
    final campusName = membership['campuses']?['name']?.toString() ?? 'this campus';
    if (campusId == null || campusId.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Campus?'),
        content: Text(
          'You will leave $campusName and can join another campus after this.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Leave', style: TextStyle(color: Color(0xFFE57373))),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLeavingCampus = true);
    try {
      await ref.read(campusRepositoryProvider).leaveCampus(campusId);
      ref.read(selectedCampusIdProvider.notifier).selectCampus(null);
      ref.invalidate(myCampusesProvider);
      ref.invalidate(myMembershipsProvider);
      ref.invalidate(campusMemberCountProvider);

      if (mounted) {
        context.go(AppRoutes.campusSelect);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not leave campus: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLeavingCampus = false);
    }
  }

  Widget _buildMenuTile(String label, IconData icon, Color color, VoidCallback onTap, bool isDark, Color primaryColor, Color cardColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryColor.withValues(alpha: 0.05)),
        boxShadow: isDark ? null : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: primaryColor.withValues(alpha: 0.3), size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickAndUploadImage(BuildContext context) async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);

    if (image != null) {
      final bytes = await image.readAsBytes();
      final extension = image.path.split('.').last;
      
      try {
        final url = await AuthRepository().uploadProfilePhoto(bytes, extension);
        if (url != null) setState(() {});
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Upload failed: $e')));
        }
      }
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = isDark ? Colors.white : const Color(0xFF1A1A1A);
    final secondaryColor = isDark ? Colors.white70 : const Color(0xFF666666);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        title: Text('Logout?', style: TextStyle(color: primaryColor)),
        content: Text('Are you sure you want to exit your current session?', style: TextStyle(color: secondaryColor)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text('Cancel', style: TextStyle(color: secondaryColor))),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            child: const Text('Logout', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await Supabase.instance.client.auth.signOut();
      if (context.mounted) context.go(AppRoutes.login);
    }
  }

  String _formatJoinedDate(Map<String, dynamic> membership) {
    // Try different possible keys for joining date
    final dateStr = membership['created_at'] ?? membership['joined_at'];
    if (dateStr == null) return 'Recent';
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM yyyy').format(date);
    } catch (_) {
      return 'Recent';
    }
  }

  Widget _buildEmptyState() {
    return const Center(
      child: Text('No campus memberships found.', style: TextStyle(color: Color(0xFF888888))),
    );
  }
}
