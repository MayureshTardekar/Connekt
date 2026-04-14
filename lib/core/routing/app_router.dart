import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../providers/auth_provider.dart';

// Your actual screens
import '../../screens/splash_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/main_screen.dart';
import '../../screens/campus/campus_selection_screen.dart';

final routerProvider = Provider<GoRouter>((ref) {
  ref.watch(authStateProvider).value; // Rebuild router on auth changes

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isLoggedIn = Supabase.instance.client.auth.currentSession != null;
      final isLoggingIn = state.matchedLocation == '/login';
      final isSplashing = state.matchedLocation == '/';

      if (!isLoggedIn) {
        return (isLoggingIn || isSplashing) ? null : '/login';
      }

      // If logged in, we need to decide between dashboard and campus selection
      // For now, we'll let the user go to campus-select if they haven't joined one
      // (Ideally this check would be in a provider for performance)
      if (isLoggedIn && (isLoggingIn || isSplashing)) {
        // We'll return the initial location and let the screens handle the deep check
        // Or better, we can use a Future to decide.
        // For simplicity in GoRouter redirect (which is synchronous-ish), 
        // we point to / but let the SplashScreen do the heavy lifting of checking membership.
        return null; 
      }

      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(path: '/campus-select', builder: (context, state) => const CampusSelectionScreen()),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => const MainScreen(),
      ),
    ],
  );
});
