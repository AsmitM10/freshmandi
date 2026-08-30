import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../shared/widgets/fm_error_banner.dart';
import '../../../../shared/widgets/fm_primary_button.dart';
import '../../data/admin_sales_repository.dart';
import '../../domain/admin_restaurant_option.dart';
import '../../domain/admin_transaction.dart';
import '../../domain/sale_line_item.dart';
import '../providers/admin_dashboard_providers.dart';
import '../providers/admin_sales_providers.dart';
import '../utils/admin_receipt_share.dart';
import '../widgets/add_sale_item_picker_sheet.dart';
import '../widgets/restaurant_picker_sheet.dart';

/// Admin "Add Sale" / "Sale Invoice" — the first admin screen that writes
/// real data (an order + order_items + invoice, the same tables the
/// restaurant-placed flow uses). Before an invoice exists this is "Sale":
/// "Save" persists a draft (order + items, no invoice yet, so it shows as
/// pending everywhere else the same way a restaurant-placed order does);
/// "Generate Invoice" finalizes it by adding the invoices row. Once
/// invoiced, the same screen relabels itself "Sale Invoice" (ORDER NO
/// becomes INVOICE NO, "Generate Invoice" becomes "Share Invoice") — Add
/// Items/Save/Delete all keep working, since an admin can still correct an
/// already-invoiced sale. The per-item "Rate" the admin enters here is
/// purely to compute this sale's total — it's stored on order_items but
/// never surfaced to the restaurant's own screens (see admin_add_sale
/// migration).
class AddSaleScreen extends ConsumerStatefulWidget {
  const AddSaleScreen({super.key, this.orderId});

  /// Tapping an existing transaction on the admin Home dashboard reopens
  /// this same screen with its data loaded, rather than a separate
  /// edit-only screen. Null means "new sale" (the default, blank state).
  final String? orderId;

  @override
  ConsumerState<AddSaleScreen> createState() => _AddSaleScreenState();
}

class _AddSaleScreenState extends ConsumerState<AddSaleScreen> {
  AdminRestaurantOption? _restaurant;
  final List<SaleLineItem> _items = [];
  DateTime _deliveryDate = DateTime.now();
  bool _isReceived = false;
  final _receivedController = TextEditingController(text: '0');

  AdminOrderRef? _order;
  String? _invoiceNumber;
  bool _isSaving = false;
  bool _isGenerating = false;
  bool _isSharing = false;
  bool _isDeleting = false;
  bool _isLoadingExisting = false;
  Object? _loadError;

  // Deliberately not derived from `_invoiceNumber` — reopening an
  // already-invoiced sale (tapping its card on Home) still lands on "Sale"
  // first; only an in-session "Generate Invoice" tap flips this screen over
  // to "Sale Invoice", per the required flow: card tap -> Sale -> Generate
  // Invoice -> Sale Invoice.
  bool _isInvoiced = false;

  @override
  void initState() {
    super.initState();
    if (widget.orderId != null) _loadExisting(widget.orderId!);
  }

  Future<void> _loadExisting(String orderId) async {
    setState(() {
      _isLoadingExisting = true;
      _loadError = null;
    });
    try {
      final draft = await ref
          .read(adminSalesRepositoryProvider)
          .fetchOrderForEdit(orderId);
      if (!mounted) return;
      setState(() {
        _order = draft.order;
        _restaurant = draft.restaurant;
        _deliveryDate = draft.deliveryDate;
        _items
          ..clear()
          ..addAll(draft.items);
        _isReceived = draft.invoiceTotal != null && draft.isPaid;
        _receivedController.text = _isReceived
            ? draft.invoiceTotal!.toStringAsFixed(0)
            : '0';
        _invoiceNumber = draft.invoiceNumber;
      });
    } catch (error) {
      if (mounted) setState(() => _loadError = error);
    } finally {
      if (mounted) setState(() => _isLoadingExisting = false);
    }
  }

  @override
  void dispose() {
    _receivedController.dispose();
    super.dispose();
  }

  double get _totalAmount =>
      _items.fold<double>(0, (sum, item) => sum + item.subtotal);

  double get _receivedAmount {
    if (!_isReceived) return 0;
    return double.tryParse(_receivedController.text.trim()) ?? 0;
  }

  double get _balance => _totalAmount - _receivedAmount;

