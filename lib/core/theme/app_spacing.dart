/// Spacing scale + fixed component dimensions from the Figma spec (sections
/// N/S/W). Reference these instead of ad-hoc `SizedBox(height: 16)` literals
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
}
