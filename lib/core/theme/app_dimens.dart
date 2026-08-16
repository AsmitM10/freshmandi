/// Spacing, radius and reference-frame dimensions from the Figma spec.
/// The Figma reference frame is 375x812 — these are proportions to preserve,
/// not hard pixel values to force onto every screen size.
class AppDimens {
  AppDimens._();

  static const double referenceWidth = 375;
  static const double referenceHeight = 812;

  static const double fieldRadius = 8;
  static const double ctaRadius = 8;
  static const double otpRadius = 4;
  static const double screenRadius = 32;
  static const double bottomSheetTopRadius = 24;

  /// Primary CTA reference dimensions (343x48 at reference width).
  static const double primaryCtaReferenceWidth = 343;
  static const double primaryCtaHeight = 48;
}
