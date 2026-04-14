import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../repositories/auth_repository.dart';

final authRepositoryProvider = Provider((ref) => AuthRepository());

final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.read(authRepositoryProvider).authStateChanges;
});

final currentUserProvider = StateProvider<User?>((ref) {
  ref.watch(authStateProvider).value;
  // This will update whenever auth state changes (sign in, sign out, user updated)
  return Supabase.instance.client.auth.currentUser;
});
