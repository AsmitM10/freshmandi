import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/utils/formatters.dart';
import '../widgets/stat_card.dart';

class SalesScreenStub extends StatelessWidget {
  const SalesScreenStub({super.key});

  static const _todaySales = [
    _SaleRecord(
      channel: 'Walk-in sales',
      customer: 'Aman Verma',
      items: '3 items',
      amount: 1520,
      time: '09:15 AM',
      status: 'Paid',
    ),
    _SaleRecord(
      channel: 'Phone order',
      customer: 'Neha Sharma',
      items: '2 items',
      amount: 980,
      time: '10:40 AM',
      status: 'Paid',
    ),
    _SaleRecord(
      channel: 'WhatsApp order',
      customer: 'Rohit Kumar',
      items: '5 items',
      amount: 2145,
      time: '11:10 AM',
      status: 'Pending',
    ),
    _SaleRecord(
      channel: 'Walk-in sales',
      customer: 'Priya Singh',
      items: '1 item',
      amount: 640,
      time: '01:25 PM',
      status: 'Paid',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final totalSales = _todaySales.fold<double>(0, (sum, sale) => sum + sale.amount);
    final payments = <String, double>{
      'Cash': 6400,
      'UPI': 5920,
      'Card': 3040,
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales register'),
        centerTitle: false,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        icon: const Icon(Icons.add),
        label: const Text('New sale'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {},
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.s4),
          children: [
            Row(
              children: [
                Expanded(
                  child: StatCard(
                    label: 'Sales today',
                    value: formatInr(totalSales),
                    period: 'Today',
                    tone: StatTone.ok,
                  ),
                ),
                const SizedBox(width: AppSpacing.s3),
                Expanded(
                  child: StatCard(
                    label: 'Average ticket',
                    value: formatInr(totalSales / _todaySales.length),
                    period: 'Per sale',
                    tone: StatTone.neutral,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s4),
            Container(
              padding: const EdgeInsets.all(AppSpacing.s2),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: const [
                  _FilterChip(label: 'Today', selected: true),
                  _FilterChip(label: 'This Week'),
                  _FilterChip(label: 'This Month'),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.s4),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.s4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Sales summary',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const Spacer(),
                        const Text('₹24,580', style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.ok600)),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s4),
                    Wrap(
                      spacing: AppSpacing.s3,
                      runSpacing: AppSpacing.s3,
                      children: payments.entries
                          .map((entry) => _PaymentPill(label: entry.key, value: formatInr(entry.value)))
                          .toList(),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s4),
            Text(
              'Recent sales',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: AppSpacing.s3),
            Card(
              child: Column(
                children: [
                  for (final sale in _todaySales)
                    ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4, vertical: AppSpacing.s2),
                      leading: CircleAvatar(
                        backgroundColor: AppColors.brand100,
                        foregroundColor: AppColors.brand600,
                        child: Text(sale.channel.substring(0, 1)),
                      ),
                      title: Row(
                        children: [
                          Text(sale.channel, style: const TextStyle(fontWeight: FontWeight.w700)),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: sale.status == 'Paid' ? AppColors.ok100 : AppColors.warn100,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              sale.status,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: sale.status == 'Paid' ? AppColors.ok600 : AppColors.warn600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      subtitle: Text('${sale.customer} · ${sale.items} · ${sale.time}'),
                      trailing: Text(
                        formatInr(sale.amount),
                        style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

class _SaleRecord {
  const _SaleRecord({
    required this.channel,
    required this.customer,
    required this.items,
    required this.amount,
    required this.time,
    required this.status,
  });

  final String channel;
  final String customer;
  final String items;
  final double amount;
  final String time;
  final String status;
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, this.selected = false});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: AppSpacing.s2),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? AppColors.brand100 : AppColors.ink50,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: selected ? AppColors.brand400 : AppColors.border),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? AppColors.brand700 : AppColors.textSecondary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _PaymentPill extends StatelessWidget {
  const _PaymentPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.brand50,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
          const SizedBox(width: 8),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
        ],
      ),
    );
  }
}
