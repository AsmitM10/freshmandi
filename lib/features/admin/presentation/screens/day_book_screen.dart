import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/fm_error_banner.dart';
import '../../domain/admin_transaction.dart';
import '../providers/admin_dashboard_providers.dart';
import '../utils/admin_receipt_share.dart';
import '../widgets/transaction_card.dart';

/// Every invoiced transaction for a single day — same Overview card style
/// as Home (scoped to that day's totals instead of all-time) plus the same
/// TransactionCard list, filtered by [adminDayBookTransactionsProvider].
class DayBookScreen extends ConsumerStatefulWidget {
  const DayBookScreen({super.key});

  @override
  ConsumerState<DayBookScreen> createState() => _DayBookScreenState();
}

class _DayBookScreenState extends ConsumerState<DayBookScreen> {
  late DateTime _selectedDate = _dateOnly(DateTime.now());
  String? _sharingOrderId;

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _selectedDate = _dateOnly(picked));
  }

  void _comingSoon(String label) {
    showAppSnackBar(context, '$label is coming soon.');
  }

  Future<void> _share(AdminTransaction transaction) async {
    if (_sharingOrderId != null) return;
    setState(() => _sharingOrderId = transaction.orderId);
    try {
      await shareAdminReceipt(context, transaction);
    } finally {
      if (mounted) setState(() => _sharingOrderId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(
      adminDayBookTransactionsProvider(_selectedDate),
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: SvgPicture.asset(
            'assets/icons/icon_back_chevron.svg',
            width: 24,
            height: 24,
          ),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Day Book',
          style: TextStyle(
            color: AppColors.primaryText,
            fontSize: 20,
            fontFamily: 'Urbanist',
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: SvgPicture.asset(
              'assets/icons/icon_kebab_menu.svg',
              width: 24,
              height: 24,
            ),
            onPressed: () => _comingSoon('More options'),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            children: [
              _DateBox(date: _selectedDate, onTap: _pickDate),
              const SizedBox(height: 20),
              Expanded(
                child: transactionsAsync.when(
                  data: (transactions) {
                    if (transactions.isEmpty) {
                      return const Center(child: _EmptyState());
                    }
                    final totalSale = transactions.fold<double>(
                      0,
                      (sum, t) => sum + t.invoiceTotal,
                    );
                    final youWillGet = transactions.fold<double>(
                      0,
                      (sum, t) => sum + t.balance,
                    );
                    return ListView(
                      children: [
                        _DayOverviewCard(
                          youWillGet: youWillGet,
                          sale: totalSale,
                        ),
                        const SizedBox(height: 20),
                        for (var i = 0; i < transactions.length; i++) ...[
                          TransactionCard(
                            index: i + 1,
                            transaction: transactions[i],
                            isSharing:
                                _sharingOrderId == transactions[i].orderId,
                            onTap: () => context.push(
                              AppRoutes.addSale,
                              extra: transactions[i].orderId,
                            ),
                            onPrint: () => _comingSoon('Print'),
                            onShare: () => _share(transactions[i]),
                          ),
                          if (i != transactions.length - 1)
                            const SizedBox(height: 12),
                        ],
                      ],
                    );
                  },
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (error, _) => const Center(
                    child: Text(
                      'Could not load this day.',
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
      ),
    );
  }
}

class _DateBox extends StatelessWidget {
  const _DateBox({required this.date, required this.onTap});

  final DateTime date;
  final VoidCallback onTap;

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
            const Text(
              'DATE',
              style: TextStyle(
                color: AppColors.primaryText,
                fontSize: 10,
                fontFamily: 'Poppins',
                letterSpacing: 1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              DateFormat('dd/MM/yyyy').format(date),
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

class _DayOverviewCard extends StatelessWidget {
  const _DayOverviewCard({required this.youWillGet, required this.sale});

  final double youWillGet;
  final double sale;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Overview',
            style: AppTextStyles.sectionHeading.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 19),
          Row(
            children: [
              Expanded(
                child: _DayOverviewStat(
                  amount: youWillGet,
                  label: 'YOU WILL GET',
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: _DayOverviewStat(amount: sale, label: 'SALE'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DayOverviewStat extends StatelessWidget {
  const _DayOverviewStat({required this.amount, required this.label});

  final double amount;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 90),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '₹${NumberFormat('#,##0').format(amount)}',
            style: AppTextStyles.amountLarge.copyWith(
              fontSize: 20,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.85),
              fontSize: 12,
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w500,
              letterSpacing: 0.48,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SvgPicture.asset(
            'assets/icons/icon_day_book_empty.svg',
            width: 150,
            height: 150,
          ),
          const SizedBox(height: 32),
          const Text(
            'No Data Available',
            style: TextStyle(
              color: AppColors.primaryText,
              fontSize: 20,
              fontFamily: 'Urbanist',
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'No data is available for this report. Please try again after making relevant changes.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.secondaryText,
              fontSize: 14,
              fontFamily: 'Poppins',
            ),
          ),
        ],
      ),
    );
  }
}
