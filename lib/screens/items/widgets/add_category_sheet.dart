import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../providers/categories_providers.dart';
import '../../../providers/repository_providers.dart';

/// Opens as a modal bottom sheet — never a separate page — per the
/// approved "Items → Add Category should not spawn a new page" rule.
Future<void> showAddCategorySheet(BuildContext context, WidgetRef ref) {
  final nameCtrl = TextEditingController();
  final emojiCtrl = TextEditingController(text: '🧺');

  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.s5,
        right: AppSpacing.s5,
        top: AppSpacing.s5,
        bottom: MediaQuery.of(sheetContext).viewInsets.bottom + AppSpacing.s5,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Add category', style: Theme.of(sheetContext).textTheme.titleLarge),
          const SizedBox(height: AppSpacing.s4),
          TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: 'Category name', hintText: 'e.g. Bakery')),
          const SizedBox(height: AppSpacing.s3),
          TextField(controller: emojiCtrl, decoration: const InputDecoration(labelText: 'Emoji icon'), maxLength: 2),
          const SizedBox(height: AppSpacing.s3),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(onPressed: () => Navigator.pop(sheetContext), child: const Text('Cancel')),
              ),
              const SizedBox(width: AppSpacing.s3),
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    final name = nameCtrl.text.trim();
                    if (name.isEmpty) {
                      ScaffoldMessenger.of(sheetContext).showSnackBar(const SnackBar(content: Text('Category name is required')));
                      return;
                    }
                    await ref.read(categoriesRepositoryProvider).create(
                          name: name,
                          emoji: emojiCtrl.text.trim().isEmpty ? '🧺' : emojiCtrl.text.trim(),
                        );
                    ref.invalidate(categoriesProvider);
                    if (sheetContext.mounted) Navigator.pop(sheetContext);
                  },
                  child: const Text('Add category'),
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}
