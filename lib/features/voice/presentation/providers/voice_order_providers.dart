import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/app_language.dart';
import '../../../../core/localization/language_provider.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../items/domain/catalog_item.dart';
import '../../../items/presentation/providers/items_providers.dart';
import '../../../orders/presentation/providers/cart_providers.dart';
import '../../data/speech_recognition_service.dart';
import '../../domain/item_matcher.dart';
import '../../domain/parsed_voice_item.dart';
import '../../domain/voice_order_combiner.dart';
import '../../domain/voice_order_config.dart';
import '../../domain/voice_order_parser.dart';

enum VoiceOrderStatus { idle, listening, processing, result, error }

class VoiceOrderUiState {
  const VoiceOrderUiState({
    this.status = VoiceOrderStatus.idle,
    this.transcript = '',
    this.soundLevel = 0,
    this.elapsed = Duration.zero,
    this.parsedItems = const [],
    this.errorMessage,
  });

  final VoiceOrderStatus status;
  final String transcript;

  /// Raw amplitude reported by the platform via `onSoundLevelChange` —
  /// drives the waveform's reaction to actual speech, not a fake/looping
  /// animation. Typical range is roughly -2 (silence) to 10 (loud speech)
  /// depending on platform; the screen normalizes it itself.
  final double soundLevel;

  final Duration elapsed;
  final List<ParsedVoiceItem> parsedItems;
  final String? errorMessage;

  Duration get remaining {
    final left = VoiceOrderConfig.maxRecordingDuration - elapsed;
    return left.isNegative ? Duration.zero : left;
  }

  bool get hasAmbiguous => parsedItems.any((i) => i.status == VoiceMatchStatus.ambiguous);

  int get firstAmbiguousIndex => parsedItems.indexWhere((i) => i.status == VoiceMatchStatus.ambiguous);

  int get matchedCount => parsedItems.where((i) => i.status == VoiceMatchStatus.matched).length;

  int get unmatchedCount => parsedItems.where((i) => i.status == VoiceMatchStatus.unmatched).length;

