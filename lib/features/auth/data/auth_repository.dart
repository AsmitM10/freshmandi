import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';

/// Thin wrapper around Supabase Auth for phone OTP. No custom tokens, no
/// custom password auth — Supabase Auth is the sole source of truth for
/// sessions.
class AuthRepository {
  AuthRepository(this._client);

  final SupabaseClient _client;

  Session? get currentSession => _client.auth.currentSession;

  /// Emits on sign-in, sign-out, token refresh, and session recovery.
  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  Future<void> sendPhoneOtp(String e164Phone) async {
    try {
      await _client.auth.signInWithOtp(phone: e164Phone);
    } catch (error) {
      throw mapErrorToAppException(error);
    }
  }

  Future<void> verifyPhoneOtp({
    required String e164Phone,
    required String otp,
  }) async {
    try {
      await _client.auth.verifyOTP(
        phone: e164Phone,
        token: otp,
        type: OtpType.sms,
      );
    } catch (error) {
      throw mapErrorToAppException(error);
    }
  }

  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (error) {
      throw mapErrorToAppException(error);
    }
  }
}
