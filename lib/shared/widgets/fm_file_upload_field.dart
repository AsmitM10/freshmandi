import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_dimens.dart';
import '../../core/theme/app_text_styles.dart';

/// FSSAI certificate picker field. Figma shows the field's filled/label
/// style and a "Drop Image here (Max 2 MB)" placeholder; it does not define
/// a selected/loading visual state, so a small trailing icon is used to
/// signal tappability and progress — a minimal, documented addition.
class FMFileUploadField extends StatelessWidget {
  const FMFileUploadField({
    super.key,
    required this.label,
    required this.onTap,
    this.selectedFileName,
    this.onClear,
    this.errorText,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback onTap;
  final String? selectedFileName;
  final VoidCallback? onClear;
  final String? errorText;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final hasError = errorText != null && errorText!.isNotEmpty;
    final hasFile = selectedFileName != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isLoading ? null : onTap,
            borderRadius: BorderRadius.circular(AppDimens.fieldRadius),
            child: Semantics(
              label: 'FSSAI certificate upload',
              button: true,
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(minHeight: 64),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.inputBackground,
                  borderRadius: BorderRadius.circular(AppDimens.fieldRadius),
                  border: hasError ? Border.all(color: AppColors.error) : null,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label.toUpperCase(), style: AppTextStyles.fieldLabel),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            hasFile
                                ? selectedFileName!
                                : 'Drop Image here (Max 2 MB)',
                            style: hasFile
                                ? AppTextStyles.bodySmall
                                : AppTextStyles.caption,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (isLoading)
                          const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        else if (hasFile && onClear != null)
                          GestureDetector(
                            onTap: onClear,
                            child: const Icon(
                              Icons.close,
                              size: 18,
                              color: AppColors.placeholder,
                            ),
                          )
                        else
                          const Icon(
                            Icons.upload_file_outlined,
                            size: 18,
                            color: AppColors.placeholder,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
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
