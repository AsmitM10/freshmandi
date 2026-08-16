import 'package:supabase_flutter/supabase_flutter.dart';

/// A user-presentable error. Screens catch this (or map into it) and show
/// the message via SnackBar/inline text — never raw exception output.
class AppException implements Exception {
  const AppException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Maps SDK/network exceptions to short, non-technical, user-facing copy.
/// None of this copy is defined in Figma (no error states were designed) —
/// flagged as an implementation addition required for production use.
AppException mapErrorToAppException(Object error) {
  if (error is AppException) return error;

  if (error is AuthException) {
    // Prefer the structured error code over message-sniffing — GoTrue's
    // error codes are stable API surface, message text isn't.
    switch (error.code) {
      case 'phone_provider_disabled':
        return const AppException(
          'Phone sign-in is not enabled for this app yet. Please contact support.',
        );
      case 'sms_send_failed':
        return const AppException(
          'Could not send the OTP right now. Please try again shortly.',
        );
      case 'over_sms_send_rate_limit':
      case 'over_request_rate_limit':
        return const AppException(
          'Too many attempts. Please wait a bit before trying again.',
        );
      case 'otp_expired':
        return const AppException('This OTP has expired. Request a new one.');
      case 'otp_disabled':
        return const AppException(
          'OTP sign-in is not enabled for this app yet. Please contact support.',
        );
      case 'phone_exists':
      case 'phone_not_confirmed':
        return const AppException('This phone number is already registered.');
      case 'signup_disabled':
        return const AppException(
          'New sign-ups are temporarily unavailable. Please try again later.',
        );
    }

    final message = error.message.toLowerCase();
    if (message.contains('rate limit') || error.statusCode == '429') {
      return const AppException(
        'Too many attempts. Please wait a bit before trying again.',
      );
    }
    if (message.contains('token has expired') || message.contains('expired')) {
      return const AppException('This OTP has expired. Request a new one.');
    }
    if (message.contains('invalid') && message.contains('otp') ||
        message.contains('token is invalid')) {
      return const AppException('Incorrect OTP. Please try again.');
    }
    if (message.contains('phone') && message.contains('exists')) {
      return const AppException('This phone number is already registered.');
    }
    return AppException(error.message);
  }

  if (error is PostgrestException) {
    if (error.code == '23505') {
      return const AppException('This phone number is already registered.');
    }
    return const AppException('Something went wrong. Please try again.');
  }

  if (error is StorageException) {
    return const AppException(
      'Could not upload the document. Please try again.',
    );
  }

  final text = error.toString().toLowerCase();
  if (text.contains('socketexception') ||
      text.contains('failed host lookup') ||
      text.contains('network')) {
    return const AppException(
      'No internet connection. Please check your network and try again.',
    );
  }

  return const AppException('Something went wrong. Please try again.');
}