  VoiceOrderUiState copyWith({
    VoiceOrderStatus? status,
    String? transcript,
    double? soundLevel,
    Duration? elapsed,
    List<ParsedVoiceItem>? parsedItems,
    String? errorMessage,
    bool clearError = false,
  }) {
    return VoiceOrderUiState(
      status: status ?? this.status,
      transcript: transcript ?? this.transcript,
      soundLevel: soundLevel ?? this.soundLevel,
      elapsed: elapsed ?? this.elapsed,
      parsedItems: parsedItems ?? this.parsedItems,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// What merging the recognized order into the shared cart actually did —
/// enough for the screen to tell the user "found N, couldn't identify M"
/// before it navigates to Cart.
typedef VoiceOrderSummary = ({int addedItemCount, int unmatchedCount});

/// Drives the whole Voice Order screen. Owns the speech service, the
/// parse/match pipeline, and the merge into the shared cart — the screen
/// itself only renders [VoiceOrderUiState] and forwards taps here; it
/// never touches Supabase, the parser, the matcher, or the cart directly.
/// `autoDispose` so the mic/timers are always torn down the moment the
/// user leaves this screen, not just when they explicitly stop.
class VoiceOrderController extends AutoDisposeNotifier<VoiceOrderUiState> {
  late final SpeechRecognitionService _service;
  Timer? _elapsedTimer;
  DateTime? _listenStartedAt;

  /// Localized strings in whatever language Settings > Language currently
  /// has selected — looked up directly from the locale rather than a
  /// BuildContext, since this is a Riverpod controller, not a widget.
  AppLocalizations get _l10n => lookupAppLocalizations(ref.read(languageProvider).locale);

  @override
  VoiceOrderUiState build() {
    _service = SpeechRecognitionService();
    ref.onDispose(() {
      _elapsedTimer?.cancel();
      _service.cancel();
    });
    return const VoiceOrderUiState();
  }

  Future<void> startListening() async {
    if (state.status == VoiceOrderStatus.listening) return;

    state = const VoiceOrderUiState(status: VoiceOrderStatus.processing);
    final availability = await _service.initialize(onStatus: _handleStatus, onError: _handleError);

    if (availability != SpeechAvailability.available) {
      state = VoiceOrderUiState(
        status: VoiceOrderStatus.error,
        errorMessage: availability == SpeechAvailability.permissionDenied
            ? _l10n.voiceErrorPermission
            : _l10n.voiceErrorUnavailable,
      );
      return;
    }

    state = const VoiceOrderUiState(status: VoiceOrderStatus.listening);
    _listenStartedAt = DateTime.now();
    _elapsedTimer?.cancel();
    _elapsedTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final elapsed = DateTime.now().difference(_listenStartedAt!);
      if (elapsed >= VoiceOrderConfig.maxRecordingDuration) {
        stopListening();
        return;
      }
      state = state.copyWith(elapsed: elapsed);
    });

    // Speech recognition always listens in whatever language the app UI
    // is currently in — see VoiceRecognitionLanguageX.fromAppLanguage.
    // Switching Settings > Language takes effect on the very next
    // recording session (this is read fresh on each startListening()
    // call, never cached), no restart needed.
    final voiceLanguage = VoiceRecognitionLanguageX.fromAppLanguage(ref.read(languageProvider));

    await _service.startListening(
      language: voiceLanguage,
      onResult: (text, isFinal) {
        if (state.status != VoiceOrderStatus.listening) return;
        state = state.copyWith(transcript: text);
        if (isFinal) _finishListening();
      },
      onSoundLevelChange: (level) {
        if (state.status != VoiceOrderStatus.listening) return;
        state = state.copyWith(soundLevel: level);
      },
    );
  }

  void _handleStatus(String status) {
    if (status == 'notListening' && state.status == VoiceOrderStatus.listening) {
      _finishListening();
    }
  }

  void _handleError(String message, {required bool permanent}) {
    if (state.status != VoiceOrderStatus.listening) return;
    if (state.transcript.trim().isEmpty) {
      _elapsedTimer?.cancel();
      state = state.copyWith(status: VoiceOrderStatus.error, errorMessage: _l10n.voiceErrorGeneric);
    } else {
      // Some words were already captured before the error fired — process
      // what was heard instead of discarding it.
      _finishListening();
    }
  }

  /// Manual stop (mic button tapped mid-listen) or the natural end of an
  /// utterance — both just finalize the transcript. Actually running it
  /// through the parser/matcher is a separate, explicit step (Generate
  /// List), matching the Figma flow where recording and generating the
  /// list are two distinct actions.
  Future<void> stopListening() async {
    if (state.status != VoiceOrderStatus.listening) return;
    _elapsedTimer?.cancel();
    await _service.stop();
    // Give the platform's own final-result/status callback a brief moment
    // to arrive naturally; if it never does (observed on some devices
    // when nothing was heard), finish manually so the UI can't get stuck
    // in "listening" forever after the user taps stop.
    await Future.delayed(const Duration(milliseconds: 300));
    _finishListening();
  }

  void _finishListening() {
    if (state.status != VoiceOrderStatus.listening) return;
    _elapsedTimer?.cancel();
    final transcript = state.transcript.trim();
    state = transcript.isEmpty
        ? state.copyWith(
            status: VoiceOrderStatus.error,
            errorMessage: _l10n.voiceErrorNoSpeech,
          )
        : state.copyWith(status: VoiceOrderStatus.idle);
  }

  /// "Generate List" — stops listening if still active, then runs the
  /// transcript through the parser and the real-catalog matcher. Never
  /// invents an item: every [ParsedVoiceItem] is either matched to a real
  /// [CatalogItem], flagged ambiguous with real candidates, or unmatched.
  Future<void> generateList() async {
    if (state.status == VoiceOrderStatus.listening) {
      await stopListening();
    }
    if (state.status == VoiceOrderStatus.error) return;

    final transcript = state.transcript.trim();
    if (transcript.isEmpty) {
      state = state.copyWith(
        status: VoiceOrderStatus.error,
        errorMessage: "We couldn't hear an order. Please try again.",
      );
      return;
    }
    await _processTranscript(transcript);
  }

  Future<void> _processTranscript(String transcript) async {
    state = state.copyWith(status: VoiceOrderStatus.processing, clearError: true);

    List<CatalogItem> catalog;
    try {
      // Reuses the already-cached catalog fetch (same provider Shop/Cart
      // use) rather than issuing a fresh Supabase query per voice order.
      catalog = await ref.read(catalogProvider.future);
    } catch (_) {
      state = state.copyWith(
        status: VoiceOrderStatus.error,
        errorMessage: _l10n.voiceErrorCatalog,
      );
      return;
    }

    const parser = VoiceOrderParser();
    const matcher = ItemMatcher();
    final segments = parser.parse(transcript);

    if (segments.isEmpty || catalog.isEmpty) {
      state = state.copyWith(
        status: VoiceOrderStatus.error,
        errorMessage: _l10n.voiceErrorNoItems,
      );
      return;
    }

    final results = <ParsedVoiceItem>[
      for (final segment in segments)
        () {
          final match = matcher.match(segment.nameCandidate, catalog);
          return ParsedVoiceItem(
            rawText: segment.nameCandidate,
            quantity: segment.quantity,
            status: match.status,
            matchedItem: match.item,
            candidates: match.candidates,
          );
        }(),
    ];

    final foundAnything = results.any(
      (r) => r.status == VoiceMatchStatus.matched || r.status == VoiceMatchStatus.ambiguous,
    );
    if (!foundAnything) {
      state = state.copyWith(
        status: VoiceOrderStatus.error,
        errorMessage: _l10n.voiceErrorNoItems,
        parsedItems: results,
      );
      return;
    }

    state = state.copyWith(status: VoiceOrderStatus.result, parsedItems: results);
  }

  void resolveAmbiguous(int index, CatalogItem chosen) {
    final next = [...state.parsedItems];
    next[index] = next[index].copyWith(
      status: VoiceMatchStatus.matched,
      matchedItem: chosen,
      candidates: const [],
    );
    state = state.copyWith(parsedItems: next);
  }

  void discardAmbiguous(int index) {
    final next = [...state.parsedItems];
    next[index] = next[index].copyWith(status: VoiceMatchStatus.unmatched, candidates: const []);
    state = state.copyWith(parsedItems: next);
  }

  void removeItem(int index) {
    final next = [...state.parsedItems]..removeAt(index);
    state = state.copyWith(parsedItems: next);
  }

  void updateQuantity(int index, int quantity) {
    if (quantity <= 0) {
      removeItem(index);
      return;
    }
    final next = [...state.parsedItems];
    final item = next[index];
    next[index] = ParsedVoiceItem(
      rawText: item.rawText,
      quantity: quantity,
      status: item.status,
      matchedItem: item.matchedItem,
      candidates: item.candidates,
    );
    state = state.copyWith(parsedItems: next);
  }

  /// Merges every matched item into the shared cart — reusing
  /// [CartNotifier.addQuantities] so a voice order adds on top of
  /// whatever's already in the cart rather than replacing it — summing
  /// duplicate items said twice in the same command along the way (the
  /// "5 kg tomato ... 3 kg tomato" -> 8 kg rule).
  VoiceOrderSummary finalizeToCart() {
    final quantities = combineMatchedQuantities(state.parsedItems);
    if (quantities.isNotEmpty) {
      ref.read(cartProvider.notifier).addQuantities(quantities);
    }
    return (addedItemCount: quantities.length, unmatchedCount: state.unmatchedCount);
  }

  void reset() {
    _elapsedTimer?.cancel();
    _service.cancel();
    state = const VoiceOrderUiState();
  }
}

final voiceOrderControllerProvider = NotifierProvider.autoDispose<VoiceOrderController, VoiceOrderUiState>(
  VoiceOrderController.new,
);
