import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../repositories/auth_repository.dart';

final authRepositoryProvider = Provider((ref) => AuthRepository());

final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.read(authRepositoryProvider).authStateChanges.handleError((e) {
    debugPrint('Auth Stream Error: $e');
    // We return an empty AuthState or handle it silently to prevent crashes
  });
});

final currentUserProvider = Provider<User?>((ref) {
  // Use the repository instead of direct Supabase access to respect mock settings
  return ref.watch(authRepositoryProvider).currentUser;
});

final totalAppUsersProvider = FutureProvider<int>((ref) async {
  return ref.watch(authRepositoryProvider).getTotalUserCount();
});
