import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../models/category.dart';
import '../../../models/product.dart';
import '../../../providers/categories_providers.dart';
import '../../../providers/items_providers.dart';
import '../../../providers/repository_providers.dart';

/// Add/Edit Item — opens as a modal bottom sheet, never a separate page,
/// per the approved "Items → Add Item should not spawn a new page" rule.
Future<void> showItemFormSheet(BuildContext context, WidgetRef ref, {Product? editing}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => _ItemFormSheet(editing: editing),
  );
}

class _ItemFormSheet extends ConsumerStatefulWidget {
  final Product? editing;
  const _ItemFormSheet({this.editing});

  @override
  ConsumerState<_ItemFormSheet> createState() => _ItemFormSheetState();
}

class _ItemFormSheetState extends ConsumerState<_ItemFormSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _unitCtrl;
  late final TextEditingController _priceCtrl;
  late final TextEditingController _mrpCtrl;
  late final TextEditingController _stockCtrl;
  String? _categoryId;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.editing;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _unitCtrl = TextEditingController(text: p?.unit ?? 'kg');
    _priceCtrl = TextEditingController(text: p != null ? p.price.toStringAsFixed(0) : '');
    _mrpCtrl = TextEditingController(text: p != null ? p.mrp.toStringAsFixed(0) : '');
    _stockCtrl = TextEditingController(text: p?.stock?.toString() ?? '');
    _categoryId = p?.categoryId;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _unitCtrl.dispose();
    _priceCtrl.dispose();
    _mrpCtrl.dispose();
    _stockCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit(List<Category> categories) async {
    final name = _nameCtrl.text.trim();
    // Matches what the dropdown shows: an explicit pick, or the first
    // category if the admin never touched the dropdown.
    final effectiveCategoryId = _categoryId ?? (categories.isNotEmpty ? categories.first.id : null);
    if (name.isEmpty || effectiveCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item name and category are required')));
      return;
    }
    Category? category;
    for (final c in categories) {
      if (c.id == effectiveCategoryId) {
        category = c;
        break;
      }
    }
    if (category == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Selected category no longer exists — pick another.')));
      return;
    }
    final price = double.tryParse(_priceCtrl.text) ?? 0;
    final mrp = double.tryParse(_mrpCtrl.text) ?? price;
    final stock = int.tryParse(_stockCtrl.text);

    setState(() => _saving = true);
    try {
      final repo = ref.read(itemsRepositoryProvider);
      if (widget.editing != null) {
        await repo.update(widget.editing!.copyWith(
          name: name,
          categoryId: category.id,
          categoryName: category.name,
          unit: _unitCtrl.text.trim().isEmpty ? 'kg' : _unitCtrl.text.trim(),
          price: price,
          mrp: mrp,
          stock: stock,
        ));
      } else {
        await repo.create(
          name: name,
          categoryId: category.id,
          categoryName: category.name,
          unit: _unitCtrl.text.trim().isEmpty ? 'kg' : _unitCtrl.text.trim(),
          price: price,
          mrp: mrp,
          stock: stock,
        );
      }
      ref.invalidate(allItemsProvider);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save item: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider);
    final editing = widget.editing != null;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.s5,
        right: AppSpacing.s5,
        top: AppSpacing.s5,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.s5,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(editing ? 'Edit item' : 'Add item', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.s4),
            TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: 'Item name', hintText: 'e.g. Fresh Tomatoes')),
            const SizedBox(height: AppSpacing.s3),
            categoriesAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('Could not load categories: $e'),
              data: (categories) {
                final requested = _categoryId ?? (categories.isNotEmpty ? categories.first.id : null);
                final validId = categories.any((c) => c.id == requested) ? requested : null;
                return DropdownButtonFormField<String>(
                  value: validId,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: [
                    for (final c in categories) DropdownMenuItem(value: c.id, child: Text('${c.emoji} ${c.name}')),
                  ],
                  onChanged: (v) => setState(() => _categoryId = v),
                );
              },
            ),
            const SizedBox(height: AppSpacing.s3),
            TextField(controller: _unitCtrl, decoration: const InputDecoration(labelText: 'Unit', hintText: 'kg / dozen / piece')),
            const SizedBox(height: AppSpacing.s3),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _priceCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Selling price (₹)'),
                  ),
                ),
                const SizedBox(width: AppSpacing.s3),
                Expanded(
                  child: TextField(
                    controller: _mrpCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'MRP (₹)'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s3),
            TextField(
              controller: _stockCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Stock on hand (optional)',
                helperText: 'Admin-entered only — not used for any low-stock alerts.',
              ),
            ),
            const SizedBox(height: AppSpacing.s5),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                ),
                const SizedBox(width: AppSpacing.s3),
                Expanded(
                  child: categoriesAsync.maybeWhen(
                    data: (categories) => ElevatedButton(
                      onPressed: _saving ? null : () => _submit(categories),
                      child: _saving
                          ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : Text(editing ? 'Save changes' : 'Add item'),
                    ),
                    orElse: () => const ElevatedButton(onPressed: null, child: Text('Loading…')),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
