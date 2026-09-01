import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/repositories/add_sale_repository.dart';
import '../../../models/sale_line_item.dart';
import '../../../providers/repository_providers.dart';

/// Two-step "Add Items" flow: search/pick a catalog item, then confirm
/// its quantity and rate (pre-filled from item_admin_pricing, still
/// editable — a per-sale price override, same as the deleted admin Add
/// Sale flow this replaces). Opens as a modal bottom sheet.
Future<SaleLineItem?> showSaleItemPicker(BuildContext context) {
  return showModalBottomSheet<SaleLineItem>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => const _SaleItemPickerSheet(),
  );
}

class _SaleItemPickerSheet extends ConsumerStatefulWidget {
  const _SaleItemPickerSheet();

  @override
  ConsumerState<_SaleItemPickerSheet> createState() => _SaleItemPickerSheetState();
}

class _SaleItemPickerSheetState extends ConsumerState<_SaleItemPickerSheet> {
  final _searchCtrl = TextEditingController();
  List<SaleCatalogItem>? _results;
  bool _loading = false;
  String? _error;
  SaleCatalogItem? _selected;

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
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await ref.read(addSaleRepositoryProvider).fetchCatalogItems(search: query);
      if (mounted) setState(() => _results = results);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_selected != null) {
      return _QuantityRateStep(
        item: _selected!,
        onBack: () => setState(() => _selected = null),
      );
    }
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
            Text('Add item', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.s4),
            TextField(
              controller: _searchCtrl,
              autofocus: true,
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search item…'),
              onChanged: _search,
            ),
            const SizedBox(height: AppSpacing.s3),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(child: Text('Could not load items: $_error', style: const TextStyle(color: AppColors.crit600)))
                      : (_results == null || _results!.isEmpty)
                          ? const Center(child: Text('No items found', style: TextStyle(color: AppColors.textMuted)))
                          : ListView.separated(
                              itemCount: _results!.length,
                              separatorBuilder: (context, index) => const Divider(height: 1),
                              itemBuilder: (context, index) {
                                final item = _results![index];
                                return ListTile(
                                  title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                                  subtitle: Text(item.unit),
                                  trailing: Text(formatInr(item.defaultRate), style: const TextStyle(fontWeight: FontWeight.w600)),
                                  onTap: () => setState(() => _selected = item),
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

class _QuantityRateStep extends StatefulWidget {
  const _QuantityRateStep({required this.item, required this.onBack});

  final SaleCatalogItem item;
  final VoidCallback onBack;

  @override
  State<_QuantityRateStep> createState() => _QuantityRateStepState();
}

class _QuantityRateStepState extends State<_QuantityRateStep> {
  late final TextEditingController _qtyCtrl;
  late final TextEditingController _rateCtrl;

  @override
  void initState() {
    super.initState();
    _qtyCtrl = TextEditingController(text: '1');
    _rateCtrl = TextEditingController(text: widget.item.defaultRate.toStringAsFixed(0));
  }

  @override
  void dispose() {
    _qtyCtrl.dispose();
    _rateCtrl.dispose();
    super.dispose();
  }

  void _confirm() {
    final qty = int.tryParse(_qtyCtrl.text) ?? 0;
    final rate = double.tryParse(_rateCtrl.text) ?? 0;
    if (qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid quantity')));
      return;
    }
    Navigator.pop(
      context,
      SaleLineItem(itemId: widget.item.id, itemName: widget.item.name, unit: widget.item.unit, quantity: qty, rate: rate),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.s5,
        right: AppSpacing.s5,
        top: AppSpacing.s5,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.s5,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(icon: const Icon(Icons.arrow_back), onPressed: widget.onBack, padding: EdgeInsets.zero, constraints: const BoxConstraints()),
              const SizedBox(width: AppSpacing.s2),
              Expanded(child: Text(widget.item.name, style: Theme.of(context).textTheme.titleLarge)),
            ],
          ),
          const SizedBox(height: AppSpacing.s4),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _qtyCtrl,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: 'Quantity (${widget.item.unit})'),
                ),
              ),
              const SizedBox(width: AppSpacing.s3),
              Expanded(
                child: TextField(
                  controller: _rateCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'Rate (₹)'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s5),
          SizedBox(
            width: double.infinity,
            child: FilledButton(onPressed: _confirm, child: const Text('Add to sale')),
          ),
        ],
      ),
    );
  }
}
