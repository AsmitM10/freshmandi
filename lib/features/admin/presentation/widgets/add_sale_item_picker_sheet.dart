import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../items/domain/catalog_item.dart';
import '../../../items/presentation/providers/items_providers.dart';
import '../../domain/sale_line_item.dart';
import '../screens/add_sale_item_detail_screen.dart';

/// Search the real catalog (same one Shop uses) and, after picking an
/// item, enter quantity + rate — reusing the real catalog means an admin
/// sale can never reference an item that doesn't actually exist.
Future<SaleLineItem?> showAddSaleItemPickerSheet(BuildContext context) {
  return showModalBottomSheet<SaleLineItem>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surfaceWhite,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => const _ItemPickerContent(),
  );
}

class _ItemPickerContent extends ConsumerStatefulWidget {
  const _ItemPickerContent();

  @override
  ConsumerState<_ItemPickerContent> createState() => _ItemPickerContentState();
}

class _ItemPickerContentState extends ConsumerState<_ItemPickerContent> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _pickItem(CatalogItem item) async {
    final result = await Navigator.of(context).push<SaleLineItem>(
      MaterialPageRoute(
        builder: (context) => AddSaleItemDetailScreen(item: item),
      ),
    );
    if (result != null && mounted) Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final catalogAsync = ref.watch(catalogProvider);

    return SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Add Item',
                    style: TextStyle(
                      color: AppColors.primaryText,
                      fontSize: 18,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.placeholder),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                controller: _searchController,
                onChanged: (value) =>
                    setState(() => _query = value.trim().toLowerCase()),
                decoration: InputDecoration(
                  hintText: 'Search items...',
                  prefixIcon: const Icon(
                    Icons.search,
                    color: AppColors.placeholder,
                  ),
                  filled: true,
                  fillColor: AppColors.inputBackground,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: catalogAsync.when(
                data: (items) {
                  final filtered = _query.isEmpty
                      ? items
                      : items
                            .where(
                              (item) =>
                                  item.name.toLowerCase().contains(_query),
                            )
                            .toList();
                  if (filtered.isEmpty) {
                    return const Center(
                      child: Text(
                        'No items match.',
                        style: TextStyle(
                          color: AppColors.placeholder,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 8,
                    ),
                    itemCount: filtered.length,
                    separatorBuilder: (context, index) =>
                        const Divider(color: AppColors.cardBorder, height: 1),
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(
                          item.name,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          item.unit,
                          style: const TextStyle(fontFamily: 'Poppins'),
                        ),
                        onTap: () => _pickItem(item),
                      );
                    },
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => const Center(
                  child: Text(
                    'Could not load items.',
                    style: TextStyle(
                      color: AppColors.placeholder,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
