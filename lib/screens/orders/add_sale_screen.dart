import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../models/admin_customer_option.dart';
import '../../models/order.dart' as order_model;
import '../../models/order_item.dart' as order_item_model;
import '../../models/sale_line_item.dart';
import '../../providers/repository_providers.dart';
import 'widgets/order_share_actions.dart';
import 'widgets/sale_customer_picker_sheet.dart';
import 'widgets/sale_item_picker_sheet.dart';

/// Admin-initiated sale: the admin builds an order directly on a
/// customer's behalf (picks the customer, prices each line item
/// themselves) rather than the customer placing it through the shop.
/// Starts as a plain draft ("Sale") and becomes an invoiced, shareable
/// document ("Sale Invoice") once Generate Invoice is pressed — the same
/// two states as [OrderDetailScreen]'s pending/accepted split, just
/// admin-authored from the start instead of restaurant-placed.
class AddSaleScreen extends ConsumerStatefulWidget {
  const AddSaleScreen({super.key, this.orderId});

  final String? orderId;

  @override
  ConsumerState<AddSaleScreen> createState() => _AddSaleScreenState();
}

class _AddSaleScreenState extends ConsumerState<AddSaleScreen> {
  String? _orderId;
  String? _orderNumber;
  String? _invoiceNumber;
  AdminCustomerOption? _customer;
  DateTime _date = DateTime.now();
  final List<SaleLineItem> _items = [];
  double _receivedAmount = 0;
  final _receivedCtrl = TextEditingController();

  bool _loading = false;
  bool _saving = false;

  bool get _isInvoiced => _invoiceNumber != null;
  double get _totalQty => _items.fold<double>(0, (sum, i) => sum + i.quantity);
  double get _subtotal => _items.fold<double>(0, (sum, i) => sum + i.amount);
  double get _balanceDue => (_subtotal - _receivedAmount).clamp(0, double.infinity);

  @override
  void initState() {
    super.initState();
    _orderId = widget.orderId;
    if (_orderId != null) _load(_orderId!);
  }

  @override
  void dispose() {
    _receivedCtrl.dispose();
    super.dispose();
  }

