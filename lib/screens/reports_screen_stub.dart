import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';
import '../core/utils/formatters.dart';
import '../widgets/stat_card.dart';

class ReportsScreenStub extends StatelessWidget {
  const ReportsScreenStub({super.key});

  static const _summary = [
    _ReportMetric(label: 'Gross sales', value: 248560, trend: '+12.4%', tone: 'ok'),
    _ReportMetric(label: 'Orders', value: 1842, trend: '+8.1%', tone: 'neutral'),
    _ReportMetric(label: 'Avg. basket', value: 1348, trend: '+4.7%', tone: 'ok'),
    _ReportMetric(label: 'Returns', value: 97, trend: '-1.8%', tone: 'warn'),
  ];

  static const _salesBreakdown = [
    ('Walk-ins', 92000),
    ('Online', 66000),
    ('Phone', 41000),
    ('WhatsApp', 31560),
  ];

  static const _topItems = [
    _TopItem(name: 'Organic Tomatoes', sales: 16800, units: 426),
    _TopItem(name: 'Bananas', sales: 14550, units: 710),
    _TopItem(name: 'Cucumber', sales: 11840, units: 356),
    _TopItem(name: 'Potato', sales: 9750, units: 398),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        centerTitle: false,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        icon: const Icon(Icons.file_download_outlined),
        label: const Text('Export'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.s4),
        children: [
          Row(
            children: const [
              _FilterChip(label: 'Sales', selected: true),
              _FilterChip(label: 'Orders'),
              _FilterChip(label: 'Customers'),
              _FilterChip(label: 'Products'),
            ],
          ),
          const SizedBox(height: AppSpacing.s4),
          Text(
            'Sales overview',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.s3),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: AppSpacing.s3,
            crossAxisSpacing: AppSpacing.s3,
            childAspectRatio: 1.45,
            children: [
              for (final metric in _summary)
                StatCard(
                  label: metric.label,
                  value: metric.label == 'Gross sales'
                      ? formatInr(metric.value)
                      : metric.label == 'Orders'
                          ? '${metric.value.round()}'
                          : metric.label == 'Avg. basket'
                              ? formatInr(metric.value)
                              : '${metric.value.round()}',
                  period: metric.trend,
                  tone: metric.tone == 'ok' ? StatTone.ok : metric.tone == 'warn' ? StatTone.warn : StatTone.neutral,
                ),
            ],
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
                        'Channel mix',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const Spacer(),
                      const Text('This month', style: TextStyle(color: AppColors.textMuted)),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s4),
                  ..._salesBreakdown.map((entry) {
                    final percent = (entry.$2 / 228560) * 100;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.s3),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(child: Text(entry.$1, style: const TextStyle(fontWeight: FontWeight.w600))),
                              Text(formatInr(entry.$2), style: const TextStyle(fontWeight: FontWeight.w700)),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.s2),
                          LinearProgressIndicator(
                            value: percent / 100,
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(999),
                            backgroundColor: AppColors.ink150,
                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.brand600),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s4),
          Text(
            'Top products',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.s3),
          Card(
            child: Column(
              children: [
                for (final item in _topItems)
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4, vertical: AppSpacing.s1),
                    leading: CircleAvatar(
                      backgroundColor: AppColors.brand100,
                      foregroundColor: AppColors.brand700,
                      child: const Icon(Icons.shopping_basket_rounded, size: 18),
                    ),
                    title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                    subtitle: Text('${item.units} units sold'),
                    trailing: Text(formatInr(item.sales), style: const TextStyle(fontWeight: FontWeight.w800)),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _ReportMetric {
  const _ReportMetric({
    required this.label,
    required this.value,
    required this.trend,
    required this.tone,
  });

  final String label;
  final num value;
  final String trend;
  final String tone;
}

class _TopItem {
  const _TopItem({
    required this.name,
    required this.sales,
    required this.units,
  });

  final String name;
  final double sales;
  final int units;
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
