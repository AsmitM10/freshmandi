import 'package:flutter/material.dart';

/// Shadow tokens from the Figma spec. Both values were previously inlined
/// separately in FMPrimaryButton and the Terms card — centralized here per
/// "do not scatter values that belong to the design system."
class AppShadows {
  AppShadows._();

  /// 0px 2px 4px rgba(0,0,0,0.25) — CTA buttons.
  static const List<BoxShadow> cta = [
    BoxShadow(color: Color(0x40000000), blurRadius: 4, offset: Offset(0, 2)),
  ];

  /// 0px 1px 4px rgba(0,0,0,0.25) — cards (Terms card, item/category cards).
  static const List<BoxShadow> card = [
    BoxShadow(color: Color(0x40000000), blurRadius: 4, offset: Offset(0, 1)),
  ];
}
