import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_shadows.dart';
import '../../core/theme/app_text_styles.dart';

/// The primary CTA: 48px tall, secondary-color fill, 8px radius, drop
/// shadow — per the Figma "Primary CTA" token. Also covers the "loading
/// button" behavior (disabled + spinner while [isLoading]) so idle/loading/
/// disabled states live in one widget instead of a near-duplicate class.
class FMPrimaryButton extends StatelessWidget {
  const FMPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null || isLoading;
    return Container(
      width: double.infinity,
      height: AppDimens.primaryCtaHeight,
      decoration: BoxDecoration(
        color: isDisabled ? AppColors.secondary.withValues(alpha: 0.5) : AppColors.secondary,
        borderRadius: BorderRadius.circular(AppDimens.ctaRadius),
        boxShadow: AppShadows.cta,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDimens.ctaRadius),
          onTap: isDisabled ? null : onPressed,
          child: Center(
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      valueColor: AlwaysStoppedAnimation<Color>(AppColors.ctaText),
                    ),
                  )
                : Text(label, style: AppTextStyles.cta),
          ),
        ),
      ),
    );
  }
}
