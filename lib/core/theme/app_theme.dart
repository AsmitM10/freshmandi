import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_spacing.dart';
import 'app_text_styles.dart';

class AppTheme {
  AppTheme._();

  /// Restaurant-facing app theme (features/*, shared/widgets).
  static ThemeData get theme => ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.background,
    fontFamily: AppTextStyles.fontFamily,
    // Loading this here (once, at app start) registers the "Poppins" family
    // with the engine under that exact name — which is what makes every
    // hardcoded `TextStyle(fontFamily: 'Poppins')` literal throughout the
    // app (there's no pubspec `fonts:` entry for it) actually render as
    // real Poppins instead of silently falling back to the OS default font.
    textTheme: GoogleFonts.poppinsTextTheme(),
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      primary: AppColors.primary,
      secondary: AppColors.secondary,
      surface: AppColors.background,
      error: AppColors.error,
    ),
    textSelectionTheme: const TextSelectionThemeData(
      cursorColor: AppColors.primary,
      selectionHandleColor: AppColors.primary,
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );

  /// Business Console (admin app, lib/screens/*) theme — ported 1:1 from
  /// its approved design system. Applied only to the admin route subtree
  /// via a `Theme(data: AppTheme.light, ...)` override in the router (see
  /// core/routing/app_router.dart), so it never affects the restaurant app
  /// theme above.
  static ThemeData get light {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.bg,
      colorScheme: const ColorScheme.light(
        primary: AppColors.navy600,
        onPrimary: AppColors.white,
        secondary: AppColors.brand600,
        onSecondary: AppColors.white,
        surface: AppColors.surface,
        onSurface: AppColors.textPrimary,
        error: AppColors.crit600,
        onError: AppColors.white,
        outline: AppColors.border,
      ),
    );

    final displayFont = GoogleFonts.manropeTextTheme();
    final bodyFont = GoogleFonts.publicSansTextTheme();

    final textTheme = bodyFont.copyWith(
      displayLarge: displayFont.displayLarge?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w800),
      displayMedium: displayFont.displayMedium?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w800),
      headlineLarge: displayFont.headlineLarge?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w800),
      headlineMedium: displayFont.headlineMedium?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w800),
      headlineSmall: displayFont.headlineSmall?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
      titleLarge: displayFont.titleLarge?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
      titleMedium: displayFont.titleMedium?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w700),
      titleSmall: displayFont.titleSmall?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
      bodyLarge: bodyFont.bodyLarge?.copyWith(color: AppColors.textPrimary),
      bodyMedium: bodyFont.bodyMedium?.copyWith(color: AppColors.textSecondary),
      bodySmall: bodyFont.bodySmall?.copyWith(color: AppColors.textMuted),
      labelLarge: bodyFont.labelLarge?.copyWith(color: AppColors.textPrimary, fontWeight: FontWeight.w600),
    );

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: const BorderSide(color: AppColors.border),
        ),
        margin: EdgeInsets.zero,
      ),
      dividerTheme: const DividerThemeData(color: AppColors.border, thickness: 1, space: 1),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.navy600,
          foregroundColor: AppColors.white,
          disabledBackgroundColor: AppColors.ink200,
          disabledForegroundColor: AppColors.ink400,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s5, vertical: AppSpacing.s3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          backgroundColor: AppColors.surface,
          side: const BorderSide(color: AppColors.border),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s5, vertical: AppSpacing.s3),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.navy600,
          textStyle: textTheme.labelLarge,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4, vertical: AppSpacing.s3),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          borderSide: const BorderSide(color: AppColors.navy600, width: 1.5),
        ),
        hintStyle: textTheme.bodyMedium,
      ),
      chipTheme: base.chipTheme.copyWith(
        backgroundColor: AppColors.neutral100,
        labelStyle: textTheme.labelLarge?.copyWith(fontSize: 12),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s3, vertical: AppSpacing.s1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.full)),
        side: BorderSide.none,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.brand100,
        surfaceTintColor: Colors.transparent,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 11,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? AppColors.brand700 : AppColors.textMuted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(color: selected ? AppColors.brand700 : AppColors.textMuted);
        }),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.ink900,
        contentTextStyle: const TextStyle(color: AppColors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sm)),
      ),
    );
  }
}
