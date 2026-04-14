import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:connekt/core/repositories/auth_repository.dart';
import '../theme/app_theme.dart';
import 'home/dashboard_tab.dart';
import 'notes/notes_tab.dart';
import 'events/events_tab.dart';
import 'chat/chat_tab.dart';
import 'ghost/ghost_tab.dart';
import 'ai/ai_chat_screen.dart';
import 'profile/profile_screen.dart';
import '../theme/avatar_helper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/providers/theme_provider.dart';
import '../core/providers/auth_provider.dart';

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({super.key});

  @override
  MainScreenState createState() => MainScreenState();
}

class MainScreenState extends ConsumerState<MainScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const DashboardTab(),
    const NotesTab(),
    const EventsTab(),
    const ChatTab(),
    const GhostTab(),
  ];

  void navigateToTab(int index) {
    setState(() => _currentIndex = index);
  }

  void _showAISheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return AIChatScreen(scrollController: scrollController);
          },
        );
      },
    );
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    
    if (image != null) {
      final bytes = await image.readAsBytes();
      final extension = image.path.split('.').last;
      
      // Show loading
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Uploading profile photo...'), duration: Duration(seconds: 2)),
        );
      }
      
      final url = await AuthRepository().uploadProfilePhoto(bytes, extension);
      
      if (mounted && url != null) {
        setState(() {}); // Trigger rebuild to show new image
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile photo updated! ✨')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: Builder(
          builder: (context) {
            final user = ref.watch(currentUserProvider);
            final name = user?.userMetadata?['full_name'] ?? user?.userMetadata?['name'] ?? 'User';
            final initials = name.isNotEmpty ? name[0].toUpperCase() : 'U';
            final avatarUrl = user?.userMetadata?['avatar_url'];
            
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: GestureDetector(
                onTap: () => _scaffoldKey.currentState?.openEndDrawer(),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primary.withValues(alpha: 0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: AppTheme.primary.withValues(alpha: 0.1),
                    child: avatarWidget(initials, radius: 18, imageUrl: avatarUrl),
                  ),
                ),
              ),
            );
          },
        ),
        title: Text(
          'Connekt',
          style: TextStyle(
            color: Theme.of(context).brightness == Brightness.dark ? Colors.white : AppTheme.textPrimary,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.notifications_none_rounded, 
              color: Theme.of(context).brightness == Brightness.dark ? Colors.white70 : AppTheme.textPrimary
            ),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      endDrawer: Drawer(
        width: MediaQuery.of(context).size.width * 0.85,
        backgroundColor: Theme.of(context).brightness == Brightness.dark 
            ? const Color(0xFF0F0A1E) 
            : Colors.white,
        child: Column(
          children: [
            // Binance Style Profile Header
            Container(
              padding: EdgeInsets.fromLTRB(24, MediaQuery.of(context).padding.top + 20, 24, 30),
              decoration: BoxDecoration(
                gradient: Theme.of(context).brightness == Brightness.dark 
                  ? const LinearGradient(
                      colors: [Color(0xFF2E1065), Color(0xFF0F0A1E)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : const LinearGradient(
                      colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
              ),
              child: Builder(
                builder: (context) {
                  final user = ref.watch(currentUserProvider);
                  final name = user?.userMetadata?['full_name'] ?? user?.userMetadata?['name'] ?? 'Student';
                  final initials = name.isNotEmpty ? name[0].toUpperCase() : 'S';
                  final email = user?.email ?? 'Verification Pending';
                  final avatarUrl = user?.userMetadata?['avatar_url'];
                  
                  return Column(
                    children: [
                      Row(
                        children: [
                          Stack(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(colors: [Colors.purpleAccent, Colors.blueAccent]),
                                ),
                                child: Hero(
                                  tag: 'profile-pic',
                                  child: avatarWidget(initials, radius: 34, imageUrl: avatarUrl),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: GestureDetector(
                                  onTap: () async {
                                    Navigator.pop(context); // Close drawer
                                    await _pickAndUploadImage();
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFF8B5CF6),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.edit_rounded, color: Colors.white, size: 14),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  email,
                                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.settings_outlined, color: Colors.white70),
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.verified_user_rounded, color: Colors.amber, size: 18),
                            SizedBox(width: 10),
                            Text('Campus Verified ✅', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                          ],
                        ),
                      ),
                    ],
                  );
                }
              ),
            ),
            
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                children: [
                  /* Commented out as requested
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.history_rounded,
                    title: 'Action History ⌚',
                    subtitle: 'View sessions & interactions',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const HistorySessionsScreen()));
                    },
                  ),
                  */
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.auto_awesome_rounded,
                    title: 'Connekt AI 🤖',
                    subtitle: 'Chat with your assistant',
                    onTap: () {
                      Navigator.pop(context);
                      _showAISheet();
                    },
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.location_on_rounded,
                    title: 'Campus Settings 🏫',
                    subtitle: 'Switch or join campus',
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  const Divider(indent: 20, endIndent: 20, height: 40),
                  _buildDrawerItem(
                    context: context,
                    icon: ref.watch(themeProvider) == ThemeMode.dark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                    title: 'Theme & Style 🎨',
                    subtitle: ref.watch(themeProvider) == ThemeMode.dark ? 'Switch to Light' : 'Switch to Purple Dark',
                    trailing: Switch.adaptive(
                      value: ref.watch(themeProvider) == ThemeMode.dark,
                      onChanged: (val) => ref.read(themeProvider.notifier).toggleTheme(),
                      activeThumbColor: const Color(0xFF8B5CF6),
                    ),
                    onTap: () => ref.read(themeProvider.notifier).toggleTheme(),
                  ),
                  _buildDrawerItem(
                    context: context,
                    icon: Icons.security_rounded,
                    title: 'Security',
                    subtitle: 'Password & Auth',
                    onTap: () {},
                  ),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: TextButton.icon(
                onPressed: () async {
                  final navigator = Navigator.of(context);
                  await Supabase.instance.client.auth.signOut();
                  if (mounted) navigator.pop(); // Close drawer
                },
                icon: const Icon(Icons.logout_rounded, color: Colors.redAccent),
                label: const Text('Log Out', style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                style: TextButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.redAccent.withValues(alpha: 0.1),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80.0), // Above bottom bar
        child: FloatingActionButton(
          onPressed: _showAISheet,
          backgroundColor: const Color(0xFF8B5CF6),
          shape: const CircleBorder(),
          elevation: 4,
          child: const Icon(Icons.auto_awesome_rounded, color: Colors.white),
        ),
      ),
      body: _pages[_currentIndex],
      extendBody: true,
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: Theme.of(context).brightness == Brightness.dark ? 0.3 : 0.08),
              blurRadius: 24,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (index) => setState(() => _currentIndex = index),
            type: BottomNavigationBarType.fixed,
            backgroundColor: Theme.of(context).cardColor,
            selectedItemColor: Theme.of(context).primaryColor,
            unselectedItemColor: Theme.of(context).brightness == Brightness.dark ? Colors.white24 : const Color(0xFFBFC6D2),
            selectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
            unselectedLabelStyle: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
            elevation: 0,
            items: [
              _buildNavItem(Icons.dashboard_rounded, 'Home', 0),
              _buildNavItem(Icons.auto_stories_rounded, 'Notes', 1),
              _buildNavItem(Icons.celebration_rounded, 'Events', 2),
              _buildNavItem(Icons.forum_rounded, 'Chat', 3),
              _buildNavItem(Icons.public_rounded, 'World', 4),
            ],
          ),
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildNavItem(
    IconData icon,
    String label,
    int index,
  ) {
    final isSelected = _currentIndex == index;
    return BottomNavigationBarItem(
      icon: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        margin: const EdgeInsets.only(bottom: 2),
        decoration: BoxDecoration(
          gradient: isSelected ? AppTheme.primaryGradient : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 22, color: isSelected ? Colors.white : null),
      ),
      label: label,
    );
  }

  Widget _buildDrawerItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark ? Colors.white : AppTheme.textPrimary;
    
    return ListTile(
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withValues(alpha: 0.05) : AppTheme.primary.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: isDark ? Colors.white70 : AppTheme.primary, size: 22),
      ),
      title: Text(
        title,
        style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 14),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(color: isDark ? Colors.white38 : AppTheme.textSecondary, fontSize: 11),
      ),
      trailing: trailing ?? Icon(Icons.chevron_right_rounded, color: isDark ? Colors.white24 : Colors.grey[300]),
    );
  }
}
