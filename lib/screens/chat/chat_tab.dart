import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../theme/avatar_helper.dart';
import 'chat_detail_screen.dart';

class ChatTab extends StatelessWidget {
  const ChatTab({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                children: [
                  Row(
                    children: [
                      Text('Messages', style: Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: 26)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), boxShadow: AppTheme.softShadow),
                        child: const Icon(Icons.edit_rounded, color: AppTheme.primary, size: 20),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Container(
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: AppTheme.softShadow),
                    child: TextField(
                      decoration: InputDecoration(
                        hintText: 'Search conversations...',
                        prefixIcon: const Icon(Icons.search_rounded, color: AppTheme.textSecondary),
                        border: InputBorder.none, enabledBorder: InputBorder.none, focusedBorder: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Online avatars
                  SizedBox(
                    height: 80,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildOnlineAvatar('Sarah', true),
                        _buildOnlineAvatar('Prof.', true),
                        _buildOnlineAvatar('Jamie', false),
                        _buildOnlineAvatar('Marcus', true),
                        _buildOnlineAvatar('Aisha', false),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),

            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Text('RECENT', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.5)),
                  ),
                  _buildChatTile(context, 'Sarah Miller', 'That presentation looked great! Se...', '10:42 AM', unread: 2),
                  _buildChatTile(context, 'Prof. Aris', 'Please review the syllabus for next w...', 'Yesterday'),
                  _buildChatTile(context, 'Ghost #482', 'New anonymous message received...', '2:15 PM', isGhost: true),
                  _buildChatTile(context, 'Jamie Chen', 'The coffee at the student union is fin...', 'Tue'),
                  _buildChatTile(context, 'Marcus Wright', 'Sent a photo', 'Oct 12'),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOnlineAvatar(String name, bool isOnline) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Column(
        children: [
          SizedBox(
            width: 56,
            height: 56,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                avatarWidget(name, radius: 26),
                if (isOnline)
                  Positioned(
                    bottom: 2,
                    right: 2,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: AppTheme.emerald,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.background, width: 2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(name, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
        ],
      ),
    );
  }

  Widget _buildChatTile(BuildContext context, String name, String message, String time, {int unread = 0, bool isGhost = false}) {
    return GestureDetector(
      onTap: () {
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => ChatDetailScreen(userName: name, userInitial: initials(name), avatarColor: isGhost ? AppTheme.anonPurple : avatarColor(name)),
        ));
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isGhost ? const Color(0xFFF5F3FF) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 10, offset: Offset(0, 2))],
        ),
        child: Row(
          children: [
            isGhost
                ? Container(
                    width: 52, height: 52,
                    decoration: BoxDecoration(gradient: AppTheme.ghostGradient, borderRadius: BorderRadius.circular(16)),
                    child: const Icon(Icons.visibility_off_rounded, color: Colors.white, size: 22),
                  )
                : avatarWidget(name, radius: 26),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(name, style: TextStyle(color: isGhost ? AppTheme.anonPurple : AppTheme.textPrimary, fontSize: 15, fontWeight: FontWeight.w700)),
                      Text(time, style: TextStyle(color: unread > 0 ? AppTheme.primary : AppTheme.textSecondary, fontSize: 12, fontWeight: unread > 0 ? FontWeight.w700 : FontWeight.w500)),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(message, style: TextStyle(color: isGhost ? const Color(0xFF7C3AED) : AppTheme.textSecondary, fontSize: 13, fontWeight: unread > 0 ? FontWeight.w600 : FontWeight.normal, fontStyle: isGhost ? FontStyle.italic : FontStyle.normal), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      if (unread > 0)
                        Container(
                          margin: const EdgeInsets.only(left: 8), width: 22, height: 22,
                          decoration: const BoxDecoration(gradient: AppTheme.primaryGradient, shape: BoxShape.circle),
                          child: Center(child: Text('$unread', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700))),
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
