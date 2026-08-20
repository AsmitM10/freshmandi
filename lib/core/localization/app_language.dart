import 'dart:ui';

/// The exactly two languages FreshMandi supports. Not a general "any BCP-47
/// locale" system — deliberately closed to just these two, per product
/// decision (do not add Marathi/Gujarati/anything else without a matching
/// ARB file and an explicit product decision to do so).
enum AppLanguage { english, hindi }

extension AppLanguageX on AppLanguage {
  Locale get locale {
    switch (this) {
      case AppLanguage.english:
        return const Locale('en');
      case AppLanguage.hindi:
        return const Locale('hi');
    }
  }

  /// Persisted value (SharedPreferences) — also what gets written back out
  /// by [fromCode].
  String get code {
    switch (this) {
      case AppLanguage.english:
        return 'en';
      case AppLanguage.hindi:
        return 'hi';
    }
  }

  static AppLanguage fromCode(String? code) {
    switch (code) {
      case 'hi':
        return AppLanguage.hindi;
      case 'en':
      default:
        return AppLanguage.english;
    }
  }
}
