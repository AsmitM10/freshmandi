import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../domain/voice_order_config.dart';

enum SpeechAvailability {
  available,
  permissionDenied,

  /// Device has no speech recognizer at all (or initialization otherwise
  /// failed) — distinct from a denied permission so the UI can show the
  /// right message for each.
  unavailable,
}

/// Thin wrapper around the on-device `speech_to_text` plugin — no cloud
/// speech API, no API key, nothing sent anywhere except to the OS's own
/// speech recognizer. This is the only file in the app that imports
/// `package:speech_to_text`; everything above it (controller, parser,
/// matcher, screen) talks to this service's plain callbacks instead, so
/// swapping the underlying plugin later would only touch this file.
class SpeechRecognitionService {
  final stt.SpeechToText _speech = stt.SpeechToText();

  bool get isListening => _speech.isListening;

  /// Initializes the recognizer for one voice-order session and requests
  /// the microphone/speech permission if it hasn't been granted yet (the
  /// plugin does this internally as part of `initialize()`). Re-running
  /// this per session (rather than caching a single init forever) keeps
  /// [onStatus]/[onError] pointed at whichever controller instance is
  /// live right now, which matters since the controller is recreated
  /// every time the Voice Order screen is opened.
  Future<SpeechAvailability> initialize({
    required void Function(String status) onStatus,
    required void Function(String errorMessage, {required bool permanent}) onError,
  }) async {
    try {
      final available = await _speech.initialize(
        onStatus: onStatus,
        onError: (error) => onError(error.errorMsg, permanent: error.permanent),
        debugLogging: false,
      );
      if (available) return SpeechAvailability.available;

      // initialize() returning false doesn't distinguish "denied
      // permission" from "no recognizer on this device" — hasPermission
      // reflects the actual OS permission state after that attempt, which
      // is the best signal the plugin exposes for telling the two apart.
      final granted = await _speech.hasPermission;
      return granted ? SpeechAvailability.unavailable : SpeechAvailability.permissionDenied;
    } catch (_) {
      return SpeechAvailability.unavailable;
    }
  }

  /// Starts one listening session. [onResult] fires for both partial and
  /// final results ([isFinal] distinguishes them); [onSoundLevelChange]
  /// drives the waveform animation with real microphone input level where
  /// the platform reports it. Recognition auto-stops after
  /// [VoiceOrderConfig.maxRecordingDuration] regardless of what's
  /// happening — see the 60s recording-limit requirement. Must be called
  /// after a successful [initialize].
  Future<void> startListening({
    required VoiceRecognitionLanguage language,
    required void Function(String text, bool isFinal) onResult,
    required void Function(double level) onSoundLevelChange,
  }) {
    return _speech.listen(
      onResult: (SpeechRecognitionResult result) {
        onResult(result.recognizedWords, result.finalResult);
      },
      onSoundLevelChange: onSoundLevelChange,
      listenOptions: stt.SpeechListenOptions(
        listenMode: stt.ListenMode.dictation,
        cancelOnError: false,
        partialResults: true,
        onDevice: false,
        listenFor: VoiceOrderConfig.maxRecordingDuration,
        pauseFor: VoiceOrderConfig.pauseBetweenWords,
        localeId: language.localeId,
      ),
    );
  }

  Future<void> stop() => _speech.stop();

  Future<void> cancel() => _speech.cancel();
}
