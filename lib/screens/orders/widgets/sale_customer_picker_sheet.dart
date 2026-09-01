import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../models/admin_customer_option.dart';
import '../../../providers/repository_providers.dart';

/// Search-and-pick a restaurant to build a sale for. Opens as a modal
/// bottom sheet, same "never a separate page" convention as the other
/// admin add/edit sheets.
Future<AdminCustomerOption?> showSaleCustomerPicker(BuildContext context) {
  return showModalBottomSheet<AdminCustomerOption>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => const _SaleCustomerPickerSheet(),
  );
}

class _SaleCustomerPickerSheet extends ConsumerStatefulWidget {
  const _SaleCustomerPickerSheet();

  @override
  ConsumerState<_SaleCustomerPickerSheet> createState() => _SaleCustomerPickerSheetState();
}

class _SaleCustomerPickerSheetState extends ConsumerState<_SaleCustomerPickerSheet> {
  final _searchCtrl = TextEditingController();
  List<AdminCustomerOption>? _results;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _search('');
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    setState(() => _loading = true);
    try {
      final results = await ref.read(addSaleRepositoryProvider).searchCustomers(query);
      if (mounted) setState(() => _results = results);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.75,
      child: Padding(
        padding: EdgeInsets.only(
          left: AppSpacing.s5,
          right: AppSpacing.s5,
          top: AppSpacing.s5,
          bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.s5,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select customer', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.s4),
            TextField(
              controller: _searchCtrl,
              autofocus: true,
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search restaurant name…'),
              onChanged: _search,
            ),
            const SizedBox(height: AppSpacing.s3),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : (_results == null || _results!.isEmpty)
                      ? const Center(child: Text('No approved customers found', style: TextStyle(color: AppColors.textMuted)))
                      : ListView.separated(
                          itemCount: _results!.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) {
                            final customer = _results![index];
                            return ListTile(
                              leading: const CircleAvatar(child: Icon(Icons.storefront_outlined)),
                              title: Text(customer.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                              subtitle: Text(customer.phone),
                              onTap: () => Navigator.pop(context, customer),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
