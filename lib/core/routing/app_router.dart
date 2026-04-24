import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import '../providers/campus_provider.dart';
import 'app_routes.dart';

// Your actual screens
import '../../screens/splash_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/signup_screen.dart';
import '../../screens/main_screen.dart';
import '../../screens/campus/campus_selection_screen.dart';
import '../../screens/campus/campus_management_screen.dart';
import '../../screens/ai/ai_chat_screen.dart';

// Tab Screens
import '../../screens/home/dashboard_tab.dart';
import '../../screens/notes/notes_tab.dart';
import '../../screens/events/events_tab.dart';
import '../../screens/chat/chat_tab.dart';
// Tab Screens removed from here to ChatTab consolidation
// Detail/Action Screens
import '../../screens/notes/note_detail_screen.dart';
import '../../screens/notes/upload_note_screen.dart';
import '../../screens/events/event_detail_screen.dart';
import '../../screens/events/post_event_screen.dart';
import '../../screens/chat/chat_detail_screen.dart';
import '../../screens/chat/friend_requests_screen.dart';
import '../../screens/lost_found/lost_found_tab.dart';
import '../../screens/lost_found/item_detail_screen.dart';
import '../../screens/lost_found/post_lost_item_screen.dart';
import '../../screens/communities/create_community_screen.dart';
import '../../screens/communities/community_chat_screen.dart';
import '../../screens/communities/community_admin_screen.dart';
import '../../screens/study_groups/study_groups_tab.dart';
import '../../screens/study_groups/create_group_screen.dart';
import '../../screens/study_groups/study_group_chat_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../models/academic_note.dart';
import '../models/campus_event.dart';
import '../models/chat_conversation.dart';
import '../models/lost_item.dart';
import '../models/study_group.dart';

