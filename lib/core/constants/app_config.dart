/// Values that are NOT defined by the Figma spec and are not sourced from
/// Supabase config. Centralized here, clearly marked, so each can be
/// changed in one place if product/business requirements pin them down later.
class AppConfig {
  AppConfig._();

  /// Supabase's phone/SMS OTP is a fixed 6-digit code (not configurable via
  /// the dashboard) — the Figma spec's 5-box OTP design cannot hold a 6-digit
  /// code. Resolved with the user: switch to 6 boxes, otherwise identical
  /// Figma styling. See lib/shared/widgets/fm_otp_input.dart.
  static const int otpLength = 6;

  /// Not specified in Figma. Minimal cooldown to stop resend-button spam;
  /// Supabase also enforces its own server-side OTP rate limit independently.
  static const int otpResendCooldownSeconds = 30;

  static const int fssaiMaxSizeBytes = 2 * 1024 * 1024; // 2 MB

  static const int restaurantNameMinLength = 2;
  static const int restaurantNameMaxLength = 100;

  static const int ownerNameMinLength = 2;
  static const int ownerNameMaxLength = 100;

  static const int phoneDigitLength = 10;

  /// Minimum time the splash screen stays visible, regardless of how fast
  /// the session check resolves. Product requirement: exactly 3 seconds.
  static const Duration splashMinDuration = Duration(seconds: 3);

  /// Identifies which revision of the Terms & Conditions copy a restaurant
  /// agreed to (mirrors the "Last Updated" date shown on the T&C screen).
  /// Bump this if the terms copy ever changes materially.
  static const String termsVersion = 'v1-2026-07-22';

  /// The one admin's login identity. Not a real phone number or email —
  /// [adminPhoneDigits] is purely a client-side trigger typed into the same
  /// phone field restaurants use, and [adminEmail] is the email of the one
  /// manually-created Supabase Auth user backing the admin account (see
  /// migration `20260825000001_admin_login.sql`). Deliberately avoids the
  /// SMS/Twilio pipeline entirely — the "OTP" boxes are used as a 6-digit
  /// PIN checked via real Supabase password auth instead.
  static const String adminPhoneDigits = '9999999999';
  static const String adminEmail = 'admin@freshmandi.app';

  /// Dev/test restaurant login — same trick as [adminPhoneDigits]/
  /// [adminEmail]: [testRestaurantPhoneDigits] is a client-side trigger
  /// only (never sent to Supabase as a real phone number), and
  /// [testRestaurantEmail] is the email of an existing, already-approved
  /// restaurant account that also has a password set. Exists so this
  /// number can be used for development/testing without depending on a
  /// working SMS provider (Twilio trial accounts refuse to deliver to
  /// unverified numbers) — the "OTP" boxes double as a 6-digit PIN
  /// checked via real Supabase password auth, exactly like admin sign-in.
  static const String testRestaurantPhoneDigits = '1234567890';
  static const String testRestaurantEmail = 'test-restaurant@freshmandi.app';
}
