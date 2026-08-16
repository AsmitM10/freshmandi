import '../constants/app_config.dart';

/// Field-level validation shared by the registration and login forms.
/// Each function returns a user-facing error string, or null when valid.
class Validators {
  Validators._();

  static final RegExp _ownerNamePattern = RegExp(r"^[a-zA-Z\s.'-]+$");
  static final RegExp _digitsOnly = RegExp(r'^[0-9]+$');

  static String? restaurantName(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Restaurant name is required';
    if (trimmed.length < AppConfig.restaurantNameMinLength) {
      return 'Restaurant name is too short';
    }
    if (trimmed.length > AppConfig.restaurantNameMaxLength) {
      return 'Restaurant name is too long';
    }
    return null;
  }

  static String? ownerName(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Owner name is required';
    if (trimmed.length < AppConfig.ownerNameMinLength) {
      return 'Owner name is too short';
    }
    if (trimmed.length > AppConfig.ownerNameMaxLength) {
      return 'Owner name is too long';
    }
    if (!_ownerNamePattern.hasMatch(trimmed)) {
      return 'Owner name contains invalid characters';
    }
    return null;
  }

  /// Validates the 10 digits the user types after the fixed +91 prefix.
  static String? phoneDigits(String? value) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Phone number is required';
    if (!_digitsOnly.hasMatch(trimmed)) {
      return 'Phone number must contain digits only';
    }
    if (trimmed.length != AppConfig.phoneDigitLength) {
      return 'Enter a valid 10-digit phone number';
    }
    return null;
  }

  /// Normalizes 10 local digits into the E.164 format stored in the database.
  static String toE164(String phoneDigits) => '+91$phoneDigits';

  static String? otp(String? value, {int length = AppConfig.otpLength}) {
    final trimmed = value?.trim() ?? '';
    if (trimmed.isEmpty) return 'Enter the OTP';
    if (!_digitsOnly.hasMatch(trimmed) || trimmed.length != length) {
      return 'Enter the $length-digit OTP';
    }
    return null;
  }
}
