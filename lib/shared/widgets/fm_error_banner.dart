import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

/// Error/success feedback is not defined in Figma. This SnackBar helper is
/// the single place that styles it, so error copy stays consistent instead
/// of being redesigned ad hoc per screen.
void showAppSnackBar(
  BuildContext context,
  String message, {
  bool isError = true,
}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        backgroundColor: isError ? AppColors.error : AppColors.success,
        content: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontFamily: AppTextStyles.fontFamily,
            fontSize: 14,
          ),
        ),
      ),
    );
}
