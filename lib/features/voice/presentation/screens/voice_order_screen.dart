import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/voice_order_providers.dart';
import '../widgets/item_resolution_sheet.dart';

/// Voice Order — on-device speech recognition (speech_to_text, no cloud/
/// paid API) that turns a spoken order into real cart quantities. The
/// Figma export only defines two visual states (idle and listening); the
/// rest of the functional flow (recognized text, ambiguous-item picks,
/// cart merge) reuses those same two frames rather than inventing new
/// screens — recognized text appears in the existing hint card, and once
/// an order is generated it's merged straight into the app's real Cart
/// screen (already built) instead of a duplicate preview UI.
class VoiceOrderScreen extends ConsumerWidget {
  const VoiceOrderScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<VoiceOrderUiState>(voiceOrderControllerProvider, (previous, next) {
      if (next.status == VoiceOrderStatus.result) _handleResult(context, ref, next);
    });

    final state = ref.watch(voiceOrderControllerProvider);
    final controller = ref.read(voiceOrderControllerProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _Header(onBack: () => context.pop(), onCart: () => context.push(AppRoutes.cart)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Voice Order',
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 24,
                      fontFamily: AppTextStyles.urbanistFontFamily,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Text(
                    'Tap the mic and speak your order items',
                    style: TextStyle(
                      color: AppColors.primaryText,
                      fontSize: 12,
                      fontFamily: AppTextStyles.fontFamily,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _InstructionCard(state: state),
                ],
              ),
            ),
            Expanded(child: Center(child: _WaveformCircle(state: state))),
            _MicSection(state: state, controller: controller),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _GenerateListButton(state: state, controller: controller),
            ),
          ],
        ),
      ),
    );
  }

  void _handleResult(BuildContext context, WidgetRef ref, VoiceOrderUiState state) {
    if (!context.mounted) return;
    final controller = ref.read(voiceOrderControllerProvider.notifier);

    final ambiguousIndex = state.firstAmbiguousIndex;
    if (ambiguousIndex != -1) {
      final item = state.parsedItems[ambiguousIndex];
      showItemResolutionSheet(
        context,
        rawText: item.rawText,
        candidates: item.candidates,
        onSelect: (chosen) => controller.resolveAmbiguous(ambiguousIndex, chosen),
        onSkip: () => controller.discardAmbiguous(ambiguousIndex),
      );
      return; // resolving re-emits state -> this listener runs again for the next ambiguous item, if any.
    }

    final summary = controller.finalizeToCart();
    final messenger = ScaffoldMessenger.of(context);
    if (summary.addedItemCount == 0) {
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text("We couldn't find any items from your order.")));
      return;
    }
    if (summary.unmatchedCount > 0) {
      final itemWord = summary.unmatchedCount == 1 ? 'item' : 'items';
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(
              'Added ${summary.addedItemCount} item(s) to your cart. '
              "Couldn't identify ${summary.unmatchedCount} $itemWord.",
            ),
          ),
        );
    }
    context.go(AppRoutes.cart);
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack, required this.onCart});

  final VoidCallback onBack;
  final VoidCallback onCart;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: onBack,
                child: const Center(
                  child: Icon(Icons.arrow_back_ios_new, color: AppColors.primaryText, size: 20),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 32,
            height: 32,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: onCart,
                child: Center(
                  child: SvgPicture.asset(
                    'assets/icons/icon_cart.svg',
                    width: 24,
                    height: 24,
                    colorFilter: const ColorFilter.mode(AppColors.primaryText, BlendMode.srcIn),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InstructionCard extends StatelessWidget {
  const _InstructionCard({required this.state});

  final VoiceOrderUiState state;

  @override
  Widget build(BuildContext context) {
    final isError = state.status == VoiceOrderStatus.error && state.errorMessage != null;
    final text = isError
        ? state.errorMessage!
        : state.transcript.isNotEmpty
        ? state.transcript
        : 'Speak like "20 kilo tamatar" or "kal ka order repeat  karo"';

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 120),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: ShapeDecoration(
          color: AppColors.surfaceWhite,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          shadows: const [BoxShadow(color: Color(0x26000000), blurRadius: 10, offset: Offset(0, 4))],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isError ? AppColors.error : AppColors.primaryText,
            fontSize: 14,
            fontFamily: AppTextStyles.fontFamily,
            fontWeight: FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

/// The static glass-sphere illustration (lib/assets/images/voice.png,
/// unchanged) with a live overlay of animated bars on top, driven by real
/// microphone amplitude (`onSoundLevelChange` from speech_to_text) while
/// listening — this is the only part of the screen that moves; the
/// artwork itself is never redrawn or replaced.
class _WaveformCircle extends StatelessWidget {
  const _WaveformCircle({required this.state});

  final VoiceOrderUiState state;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 233,
      height: 233,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Image.asset('lib/assets/images/voice.png', width: 233, height: 233, fit: BoxFit.contain),
          _FrequencyBars(
            soundLevel: state.soundLevel,
            isActive: state.status == VoiceOrderStatus.listening,
          ),
        ],
      ),
    );
  }
}

class _FrequencyBars extends StatelessWidget {
  const _FrequencyBars({required this.soundLevel, required this.isActive});

  final double soundLevel;
  final bool isActive;

  // Mountain-shaped weights matching the 7 bars already drawn in
  // voice.png, tallest in the center — the center bar reacts most to
  // speech, tapering off toward the edges, same as the static artwork.
  static const _weights = [0.35, 0.6, 0.85, 1.0, 0.85, 0.6, 0.35];
  static const _baseHeight = 14.0;
  static const _maxExtra = 46.0;

  @override
  Widget build(BuildContext context) {
    if (!isActive) return const SizedBox(width: 120, height: 70);

    // speech_to_text reports sound level on a platform-specific scale
    // (observed roughly 0-10 on Android, negative dB approaching 0 on
    // iOS) — this isn't a documented fixed range, just a practical
    // heuristic that reacts well on both without needing a calibration
    // step.
    final normalized = ((soundLevel + 2) / 12).clamp(0.0, 1.0);

    return SizedBox(
      width: 120,
      height: 70,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          for (final weight in _weights) ...[
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              curve: Curves.easeOut,
              width: 5,
              height: _baseHeight + _maxExtra * normalized * weight,
              decoration: BoxDecoration(
                color: const Color(0xFFEFFFB0),
                borderRadius: BorderRadius.circular(4),
                boxShadow: const [
                  BoxShadow(color: Color(0x80EFFFB0), blurRadius: 6, spreadRadius: 1),
                ],
              ),
            ),
            const SizedBox(width: 6),
          ],
        ]..removeLast(),
      ),
    );
  }
}

