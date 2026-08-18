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

/// Speech recognizer locale. Only [english] is wired up today — Hindi and
/// Marathi are declared so the rest of the voice-order architecture
/// (service/controller/screen) never has to change to add them later; only
/// this enum, [VoiceRecognitionLanguageX.localeId], and (once real Hindi/
/// Marathi item aliases exist in the catalog) the item matcher would need
/// updating.
enum VoiceRecognitionLanguage { english }

extension VoiceRecognitionLanguageX on VoiceRecognitionLanguage {
  /// BCP-47 locale id passed to `SpeechToText.listen(localeId: ...)`.
  /// `en_IN` (not `en_US`) so on-device recognition is tuned for
  /// Indian-accented English and mixed Hindi/English grocery terms
  /// ("tamatar", "kilo") where the device's language pack supports it.
  String get localeId {
    switch (this) {
      case VoiceRecognitionLanguage.english:
        return 'en_IN';
    }
  }

  String get label {
    switch (this) {
      case VoiceRecognitionLanguage.english:
        return 'English';
    }
  }
}
