import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/constants/app_config.dart';
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

  /// Signs in as the one admin via Supabase email+password auth — the
  /// 6-digit PIN the admin typed into the (reused) OTP boxes is the
  /// password. Deliberately bypasses the phone/SMS pipeline entirely.
  Future<void> signInAdmin(String pin) async {
    try {
      await _client.auth.signInWithPassword(
        email: AppConfig.adminEmail,
        password: pin,
      );
    } catch (error) {
      throw mapErrorToAppException(error);
    }
  }

  /// Signs in as the dev/test restaurant account (AppConfig.
  /// testRestaurantPhoneDigits) via Supabase email+password auth — same
  /// mechanism and same reason as [signInAdmin]: bypasses the phone/SMS
  /// pipeline entirely for a designated test number.
  Future<void> signInTestRestaurant(String pin) async {
    try {
      await _client.auth.signInWithPassword(
        email: AppConfig.testRestaurantEmail,
        password: pin,
      );
    } catch (error) {
      throw mapErrorToAppException(error);
    }
  }

  /// Call once, immediately after a successful admin sign-in. Links the
  /// seeded admin row to the now-real signed-in user (first login only).
  Future<bool> claimAdmin() async {
    try {
      final result = await _client.rpc('claim_admin');
      return result == true;
    } catch (error) {
      throw mapErrorToAppException(error);
    }
  }

  /// Call on session restore (app cold start) for an already-signed-in
  /// user, to check whether they were previously claimed as the admin.
  Future<bool> isAdmin() async {
    try {
      final result = await _client.rpc('is_admin');
      return result == true;
    } catch (error) {
      throw mapErrorToAppException(error);
    }
  }
}
