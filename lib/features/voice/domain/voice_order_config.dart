import '../../../core/localization/app_language.dart';

/// Tunables for Voice Order that aren't sourced from Figma or Supabase —
/// centralized here, same convention as [AppConfig] in core/constants.
class VoiceOrderConfig {
  VoiceOrderConfig._();

  /// Hard stop for one listening session. Prevents an accidental
  /// open-ended recording from running forever; the UI counts down from
  /// this and recognition is force-stopped (not cancelled — whatever was
  /// heard up to that point is still processed) once it elapses.
  static const Duration maxRecordingDuration = Duration(seconds: 60);

  /// How long the recognizer waits after the user stops talking before it
  /// treats the utterance as finished. Long enough that "10 kg tomato, 5
  /// kg onion" (spoken as one breath with natural pauses, or with a beat
  /// of hesitation before the user starts talking at all) doesn't get cut
  /// off, short enough that the mic doesn't sit open forever waiting for
  /// a final result that will never come. Only takes effect on
  /// native (Android/iOS) — Chrome/Edge's underlying Web Speech API
  /// enforces its own shorter, browser-controlled silence timeout on web
  /// that this value can't override.
  static const Duration pauseBetweenWords = Duration(seconds: 8);
}

/// Speech recognizer locale — mirrors FreshMandi's two supported app
/// languages ([AppLanguage] in core/localization) exactly, via
/// [VoiceRecognitionLanguageX.fromAppLanguage]. There is deliberately no
/// separate "voice language" setting anywhere in the UI: Voice Order
/// always listens in whatever language Settings > Language currently has
/// selected, so switching the app language and switching the speech
/// recognizer language can never drift apart into two different values.
enum VoiceRecognitionLanguage { english, hindi }

extension VoiceRecognitionLanguageX on VoiceRecognitionLanguage {
  /// BCP-47-style locale id passed to `SpeechToText.listen(localeId: ...)`,
  /// in the underscore form `SpeechToText.locales()` actually returns on
  /// device (not a bare hyphenated tag) — `en_IN`/`hi_IN` so on-device
  /// recognition is tuned for Indian-accented speech and mixed Hindi/
  /// English grocery terms ("tamatar", "kilo") where the device's
  /// language pack supports it.
  String get localeId {
    switch (this) {
      case VoiceRecognitionLanguage.english:
        return 'en_IN';
      case VoiceRecognitionLanguage.hindi:
        return 'hi_IN';
    }
  }

  String get label {
    switch (this) {
      case VoiceRecognitionLanguage.english:
        return 'English';
      case VoiceRecognitionLanguage.hindi:
        return 'हिंदी';
    }
  }

  /// The one place `AppLanguage` (Settings > Language) turns into a
  /// speech-recognition locale — en → en_IN, hi → hi_IN.
  static VoiceRecognitionLanguage fromAppLanguage(AppLanguage language) {
    switch (language) {
      case AppLanguage.english:
        return VoiceRecognitionLanguage.english;
      case AppLanguage.hindi:
        return VoiceRecognitionLanguage.hindi;
    }
  }
}
