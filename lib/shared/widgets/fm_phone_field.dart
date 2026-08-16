import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/constants/app_config.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_text_styles.dart';

/// PHONE NO. field: a visually non-editable "+91" prefix, a vertical
/// divider, then a 10-digit input — per the Figma spec. [controller] holds
/// only the 10 local digits; combine with Validators.toE164 when submitting.
class FMPhoneField extends StatelessWidget {
  const FMPhoneField({
    super.key,
    required this.controller,
    this.errorText,
    this.onChanged,
    this.enabled = true,
  });

  final TextEditingController controller;
  final String? errorText;
  final ValueChanged<String>? onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null && errorText!.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.inputBackground,
            borderRadius: BorderRadius.circular(AppDimens.fieldRadius),
            border: hasError ? Border.all(color: AppColors.error) : null,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('PHONE NO.', style: AppTextStyles.fieldLabel),
              const SizedBox(height: 4),
              SizedBox(
                height: 28,
                child: Row(
                  children: [
                    const Text('+91', style: AppTextStyles.bodySmall),
                    const SizedBox(width: 8),
                    Container(width: 1, height: 16, color: AppColors.placeholder),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Semantics(
                        label: 'Phone number',
                        textField: true,
                        child: TextFormField(
                          controller: controller,
                          enabled: enabled,
                          keyboardType: TextInputType.phone,
                          maxLength: AppConfig.phoneDigitLength,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          onChanged: onChanged,
                          textAlignVertical: TextAlignVertical.top,
                          decoration: const InputDecoration(
                            isDense: true,
                            counterText: '',
                            contentPadding: EdgeInsets.zero,
                            border: InputBorder.none,
                            hintText: '9876543210',
                            hintStyle: AppTextStyles.caption,
                          ),
                          style: AppTextStyles.bodySmall,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (hasError)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: Text(
              errorText!,
              style: const TextStyle(
                color: AppColors.error,
                fontSize: 12,
                fontFamily: AppTextStyles.fontFamily,
              ),
            ),
          ),
      ],
    );
  }
}
