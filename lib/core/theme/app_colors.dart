import 'package:flutter/material.dart';

/// Design tokens sourced from the FreshMandi Figma spec (source of truth)
/// for the restaurant-facing app (features/*, shared/widgets). Do not
/// redefine these values inline in widgets — reference this class instead.
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

  /// "Paid" status badge fill — brighter/more saturated than [accentGreen]
  /// (used for "Live" text and similar accents), per the pill-button order
  /// card redesign.
  static const Color statusPaidGreen = Color(0xFF3DF574);

  // =======================================================================
  // Business Console (admin app, lib/screens/*) design tokens — ported 1:1
  // from its approved `styles.css` design system (sage green brand + navy
  // interactive, warm cream neutrals). Kept as a separate, clearly-scoped
  // section rather than merged into the restaurant-app tokens above: the
  // two UIs were designed independently and none of these names collide
  // with the ones above, so both can reference this single AppColors class
  // without either app's palette changing. Do not introduce new colors
  // here without an approved design update.
  // =======================================================================

  // ---- Brand: sage green (identity, hero surfaces, success, checkmarks)
  static const brand900 = Color(0xFF1E2F1B);
  static const brand800 = Color(0xFF2B4327);
  static const brand700 = Color(0xFF3E5637);
  static const brand600 = Color(0xFF4C6C46);
  static const brand500 = Color(0xFF598559);
  static const brand400 = Color(0xFF7A9F72);
  static const brand300 = Color(0xFF9FBC97);
  static const brand100 = Color(0xFFE3EDDE);
  static const brand50 = Color(0xFFF3F7F0);

  // ---- Navy: interactive/action (buttons, links, active nav, focus)
  static const navy900 = Color(0xFF1C2A38);
  static const navy800 = Color(0xFF263A4C);
  static const navy700 = Color(0xFF324A60);
  static const navy600 = Color(0xFF3E5B7A);
  static const navy500 = Color(0xFF52708F);
  static const navy400 = Color(0xFF7891A8);
  static const navy100 = Color(0xFFE4EAF0);
  static const navy50 = Color(0xFFF1F4F7);

  // ---- Accent (turmeric/mango — sparing use: badges, chart 2nd series)
  static const accent600 = Color(0xFFB3791C);
  static const accent500 = Color(0xFFDB9A2E);
  static const accent100 = Color(0xFFFBEDD4);

  // ---- Neutrals (warm, cream-leaning — matches FreshMandi customer app)
  static const ink900 = Color(0xFF23261F);
  static const ink800 = Color(0xFF2E3228);
  static const ink700 = Color(0xFF454A3E);
  static const ink600 = Color(0xFF5E6355);
  static const ink500 = Color(0xFF797F6E);
  static const ink400 = Color(0xFF9A9F8F);
  static const ink300 = Color(0xFFC0C4B7);
  static const ink200 = Color(0xFFDEE1D6);
  static const ink150 = Color(0xFFE9EAE0);
  static const ink100 = Color(0xFFF1F2EA);
  static const ink50 = Color(0xFFFAF8F3);
  static const white = Color(0xFFFFFFFF);

  // ---- Status semantics
  static const ok600 = Color(0xFF3E8C43);
  static const ok100 = Color(0xFFE5F4E4);
  static const warn600 = Color(0xFFB5731A);
  static const warn100 = Color(0xFFFBEEDC);
  static const crit600 = Color(0xFFAA2617);
  static const crit100 = Color(0xFFFBE4E1);
  static const info600 = Color(0xFF3E5B7A);
  static const info100 = Color(0xFFE4EAF0);
  static const neutral600 = Color(0xFF5E6355);
  static const neutral100 = Color(0xFFEFF0E8);

  // ---- Surfaces / text (light theme — the only theme the approved
  // design was reviewed in; dark-mode tokens exist in styles.css but were
  // never shown to the client, so they are intentionally NOT ported here)
  static const bg = ink50;
  static const surface = white;
  static const surfaceTint = brand50;
  static const border = ink150;
  static const borderStrong = ink200;

  static const textPrimary = ink900;
  static const textSecondary = ink600;
  static const textMuted = ink400;
  static const textOnBrand = white;
}
