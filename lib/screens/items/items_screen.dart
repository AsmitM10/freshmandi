import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../data/repositories/categories_repository.dart';
import '../../models/product.dart';
import '../../providers/items_providers.dart';
import '../../providers/repository_providers.dart';
import '../../widgets/empty_state.dart';
import 'widgets/add_category_sheet.dart';
import 'widgets/add_item_sheet.dart';

/// Items — ONE single screen: search + list (Item / Category / Price /
/// Actions) with "+ Add Item" and "+ Add Category" opening modal bottom
/// sheets, never separate pages. No Availability/Stock column — see
/// README.md "Implementation notes".
class ItemsScreen extends ConsumerWidget {
  const ItemsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(filteredItemsProvider);
    final selectedCategory = ref.watch(itemsCategoryFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Items'),
        actions: [
          IconButton(
            icon: const Icon(Icons.category_outlined),
            tooltip: 'Add category',
            onPressed: () => showAddCategorySheet(context, ref),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showItemFormSheet(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Add Item'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.s4, AppSpacing.s3, AppSpacing.s4, AppSpacing.s2),
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search item or SKU…',
                  ),
                  onChanged: (v) => ref.read(itemsSearchProvider.notifier).state = v,
                ),
                const SizedBox(height: AppSpacing.s3),
                Align(
                  alignment: Alignment.centerLeft,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final option in ['All', ...CategoriesRepository.approvedFilterCategories])
                          Padding(
                            padding: const EdgeInsets.only(right: AppSpacing.s2),
                            child: ChoiceChip(
                              label: Text(option == 'All' ? 'All categories' : option),
                              selected: selectedCategory == option,
                              onSelected: (_) => ref.read(itemsCategoryFilterProvider.notifier).state = option,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: itemsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => ErrorStateView(error: e, onRetry: () => ref.invalidate(allItemsProvider)),
              data: (items) {
                if (items.isEmpty) {
                  return const EmptyStateView(
                    icon: Icons.search_off,
                    title: 'No items found',
                    body: 'Try a different search or category.',
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(allItemsProvider),
                  child: ListView.separated(
                    padding: const EdgeInsets.only(bottom: 88),
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) => _ItemRow(item: items[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemRow extends ConsumerWidget {
  final Product item;
  const _ItemRow({required this.item});

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Delete "${item.name}"?'),
        content: const Text("This removes the item from your catalogue. This can't be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.crit600),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete item'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(itemsRepositoryProvider).delete(item.id);
      ref.invalidate(allItemsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('"${item.name}" deleted')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      onTap: () => showItemFormSheet(context, ref, editing: item),
      leading: CircleAvatar(backgroundColor: AppColors.brand50, child: Text(item.emoji)),
      title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w700)),
      subtitle: Text(item.categoryName),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(formatInr(item.price), style: const TextStyle(fontWeight: FontWeight.w700)),
          IconButton(
            icon: const Icon(Icons.edit_outlined, size: 20),
            onPressed: () => showItemFormSheet(context, ref, editing: item),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.crit600),
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
    );
  }
}