  Future<void> _pickCustomer() async {
    final restaurant = await showRestaurantPickerSheet(context);
    if (restaurant != null) setState(() => _restaurant = restaurant);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deliveryDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _deliveryDate = picked);
  }

  Future<void> _addItem() async {
    final item = await showAddSaleItemPickerSheet(context);
    if (item != null) setState(() => _items.add(item));
  }

  void _removeItem(int index) {
    setState(() => _items.removeAt(index));
  }

  /// Creates the order on first Save/Generate Invoice, or updates the
  /// existing one, then replaces its line items with the current list.
  Future<void> _persistOrderAndItems() async {
    final repo = ref.read(adminSalesRepositoryProvider);
    if (_order == null) {
      _order = await repo.createOrder(
        restaurantId: _restaurant!.id,
        deliveryDate: _deliveryDate,
      );
    } else {
      await repo.updateOrderDeliveryDate(
        orderId: _order!.id,
        deliveryDate: _deliveryDate,
      );
    }
    await repo.replaceOrderItems(_order!.id, _items);
  }

  Future<void> _save() async {
    if (_restaurant == null) {
      showAppSnackBar(context, 'Select a customer first.');
      return;
    }
    setState(() => _isSaving = true);
    try {
      await _persistOrderAndItems();
      if (mounted) {
        setState(() {});
        showAppSnackBar(context, 'Saved as draft.');
      }
    } catch (error) {
      if (mounted) {
        showAppSnackBar(context, 'Could not save. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _generateInvoice() async {
    if (_restaurant == null) {
      showAppSnackBar(context, 'Select a customer first.');
      return;
    }
    if (_items.isEmpty) {
      showAppSnackBar(context, 'Add at least one item first.');
      return;
    }
    setState(() => _isGenerating = true);
    try {
      await _persistOrderAndItems();
      await ref
          .read(adminSalesRepositoryProvider)
          .generateInvoice(
            orderId: _order!.id,
            totalAmount: _totalAmount,
            isPaid: _totalAmount > 0 && _receivedAmount >= _totalAmount,
          );
      ref.invalidate(adminRevenueSummaryProvider);
      ref.invalidate(adminRecentTransactionsProvider);
      // Refetch rather than guessing the invoice number locally — it's
      // assigned by a database trigger (see admin_add_sale migration).
      final draft = await ref
          .read(adminSalesRepositoryProvider)
          .fetchOrderForEdit(_order!.id);
      if (mounted) {
        setState(() {
          _invoiceNumber = draft.invoiceNumber;
          _isInvoiced = true;
        });
        showAppSnackBar(context, 'Invoice generated.');
      }
    } catch (error) {
      if (mounted) {
        showAppSnackBar(
          context,
          'Could not generate the invoice. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  Future<void> _shareInvoice() async {
    if (_order == null || _isSharing) return;
    setState(() => _isSharing = true);
    try {
      await shareAdminReceipt(
        context,
        AdminTransaction(
          orderId: _order!.id,
          restaurantName: _restaurant?.restaurantName ?? '—',
          restaurantPhone: _restaurant?.phoneNumber ?? '—',
          orderNumber: _order!.orderNumber,
          invoiceNumber: _invoiceNumber,
          createdAt: _order!.createdAt,
          invoiceTotal: _totalAmount,
          isPaid: _isReceived && _receivedAmount >= _totalAmount,
        ),
        items: _items,
      );
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  Future<void> _delete() async {
    if (_order == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete this sale?'),
        content: const Text(
          'This removes the order and its invoice, if any. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isDeleting = true);
    try {
      await ref.read(adminSalesRepositoryProvider).deleteOrder(_order!.id);
      ref.invalidate(adminRevenueSummaryProvider);
      ref.invalidate(adminRecentTransactionsProvider);
      if (mounted) {
        showAppSnackBar(context, 'Sale deleted.');
        context.pop();
      }
    } catch (error) {
      if (mounted) {
        showAppSnackBar(context, 'Could not delete. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isBusy = _isSaving || _isGenerating || _isSharing || _isDeleting;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new,
            color: AppColors.primaryText,
            size: 20,
          ),
          onPressed: () => context.pop(),
        ),
        title: Text(
          // While an existing sale is still loading, neither label is known
          // yet to be correct — showing one and then flipping to the other
          // reads as a glitch, so stay blank until the fetch settles.
          _isLoadingExisting ? '' : (_isInvoiced ? 'Sale Invoice' : 'Sale'),
          style: const TextStyle(
            color: AppColors.primaryText,
            fontSize: 20,
            fontFamily: 'Urbanist',
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoadingExisting
            ? const Center(child: CircularProgressIndicator())
            : _loadError != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Could not load this sale.',
                        style: TextStyle(
                          color: AppColors.placeholder,
                          fontFamily: 'Poppins',
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => _loadExisting(widget.orderId!),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              )
            : _buildForm(context, isBusy),
      ),
    );
  }

  Widget _buildForm(BuildContext context, bool isBusy) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: _InfoBox(
                      label: _isInvoiced ? 'INVOICE NO' : 'ORDER NO',
                      value: _isInvoiced
                          ? _invoiceNumber!
                          : (_order?.orderNumber ?? '—'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _InfoBox(
                      label: 'DATE',
                      value: DateFormat('dd/MM/yyyy').format(_deliveryDate),
                      onTap: _pickDate,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _InfoBox(
                label: 'CUSTOMER NAME',
                value: _restaurant?.restaurantName ?? 'Tap to select customer',
                onTap: _pickCustomer,
              ),
              const SizedBox(height: 12),
              _InfoBox(
                label: 'PHONE NO.',
                value: _restaurant?.phoneNumber ?? '—',
              ),
              const SizedBox(height: 20),
              _BilledItemsCard(items: _items, onRemove: _removeItem),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.cardBorder),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Qty : ${_items.fold<int>(0, (sum, i) => sum + i.quantity)}',
                    ),
                    Text(
                      'Subtotal : ${NumberFormat('#,##0').format(_totalAmount)}',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: _addItem,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  side: const BorderSide(color: AppColors.cardBorder),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Add Items',
                  style: TextStyle(
                    color: AppColors.secondary,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              _AmountsCard(
                totalAmount: _totalAmount,
                isReceived: _isReceived,
                receivedController: _receivedController,
                balance: _balance,
                onReceivedToggle: (value) => setState(() {
                  _isReceived = value;
                  if (value) {
                    _receivedController.text = _totalAmount.toStringAsFixed(0);
                  }
                }),
                onReceivedChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 20),
              FMPrimaryButton(
                label: _isInvoiced ? 'Share Invoice' : 'Generate Invoice',
                isLoading: _isInvoiced ? _isSharing : _isGenerating,
                onPressed: isBusy
                    ? null
                    : (_isInvoiced ? _shareInvoice : _generateInvoice),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: (_order == null || isBusy) ? null : _delete,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    side: const BorderSide(color: AppColors.secondary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isDeleting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'Delete',
                          style: TextStyle(
                            color: AppColors.secondary,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: isBusy ? null : _save,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    backgroundColor: AppColors.secondary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Save',
                          style: TextStyle(
                            color: Colors.white,
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({required this.label, required this.value, this.onTap});

  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.cardBorder),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              label,
              style: const TextStyle(
                color: AppColors.primaryText,
                fontSize: 10,
                fontFamily: 'Poppins',
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: const TextStyle(
                color: AppColors.primaryText,
                fontSize: 14,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BilledItemsCard extends StatelessWidget {
  const _BilledItemsCard({required this.items, required this.onRemove});

  final List<SaleLineItem> items;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.cardBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            color: AppColors.primary,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Billed Items',
                  style: TextStyle(color: Colors.white, fontFamily: 'Poppins'),
                ),
                Text(
                  'Rate',
                  style: TextStyle(color: Colors.white, fontFamily: 'Poppins'),
                ),
              ],
            ),
          ),
          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Text(
                'No items added yet.',
                style: TextStyle(
                  color: AppColors.placeholder,
                  fontFamily: 'Poppins',
                ),
              ),
            )
          else
            for (var i = 0; i < items.length; i++)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                decoration: i == 0
                    ? null
                    : const BoxDecoration(
                        border: Border(
                          top: BorderSide(color: AppColors.cardBorder),
                        ),
                      ),
                child: Row(
                  children: [
                    Text(
                      '#${i + 1}  ',
                      style: const TextStyle(fontFamily: 'Poppins'),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            items[i].itemName,
                            style: const TextStyle(
                              fontFamily: 'Urbanist',
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Text(
                            'Item Subtotal',
                            style: TextStyle(
                              color: AppColors.secondaryText,
                              fontSize: 12,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹${NumberFormat('#,##0').format(items[i].subtotal)}',
                          style: const TextStyle(
                            fontFamily: 'Urbanist',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          '${items[i].rate.toStringAsFixed(0)} * ${items[i].quantity} = ${items[i].subtotal.toStringAsFixed(0)}₹',
                          style: const TextStyle(
                            color: AppColors.secondaryText,
                            fontSize: 12,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.close,
                        size: 16,
                        color: AppColors.placeholder,
                      ),
                      onPressed: () => onRemove(i),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }
}

class _AmountsCard extends StatelessWidget {
  const _AmountsCard({
    required this.totalAmount,
    required this.isReceived,
    required this.receivedController,
    required this.balance,
    required this.onReceivedToggle,
    required this.onReceivedChanged,
  });

  final double totalAmount;
  final bool isReceived;
  final TextEditingController receivedController;
  final double balance;
  final ValueChanged<bool> onReceivedToggle;
  final ValueChanged<String> onReceivedChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.cardBorder),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _AmountRow(label: 'Total Amount', value: totalAmount, bold: true),
          const Divider(height: 1, color: AppColors.cardBorder),
          Row(
            children: [
              Checkbox(
                value: isReceived,
                onChanged: (value) => onReceivedToggle(value ?? false),
              ),
              const Text(
                'Received',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              SizedBox(
                width: 100,
                child: TextField(
                  controller: receivedController,
                  enabled: isReceived,
                  textAlign: TextAlign.right,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: onReceivedChanged,
                  decoration: const InputDecoration(
                    prefixText: '₹ ',
                    border: InputBorder.none,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 1, color: AppColors.cardBorder),
          _AmountRow(label: 'Balance', value: balance, bold: true),
        ],
      ),
    );
  }
}

class _AmountRow extends StatelessWidget {
  const _AmountRow({
    required this.label,
    required this.value,
    this.bold = false,
  });

  final String label;
  final double value;
  final bool bold;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
          Text(
            '₹ ${NumberFormat('#,##0').format(value)}',
            style: TextStyle(
              fontFamily: 'Urbanist',
              fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