  Future<void> _load(String orderId) async {
    setState(() => _loading = true);
    try {
      final draft = await ref.read(addSaleRepositoryProvider).fetchForEdit(orderId);
      setState(() {
        _orderId = draft.orderId;
        _orderNumber = draft.orderNumber;
        _invoiceNumber = draft.invoiceNumber;
        _customer = draft.customer;
        _date = draft.createdAt;
        _items
          ..clear()
          ..addAll(draft.items);
        _receivedAmount = draft.receivedAmount;
        _receivedCtrl.text = _receivedAmount == 0 ? '' : _receivedAmount.toStringAsFixed(0);
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not load sale: $e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _pickCustomer() async {
    final picked = await showSaleCustomerPicker(context);
    if (picked != null) setState(() => _customer = picked);
  }

  Future<void> _addItem() async {
    final item = await showSaleItemPicker(context);
    if (item != null) setState(() => _items.add(item));
  }

  /// Persists the current draft (creating the order if it doesn't exist
  /// yet) without necessarily generating an invoice — the "Save" action.
  Future<String> _persistDraft() async {
    final repo = ref.read(addSaleRepositoryProvider);
    var orderId = _orderId;
    orderId ??= await repo.createDraft(_customer!.id);
    await repo.replaceItems(orderId, _items);
    return orderId;
  }

  Future<void> _save() async {
    if (_customer == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a customer first')));
      return;
    }
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add at least one item')));
      return;
    }
    setState(() => _saving = true);
    try {
      final orderId = await _persistDraft();
      setState(() => _orderId = orderId);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sale saved')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _generateInvoice() async {
    if (_customer == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a customer first')));
      return;
    }
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add at least one item')));
      return;
    }
    setState(() => _saving = true);
    try {
      final repo = ref.read(addSaleRepositoryProvider);
      final orderId = await _persistDraft();
      await repo.generateInvoice(
        orderId: orderId,
        totalAmount: _subtotal,
        receivedAmount: _receivedAmount,
        customer: _customer!,
        method: 'Cash',
      );
      await _load(orderId);
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Invoice generated')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not generate invoice: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    if (_orderId == null) {
      if (mounted) Navigator.pop(context);
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete this sale?'),
        content: const Text("This removes the order and its invoice. This can't be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.crit600),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(addSaleRepositoryProvider).deleteSale(_orderId!);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not delete: $e')));
    }
  }

  void _shareInvoice() {
    if (_customer == null) return;
    final order = order_model.Order(
      id: _orderId!,
      customerId: _customer!.id,
      customerName: _customer!.name,
      customerPhone: _customer!.phone,
      orderNumber: _orderNumber ?? _orderId!,
      invoiceNumber: _invoiceNumber,
      items: [
        for (final item in _items)
          order_item_model.OrderItem(
            productId: item.itemId,
            name: item.itemName,
            emoji: '🥬',
            unit: item.unit,
            qty: item.quantity,
            rate: item.rate,
          ),
      ],
      total: _subtotal,
      status: order_model.OrderStatus.confirmed,
      paymentStatus: _receivedAmount >= _subtotal ? order_model.PaymentStatus.paid : order_model.PaymentStatus.pending,
      paymentMethod: 'Cash',
      placed: _date,
    );
    showModalBottomSheet(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.image_outlined),
              title: const Text('Share as Image'),
              onTap: () {
                Navigator.pop(sheetContext);
                shareOrderAsImage(context, ref, order);
              },
            ),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf_outlined),
              title: const Text('Share as PDF'),
              onTap: () {
                Navigator.pop(sheetContext);
                shareOrderAsPdf(context, ref, order);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isInvoiced ? 'Sale Invoice' : 'Sale')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.s4),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _InfoField(
                        label: _isInvoiced ? 'INVOICE NO' : 'ORDER NO',
                        value: _isInvoiced ? _invoiceNumber! : (_orderNumber ?? 'New'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s3),
                    Expanded(child: _InfoField(label: 'DATE', value: formatDate(_date))),
                  ],
                ),
                const SizedBox(height: AppSpacing.s3),
                InkWell(
                  borderRadius: BorderRadius.circular(8),
                  onTap: _orderId == null ? _pickCustomer : null,
                  child: _InfoField(
                    label: 'CUSTOMER NAME',
                    value: _customer?.name ?? 'Tap to select a customer',
                    valueColor: _customer == null ? AppColors.textMuted : null,
                    trailing: _orderId == null ? const Icon(Icons.chevron_right, color: AppColors.textMuted) : null,
                  ),
                ),
                if (_customer != null) ...[
                  const SizedBox(height: AppSpacing.s3),
                  _InfoField(label: 'PHONE NO.', value: _customer!.phone),
                ],
                const SizedBox(height: AppSpacing.s5),

                Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.primary.withValues(alpha: 0.28)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        color: AppColors.primary,
                        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s3, vertical: AppSpacing.s2),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Billed Items', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                            Text('Rate', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                      if (_items.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(AppSpacing.s4),
                          child: Text('No items added yet', style: TextStyle(color: AppColors.textMuted)),
                        )
                      else
                        for (var i = 0; i < _items.length; i++)
                          Dismissible(
                            key: ValueKey('${_items[i].itemId}_$i'),
                            direction: DismissDirection.endToStart,
                            background: Container(
                              color: AppColors.crit100,
                              alignment: Alignment.centerRight,
                              padding: const EdgeInsets.only(right: AppSpacing.s4),
                              child: const Icon(Icons.delete_outline, color: AppColors.crit600),
                            ),
                            onDismissed: (_) => setState(() => _items.removeAt(i)),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s3, vertical: AppSpacing.s2),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('#${i + 1}  ${_items[i].itemName}', style: const TextStyle(fontWeight: FontWeight.w700)),
                                        Text('Item Subtotal', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(formatInr(_items[i].amount), style: const TextStyle(fontWeight: FontWeight.w700)),
                                      Text(
                                        '${_items[i].quantity} × ${formatInr(_items[i].rate)}',
                                        style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.s3),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4, vertical: AppSpacing.s3),
                  decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Total Qty : ${_totalQty.toStringAsFixed(1)}'),
                      Text('Subtotal : ${formatInr(_subtotal)}', style: const TextStyle(fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.s3),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: _addItem,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Items'),
                  ),
                ),
                const SizedBox(height: AppSpacing.s5),

                Container(
                  padding: const EdgeInsets.all(AppSpacing.s4),
                  decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: [
                      _AmountRow(label: 'Total Amount', value: _subtotal, bold: true),
                      const SizedBox(height: AppSpacing.s3),
                      Row(
                        children: [
                          Checkbox(
                            value: _subtotal > 0 && _receivedAmount >= _subtotal,
                            onChanged: (checked) {
                              setState(() {
                                _receivedAmount = checked == true ? _subtotal : 0;
                                _receivedCtrl.text = _receivedAmount == 0 ? '' : _receivedAmount.toStringAsFixed(0);
                              });
                            },
                          ),
                          const Expanded(child: Text('Received')),
                          SizedBox(
                            width: 100,
                            child: TextField(
                              controller: _receivedCtrl,
                              textAlign: TextAlign.right,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(prefixText: '₹ ', isDense: true),
                              onChanged: (v) => setState(() => _receivedAmount = double.tryParse(v) ?? 0),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.s2),
                      _AmountRow(label: 'Balance Due', value: _balanceDue, bold: true),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.s4),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: _saving ? null : (_isInvoiced ? _shareInvoice : _generateInvoice),
                    child: _saving
                        ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(_isInvoiced ? 'Share Invoice' : 'Generate Invoice'),
                  ),
                ),
                const SizedBox(height: AppSpacing.s4),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _saving ? null : _delete,
                        child: const Text('Delete'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s3),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _saving ? null : _save,
                        child: const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

class _InfoField extends StatelessWidget {
  const _InfoField({required this.label, required this.value, this.valueColor, this.trailing});

  final String label;
  final String value;
  final Color? valueColor;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s3),
      decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 10, fontWeight: FontWeight.w600, letterSpacing: 1),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: valueColor ?? AppColors.textPrimary),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({required this.label, required this.value, this.bold = false});

  final String label;
  final double value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    final weight = bold ? FontWeight.w800 : FontWeight.w400;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: TextStyle(fontWeight: weight)),
        Text(formatInr(value), style: TextStyle(fontWeight: weight)),
      ],
    );
  }
}
