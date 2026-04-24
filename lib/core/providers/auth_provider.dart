import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../repositories/auth_repository.dart';

final authRepositoryProvider = Provider((ref) => AuthRepository());

final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.read(authRepositoryProvider).authStateChanges.handleError((e) {
    // Skip logging for the common PKCE/Hot-Restart "Code verifier" noise
    if (e is AuthException && e.message.contains('Code verifier')) {
      return;
    }
    debugPrint('Auth Stream Error: $e');
  });
});

final currentUserProvider = Provider<User?>((ref) {
  // Use the repository instead of direct Supabase access to respect mock settings
  return ref.watch(authRepositoryProvider).currentUser;
});

final totalAppUsersProvider = FutureProvider<int>((ref) async {
  return ref.watch(authRepositoryProvider).getTotalUserCount();
});
