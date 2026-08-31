import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../providers/transactions_providers.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/stat_card.dart';
import 'widgets/record_payment_sheet.dart';

/// Transactions — Money In only. Money Out / Expenses were removed from
/// scope entirely, not hidden.
class TransactionsScreen extends ConsumerWidget {
  const TransactionsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionsListProvider);
    final allTransactionsAsync = ref.watch(allTransactionsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Transactions')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showRecordPaymentSheet(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Record Payment'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(transactionsListProvider);
          ref.invalidate(allTransactionsProvider);
        },
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.s4),
          children: [
            allTransactionsAsync.when(
              loading: () => const SizedBox(height: 88, child: Center(child: CircularProgressIndicator())),
              error: (e, _) => ErrorStateView(error: e, onRetry: () => ref.invalidate(allTransactionsProvider)),
              data: (all) {
                final now = DateTime.now();
                final today = all.where((t) => t.date.year == now.year && t.date.month == now.month && t.date.day == now.day);
                final month = all.where((t) => t.date.year == now.year && t.date.month == now.month);
                final receivedToday = today.fold<double>(0, (sum, t) => sum + t.amount);
                final receivedMonth = month.fold<double>(0, (sum, t) => sum + t.amount);
                return Row(
                  children: [
                    Expanded(child: StatCard(label: 'Received', value: formatInr(receivedToday), period: 'Today', tone: StatTone.ok)),
                    const SizedBox(width: AppSpacing.s3),
                    Expanded(child: StatCard(label: 'Received', value: formatInr(receivedMonth), period: 'This Month', tone: StatTone.ok)),
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpacing.s4),
            TextField(
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search category or party…'),
              onChanged: (v) => ref.read(transactionsSearchProvider.notifier).state = v,
            ),
            const SizedBox(height: AppSpacing.s3),
            transactionsAsync.when(
              loading: () => const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
              error: (e, _) => ErrorStateView(error: e, onRetry: () => ref.invalidate(transactionsListProvider)),
              data: (list) {
                if (list.isEmpty) {
                  return const EmptyStateView(icon: Icons.receipt_long_outlined, title: 'No transactions found', body: 'Try a different search.');
                }
                return Card(
                  child: Column(
                    children: [
                      for (final t in list)
                        ListTile(
                          leading: const CircleAvatar(child: Icon(Icons.arrow_downward, size: 18)),
                          title: Text(t.category, style: const TextStyle(fontWeight: FontWeight.w600)),
                          subtitle: Text('${t.partyName ?? '—'} · ${formatDate(t.date)}'),
                          trailing: Text('+${formatInr(t.amount)}', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.w700)),
                        ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
