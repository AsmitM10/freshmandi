import 'package:flutter/material.dart';

/// Design tokens sourced from the FreshMandi Figma spec (source of truth).
/// Do not redefine these values inline in widgets — reference this class instead.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF4A8754);
  static const Color secondary = Color(0xFF355C7D);
  static const Color accentGreen = Color(0xFF7ED957);

  static const Color background = Color(0xFFFAF9F6);

  /// rgba(74, 135, 84, 0.04) — used as the fill for text field / upload field containers.
  static const Color inputBackground = Color(0x0A4A8754);

  static const Color otpFilled = Color(0xFFFFFFFF);
  static const Color otpEmpty = Color(0xFFE8EEE5);

  static const Color primaryText = Color(0xFF242424);
  static const Color secondaryText = Color(0xFF2F3136);
  static const Color placeholder = Color(0xFF6B7280);

  static const Color ctaText = Color(0xFFFFFEFC);
  static const Color fieldBorder = Color(0xFF4A8754);

  /// Terms & Conditions screen tokens.
  static const Color cardBorder = Color(0xFFE8E6DF);
  static const Color iconBgLight = Color(0x334A8754); // rgba(74,135,84,0.2)
  static const Color iconBgMuted = Color(0xFFD7E2D6);

  /// Error/success colors are NOT specified in the Figma file. These are
  /// implementation additions required for production error handling —
  /// flagged per the project's design-conflict rule, not sourced from Figma.
  static const Color error = Color(0xFFB3261E);
  static const Color success = Color(0xFF2E7D32);

  // ---------------------------------------------------------------------
  // Shop / Cart / Order tokens (Figma spec section O). Most of that
  // palette turns out to be the exact same colors already defined above
  // under different names — mapped in comments rather than duplicated:
  //   color.secondary      -> secondary        color.text.restaurant -> secondaryText
  //   color.surface.field  -> inputBackground   color.text.disabled   -> inputBackground
  //   color.border.field   -> cardBorder        color.border.otp      -> fieldBorder
  //   color.otp.inactive   -> otpEmpty          color.nav.active      -> secondary
  //   color.nav.inactive   -> placeholder       color.purchase.bg     -> primary
  //   color.text.onPrimary -> ctaText           color.text.secondary  -> placeholder
  // Only genuinely new values are added below.
  // ---------------------------------------------------------------------

  static const Color accentYellow = Color(0xFFE6B84A); // pending/warning status
  static const Color accentRed = Color(0xFFFF0000); // cart/notification badge dot

  static const Color backgroundHome = Color(0xFFFCFBF7);

  /// Bottom sheet / navbar / search bar / card-interior surface — same hex
  /// as [ctaText] but a distinct name since the *role* differs (surface vs.
  /// on-button text) even though Figma reused the value.
  static const Color surfaceWhite = Color(0xFFFFFEFC);

  /// rgba(255,255,255,0.1) — item cards, category cards, purchase sub-cards.
  static const Color surfaceCard = Color(0x1AFFFFFF);

  static const Color textHeading = Color(0xFF181818); // "Shop" screen title
  static const Color textTertiary = Color(0xFF808080); // screen subtitles

  // ---------------------------------------------------------------------
  // History screen tokens.
  // ---------------------------------------------------------------------
  static const Color labelGray = Color(0xFF707070); // "ORDER NO.", "ITEMS" etc.
  static const Color invoiceGreen = Color(0xFF2A8531); // invoice total amount
}
