/// Spacing scale + fixed component dimensions from the Figma spec (sections
/// N/S/W), used by the restaurant-facing app (features/*, shared/widgets).
/// Reference these instead of ad-hoc `SizedBox(height: 16)` literals
/// scattered through screens.
class AppSpacing {
  AppSpacing._();

  // Generic gap scale — inferred from the repeated values actually used
  // across both Figma specs (field gaps, section gaps, card padding).
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double base = 16;
  static const double lg = 20;
  static const double xl = 24;

  // Item grid (Shop screens).
  static const double gridGap = 12;
  static const int gridColumns = 2;
  static const double itemCardHeight = 140;
  static const double itemCardImageWidth = 88;
  static const double itemCardImageHeight = 90;

  // Category cards (Browse Category section).
  static const double categoryCardWidth = 106;
  static const double categoryCardHeight = 140;

  // Search bar.
  static const double searchBarHeight = 55;

  // Bottom navigation + voice button.
  static const double bottomNavHeight = 127;
  static const double voiceButtonInnerSize = 58;
  static const double voiceButtonOuterPadding = 10;

  // Purchase summary card (Home screen).
  static const double purchaseCardHeight = 176;
  static const double purchaseCardReferenceWidth = 343;

  // =======================================================================
  // Business Console (admin app, lib/screens/*) 8px spacing system —
  // ported 1:1 from its `--sp-*` styles.css tokens. Kept as a separate
  // section since none of these names collide with the scale above.
  // =======================================================================
  static const s1 = 4.0;
  static const s2 = 8.0;
  static const s3 = 12.0;
  static const s4 = 16.0;
  static const s5 = 20.0;
  static const s6 = 24.0;
  static const s7 = 32.0;
  static const s8 = 40.0;
  static const s9 = 48.0;
  static const s10 = 64.0;
}

/// Corner radii for the Business Console — ported from `--r-*` in its
/// approved styles.css. The restaurant-facing app hardcodes its own radii
/// inline per-widget rather than through a shared scale.
class AppRadius {
  AppRadius._();

  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const full = 999.0;
}
