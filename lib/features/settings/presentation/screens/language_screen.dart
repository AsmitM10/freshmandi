import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/localization/app_language.dart';
import '../../../../core/localization/language_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../l10n/gen/app_localizations.dart';

/// Language — reached from Settings' "Language" row. Selecting a language
/// updates [languageProvider] immediately (which the whole app,
/// including Voice Order's speech-recognition locale, reads from), no
/// restart required, and persists via SharedPreferences so it survives
/// closing/reopening the app.
///
/// No Figma export was provided for this screen — built to match the
/// existing Settings-family visual language (same header, same white
/// card-with-dividers list) rather than inventing a different style.
class LanguageScreen extends ConsumerWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final current = ref.watch(languageProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundHome,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _Header(title: l10n.languageScreenTitle, onBack: () => context.pop()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: AppColors.surfaceWhite,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: const [
                    BoxShadow(color: Color(0x3F000000), blurRadius: 4, offset: Offset(0, 1)),
                  ],
                ),
                child: Column(
                  children: [
                    _LanguageRow(
                      label: l10n.languageEnglish,
                      isSelected: current == AppLanguage.english,
                      onTap: () => ref.read(languageProvider.notifier).setLanguage(AppLanguage.english),
                    ),
                    const Divider(color: AppColors.cardBorder, height: 1),
                    _LanguageRow(
                      label: l10n.languageHindi,
                      isDevanagari: true,
                      isSelected: current == AppLanguage.hindi,
                      onTap: () => ref.read(languageProvider.notifier).setLanguage(AppLanguage.hindi),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.title, required this.onBack});

  final String title;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
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
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTextStyles.urbanistFontFamily,
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryText,
              ),
            ),
          ),
          const SizedBox(width: 32),
        ],
      ),
    );
  }
}

class _LanguageRow extends StatelessWidget {
  const _LanguageRow({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.isDevanagari = false,
  });

  final String label;
  final bool isSelected;
  final bool isDevanagari;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Poppins/Urbanist (this app's only bundled type families) have no
    // Devanagari glyphs — Hind is a Devanagari+Latin Google Font in the
    // same humanist-sans register, loaded on demand here so "हिंदी"
    // renders as real text everywhere, not just via best-effort OS
    // fallback (which Flutter Web in particular can't rely on).
    final labelStyle = TextStyle(
      color: AppColors.primaryText,
      fontSize: 16,
      fontFamily: AppTextStyles.urbanistFontFamily,
      fontWeight: FontWeight.w600,
      fontFamilyFallback: isDevanagari ? AppTextStyles.devanagariFallback : null,
    );

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        child: Row(
          children: [
            Expanded(child: Text(label, style: labelStyle)),
            if (isSelected)
              Container(
                width: 24,
                height: 24,
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                child: const Icon(Icons.check, color: AppColors.ctaText, size: 16),
              )
            else
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.cardBorder, width: 1.5),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
