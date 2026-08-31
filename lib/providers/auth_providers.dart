import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'repository_providers.dart';

/// Streams Supabase's own auth state — this is the single source of truth
/// for "is an admin signed in", per the project rule against a second,
/// shadow session store.
final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

final currentUserEmailProvider = Provider<String?>((ref) {
  final auth = ref.watch(authStateProvider).valueOrNull;
  return auth?.session?.user.email;
});