final routerProvider = Provider<GoRouter>((ref) {
  
  return GoRouter(
    initialLocation: AppRoutes.splash,
    redirect: (context, state) {
      final user = ref.read(currentUserProvider);
      final location = state.matchedLocation;
      
      // LOGS FOR DEBUGGING (Visible in terminal)
      debugPrint('Router: [User: ${user?.email ?? "Guest"}] [Location: $location] [Query: ${state.uri.queryParameters.keys}]');

      // NEW: If we are in the middle of an OAuth code exchange or password recovery, 
      // do NOT redirect. Let Supabase handle the incoming URL.
      if (state.uri.queryParameters.containsKey('code') || 
          state.uri.queryParameters.containsKey('recovery_token')) {
        debugPrint('Router: Auth exchange detected, staying on current route...');
        return null;
      }

      final isLoggingIn = location == AppRoutes.login || 
                         location == AppRoutes.signup ||
                         location == AppRoutes.splash;
      
      if (user == null) {
        return isLoggingIn ? null : AppRoutes.login;
      }
      
      // If logged in, check memberships to decide destination
      // We use .value to check the current state without triggering an infinite loop
      final memberships = ref.watch(myMembershipsProvider).value;

      if (isLoggingIn) {
        if (memberships == null) return null; // Still loading, wait on Splash
        
        if (memberships.isEmpty) {
          return AppRoutes.campusSelect;
        }
        return AppRoutes.dashboard;
      }

      // Safeguard: If user is logged in but managed to get past selection without joining, force them back
      if (memberships != null && memberships.isEmpty && location != AppRoutes.campusSelect) {
        return AppRoutes.campusSelect;
      }
      
      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.signup,
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: AppRoutes.campusSelect,
        builder: (context, state) => const CampusSelectionScreen(),
      ),
      GoRoute(
        path: AppRoutes.chatFriendRequests,
        builder: (context, state) => const FriendRequestsScreen(),
      ),
      GoRoute(
        path: AppRoutes.profile,
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: AppRoutes.aiChat,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final initialPrompt = extra?['initialPrompt'] as String?;
          return AIChatScreen(initialPrompt: initialPrompt);
        },
      ),
      GoRoute(
        path: AppRoutes.campusManagement,
        name: AppRoutes.campusManagement,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          return CampusManagementScreen(
            campusId: extra?['campusId'] ?? '',
            campusName: extra?['campusName'] ?? 'Campus',
          );
        },
      ),
      GoRoute(
        path: AppRoutes.lostFound,
        builder: (context, state) => const LostFoundTab(),
        routes: [
          GoRoute(
            path: 'detail',
            builder: (context, state) {
              final extra = state.extra;
              if (extra is! LostItem) {
                return const _RoutePayloadErrorScreen(
                  message: 'Missing lost-and-found item data.',
                );
              }
              return ItemDetailScreen(item: extra);
            },
          ),
          GoRoute(
            path: 'post',
            builder: (context, state) => const PostLostItemScreen(),
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.studyGroups,
        builder: (context, state) => const StudyGroupsTab(),
        routes: [
          GoRoute(
            path: 'create',
            builder: (context, state) => const CreateGroupScreen(),
          ),
          GoRoute(
            path: 'chat',
            builder: (context, state) {
              final extra = state.extra;
              if (extra is! StudyGroup) {
                return const _RoutePayloadErrorScreen(
                  message: 'Missing study group data.',
                );
              }
              return StudyGroupChatScreen(group: extra);
            },
          ),
        ],
      ),

      // Dashboard with Nested Tabs
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainScreen(navigationShell: navigationShell);
        },
        branches: [
          // HOME BRANCH
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.dashboard,
                builder: (context, state) => const DashboardTab(),
              ),
            ],
          ),
          // NOTES BRANCH
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.notes,
                builder: (context, state) => const NotesTab(),
                routes: [
                  GoRoute(
                    path: 'detail',
                    builder: (context, state) {
                      final extra = state.extra;
                      if (extra is! AcademicNote) {
                        return const _RoutePayloadErrorScreen(
                          message: 'Missing note details.',
                        );
                      }
                      return NoteDetailScreen(note: extra);
                    },
                  ),
                  GoRoute(
                    path: 'upload',
                    builder: (context, state) => const UploadNoteScreen(),
                  ),
                ],
              ),
            ],
          ),
          // EVENTS BRANCH
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.events,
                builder: (context, state) => const EventsTab(),
                routes: [
                  GoRoute(
                    path: 'detail',
                    builder: (context, state) {
                      final extra = state.extra;
                      if (extra is! CampusEvent) {
                        return const _RoutePayloadErrorScreen(
                          message: 'Missing event details.',
                        );
                      }
                      return EventDetailScreen(event: extra);
                    },
                  ),
                  GoRoute(
                    path: 'post',
                    builder: (context, state) => const PostEventScreen(),
                  ),
                ],
              ),
            ],
          ),
          // CHAT BRANCH
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.chat,
                builder: (context, state) => const ChatTab(),
                routes: [
                  GoRoute(
                    path: 'detail',
                    builder: (context, state) {
                      final extra = state.extra;
                      if (extra is! ChatConversation) {
                        return const _RoutePayloadErrorScreen(
                          message: 'Missing chat conversation data.',
                        );
                      }
                      return ChatDetailScreen(
                        targetId: (extra.isGroup || extra.isOfficial) ? extra.id : extra.participantId,
                        name: extra.participantName,
                        isCommunity: extra.isGroup || extra.isOfficial,
                        isOfficial: extra.isOfficial,
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: AppRoutes.createCommunity,
        builder: (context, state) => const CreateCommunityScreen(),
      ),
      GoRoute(
        path: AppRoutes.communityChat,
        builder: (context, state) => CommunityChatScreen(communityId: state.pathParameters['id'] ?? ''),
      ),
      GoRoute(
        path: '/communities/:id/admin',
        builder: (context, state) => CommunityAdminScreen(communityId: state.pathParameters['id'] ?? ''),
      ),
    ],
  );
});

class _RoutePayloadErrorScreen extends StatelessWidget {
  const _RoutePayloadErrorScreen({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Route Error')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(message, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}
