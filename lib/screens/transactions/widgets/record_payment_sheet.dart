import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../models/customer.dart';
import '../../../providers/customers_providers.dart';
import '../../../providers/repository_providers.dart';
import '../../../providers/transactions_providers.dart';

const _categories = ['Sale Payment', 'Order Payment', 'Owner Capital Introduced', 'Miscellaneous Income', 'Interest Income', 'Refund Received'];
const _methods = ['UPI', 'Cash', 'Bank Transfer', 'Card'];

Future<void> showRecordPaymentSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) => const _RecordPaymentSheet(),
  );
}

class _RecordPaymentSheet extends ConsumerStatefulWidget {
  const _RecordPaymentSheet();

  @override
  ConsumerState<_RecordPaymentSheet> createState() => _RecordPaymentSheetState();
}

class _RecordPaymentSheetState extends ConsumerState<_RecordPaymentSheet> {
  final _amountCtrl = TextEditingController();
  String _category = _categories.first;
  String _method = _methods.first;
  String? _customerId;
  bool _saving = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountCtrl.text) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter an amount to continue')));
      return;
    }
    setState(() => _saving = true);
    try {
      final customers = ref.read(allCustomersProvider).valueOrNull ?? const <Customer>[];
      Customer? customer;
      if (_customerId != null) {
        for (final c in customers) {
          if (c.id == _customerId) {
            customer = c;
            break;
          }
        }
      }
      await ref.read(transactionsRepositoryProvider).record(
            category: _category,
            partyId: customer?.id,
            partyName: customer?.businessName,
            amount: amount,
            method: _method,
          );
      ref.invalidate(transactionsListProvider);
      ref.invalidate(allTransactionsProvider);
      if (customer != null) ref.invalidate(customerDetailProvider(customer.id));
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not record payment: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(allCustomersProvider);

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
            Text('Record Payment', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: AppSpacing.s4),
            customersAsync.maybeWhen(
              data: (customers) {
                // If the previously selected id is no longer in a freshly
                // reloaded list, fall back to "no customer" rather than
                // asserting on a stale value.
                final validId = customers.any((c) => c.id == _customerId) ? _customerId : null;
                return DropdownButtonFormField<String?>(
                  value: validId,
                  isExpanded: true,
                  decoration: const InputDecoration(labelText: 'Customer (optional)'),
                  items: [
                    const DropdownMenuItem(value: null, child: Text('— No customer —')),
                    for (final c in customers) DropdownMenuItem(value: c.id, child: Text(c.businessName, overflow: TextOverflow.ellipsis)),
                  ],
                  onChanged: (v) => setState(() => _customerId = v),
                );
              },
              orElse: () => const LinearProgressIndicator(),
            ),
            const SizedBox(height: AppSpacing.s3),
            DropdownButtonFormField<String>(
              value: _category,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Category'),
              items: [for (final c in _categories) DropdownMenuItem(value: c, child: Text(c))],
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: AppSpacing.s3),
            TextField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Amount'),
            ),
            const SizedBox(height: AppSpacing.s3),
            DropdownButtonFormField<String>(
              value: _method,
              decoration: const InputDecoration(labelText: 'Method'),
              items: [for (final m in _methods) DropdownMenuItem(value: m, child: Text(m))],
              onChanged: (v) => setState(() => _method = v!),
            ),
            const SizedBox(height: AppSpacing.s5),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saving ? null : _submit,
                child: _saving
                    ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Save Payment'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
