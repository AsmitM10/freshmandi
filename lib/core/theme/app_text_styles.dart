import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// Poppins (+ Urbanist for a few roles, per Figma spec section P) typography
/// scale. Reference these instead of constructing ad-hoc TextStyles so the
/// type scale stays in one place.
class AppTextStyles {
  AppTextStyles._();

  static const String fontFamily = 'Poppins';
  static const String urbanistFontFamily = 'Urbanist';

  /// Neither Poppins nor Urbanist (this app's only two type families) has
  /// Devanagari glyphs, so Hindi text needs an explicit fallback — Hind is
  /// a Devanagari+Latin Google Font in the same humanist-sans register.
  /// Merge into any style used for localized text, e.g.
  /// `AppTextStyles.caption.copyWith(fontFamilyFallback: AppTextStyles.devanagariFallback)`.
  /// Relying on automatic OS font substitution alone isn't enough — it's
  /// inconsistent on native and largely absent on Flutter web, which is
  /// this app's primary dev/test target.
  static List<String> get devanagariFallback => [GoogleFonts.hind().fontFamily!];

  static const TextStyle heading = TextStyle(
    fontFamily: fontFamily,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryText,
  );

  static const TextStyle body = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.primaryText,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontFamily,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.primaryText,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.placeholder,
  );

  static const TextStyle cta = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.ctaText,
  );

  /// Field labels: 10px / 400, uppercase, letter-spacing 1px.
  /// Apply `.toUpperCase()` to the label string at the call site — this
  /// style only carries the typographic properties.
  static const TextStyle fieldLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: 10,
    fontWeight: FontWeight.w400,
    letterSpacing: 1,
    color: AppColors.primaryText,
  );

  // ---------------------------------------------------------------------
  // Shop / Cart / Order roles (Figma spec section P). text.heading.h1,
  // text.body.regular, text.body.subtitle, text.field.label and
  // text.cta.primary are identical to heading/bodySmall/caption/fieldLabel/
  // cta above and reuse them rather than duplicating. Urbanist roles use
  // `GoogleFonts.urbanist(...)` (not `const`, since GoogleFonts loads the
  // font lazily) — same self-registering mechanism as AppTheme's Poppins
  // load, so once any one of these is used the family is available
  // app-wide, including to any raw `fontFamily: 'Urbanist'` literal.
  // ---------------------------------------------------------------------

  /// "Shop", restaurant name — screen-level titles.
  static const TextStyle headingScreen = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w400,
    color: AppColors.primaryText,
  );

  /// Section headings ("Browse Category", "Frequently Ordered").
  static TextStyle get sectionHeading => GoogleFonts.urbanist(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.secondaryText,
  );

  /// Item card names — same metrics as [sectionHeading], different color.
  static TextStyle get itemName => GoogleFonts.urbanist(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryText,
  );

  /// Category card labels ("Vegetables", "Fruits", "Exotic Veg").
  static TextStyle get categoryLabel => GoogleFonts.urbanist(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryText,
  );

  /// Uppercase small labels ("TOTAL PURCHASE", "PAID", "PENDING").
  /// Apply `.toUpperCase()` to the label string at the call site.
  static const TextStyle labelUppercase = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.48,
    color: AppColors.primaryText,
  );

  /// Bottom navigation tab labels.
  static const TextStyle navLabel = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.placeholder,
  );

  /// Large currency amount (purchase total).
  static TextStyle get amountLarge => GoogleFonts.urbanist(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryText,
  );

  /// Medium currency amount (sub-totals).
  static TextStyle get amountMedium => GoogleFonts.urbanist(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryText,
  );

  /// Small links ("Resend OTP").
  static const TextStyle link = TextStyle(
    fontFamily: fontFamily,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.secondary,
    decoration: TextDecoration.underline,
  );

  /// "Repeat Order" link.
  static TextStyle get repeatLink => GoogleFonts.urbanist(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.secondary,
    decoration: TextDecoration.underline,
  );
}
