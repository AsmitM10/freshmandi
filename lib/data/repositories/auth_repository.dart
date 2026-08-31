import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/supabase/supabase_client.dart';

/// Admin sign-in. Uses Supabase Auth directly (email + password) — per
/// FreshMandi project rules, Supabase's own SDK owns session persistence;
/// this repository does not shadow it with a second local session store.
///
/// PRODUCT DECISION REQUIRED: the customer-facing FreshMandi app uses
/// OTP-based login with no password. Whether the admin console should also
/// be OTP-based (and if so, by SMS or email OTP through Supabase Auth) or
/// stay email+password is a product decision, not made here — this is the
/// simplest Supabase-native option to get the console running end-to-end.
class AuthRepository {
  Stream<AuthState> get authStateChanges => supabase.auth.onAuthStateChange;

  bool get isSignedIn => supabase.auth.currentSession != null;

  String? get currentUserEmail => supabase.auth.currentUser?.email;

  Future<void> signIn({required String email, required String password}) async {
    await supabase.auth.signInWithPassword(email: email, password: password);
  }

  Future<void> signOut() async {
    await supabase.auth.signOut();
  }
}
