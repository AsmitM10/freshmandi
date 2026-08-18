import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimens.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../items/domain/catalog_item.dart';

/// "Which item did you mean?" — shown when a spoken item phrase matched
/// more than one real catalog item and the app can't safely guess which
/// one was meant (per the ambiguous-item rule: never silently add a
/// random item). Not designed in Figma — same "minimal, design-consistent
/// state" treatment as [EmptyState]/[LoadingState] and the Return Order
/// reason-picker sheet.
Future<void> showItemResolutionSheet(
  BuildContext context, {
  required String rawText,
  required List<CatalogItem> candidates,
  required ValueChanged<CatalogItem> onSelect,
  required VoidCallback onSkip,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isDismissible: false,
    enableDrag: false,
    backgroundColor: AppColors.surfaceWhite,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(AppDimens.bottomSheetTopRadius)),
    ),
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(color: AppColors.cardBorder, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Which item did you mean?',
              style: const TextStyle(
                color: AppColors.primaryText,
                fontSize: 18,
                fontFamily: AppTextStyles.urbanistFontFamily,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'We heard "$rawText" — pick the item you meant.',
              style: AppTextStyles.caption,
            ),
            const SizedBox(height: 16),
            for (final candidate in candidates)
              _CandidateRow(
                item: candidate,
                onTap: () {
                  Navigator.of(context).pop();
                  onSelect(candidate);
                },
              ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  onSkip();
                },
                child: const Text(
                  "None of these — skip this item",
                  style: TextStyle(
                    color: AppColors.placeholder,
                    fontSize: 13,
                    fontFamily: AppTextStyles.fontFamily,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _CandidateRow extends StatelessWidget {
  const _CandidateRow({required this.item, required this.onTap});

  final CatalogItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 44,
                height: 44,
                child: item.imageUrl == null || item.imageUrl!.isEmpty
                    ? _imageFallback()
                    : CachedNetworkImage(
                        imageUrl: item.imageUrl!,
                        fit: BoxFit.cover,
                        errorWidget: (context, _, _) => _imageFallback(),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name, style: AppTextStyles.itemName.copyWith(fontSize: 15)),
                  Text(item.unit, style: AppTextStyles.caption),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.placeholder, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _imageFallback() {
    return Container(
      color: AppColors.inputBackground,
      child: const Icon(Icons.image_not_supported_outlined, color: AppColors.placeholder, size: 18),
    );
  }
}