class _MicSection extends StatelessWidget {
  const _MicSection({required this.state, required this.controller});

  final VoiceOrderUiState state;
  final VoiceOrderController controller;

  @override
  Widget build(BuildContext context) {
    final isListening = state.status == VoiceOrderStatus.listening;
    final isCheckingAvailability =
        state.status == VoiceOrderStatus.processing && state.transcript.isEmpty && state.parsedItems.isEmpty;

    return Column(
      children: [
        if (isListening) ...[
          Text(
            _formatDuration(state.remaining),
            style: const TextStyle(
              color: AppColors.secondary,
              fontSize: 20,
              fontFamily: AppTextStyles.urbanistFontFamily,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
        ],
        SizedBox(
          width: 53,
          height: 53,
          child: isCheckingAvailability
              ? const DecoratedBox(
                  decoration: BoxDecoration(color: AppColors.secondary, shape: BoxShape.circle),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.ctaText),
                  ),
                )
              : Material(
                  color: Colors.transparent,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: isListening ? controller.stopListening : controller.startListening,
                    child: SvgPicture.asset(
                      isListening ? 'assets/icons/icon_voice_pause.svg' : 'assets/icons/icon_voice_play.svg',
                      width: 53,
                      height: 53,
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _GenerateListButton extends StatelessWidget {
  const _GenerateListButton({required this.state, required this.controller});

  final VoiceOrderUiState state;
  final VoiceOrderController controller;

  @override
  Widget build(BuildContext context) {
    final isBusy =
        state.status == VoiceOrderStatus.processing && (state.transcript.isNotEmpty || state.parsedItems.isNotEmpty);

    return Container(
      width: double.infinity,
      height: 48,
      clipBehavior: Clip.antiAlias,
      decoration: ShapeDecoration(
        color: AppColors.secondary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        shadows: const [BoxShadow(color: Color(0x3F000000), blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isBusy ? null : controller.generateList,
          child: Center(
            child: isBusy
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text(
                    'Generate List',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontFamily: AppTextStyles.fontFamily,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
