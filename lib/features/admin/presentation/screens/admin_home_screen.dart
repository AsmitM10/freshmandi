import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/fm_error_banner.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/admin_revenue_summary.dart';
import '../../domain/admin_transaction.dart';
import '../../presentation/widgets/share_transaction_sheet.dart';
import '../../presentation/widgets/transaction_card.dart';
import '../providers/admin_dashboard_providers.dart';
import '../utils/admin_receipt_share.dart';

/// Admin dashboard Home tab. "Add Sale" opens the Sale screen, "Day Book"
/// opens the day-scoped transactions screen, and "All Txns Report" / "See
/// All" both open the date-range transactions screen — all real. Per-
/// transaction print is still a UI-only stub (no backend query for it
/// yet). The Overview totals and Transactions list below them are real,
/// live aggregate queries over every restaurant's orders/invoices —
/// nothing on this screen is placeholder/lorem-ipsum data. The share icon
/// opens a real "Share Transaction" sheet whose Share option generates and
/// shares an actual
/// receipt image (see [_shareReceipt]) — WhatsApp and SMS in that sheet
/// trigger the exact same flow, since neither's URL scheme can carry a
/// file attachment; the native share/download flow is the only way any
/// app gets a real image into either.
class AdminHomeScreen extends ConsumerStatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  ConsumerState<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends ConsumerState<AdminHomeScreen> {
  String? _sharingOrderId;

  void _comingSoon(BuildContext context, String label) {
    showAppSnackBar(context, '$label is coming soon.');
  }

  // WhatsApp/SMS and Share all end up generating and sharing the same
  // receipt image — there's no platform (web or native) that lets an app
  // attach a file straight into WhatsApp or SMS via a URL scheme, so the
  // only real way to get the image into either is the same native
  // share/download flow "Share" already uses, letting the person pick
  // WhatsApp themselves from that list. The three buttons stay separate
  // labels/icons as a hint toward that destination, not distinct behavior.
  void _showShareSheet(BuildContext context, AdminTransaction transaction) {
    showShareTransactionSheet(
      context,
      onWhatsApp: () => _shareReceipt(context, transaction),
      onSms: () => _shareReceipt(context, transaction),
      onShare: () => _shareReceipt(context, transaction),
    );
  }

  Future<void> _shareReceipt(
    BuildContext context,
    AdminTransaction transaction,
  ) async {
    if (_sharingOrderId != null) return;
    setState(() => _sharingOrderId = transaction.orderId);
    try {
      await shareAdminReceipt(context, transaction);
    } finally {
      if (mounted) setState(() => _sharingOrderId = null);
    }
  }

  void _showAccountSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 12, 20, 4),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'More admin settings are coming soon.',
                    style: TextStyle(
                      color: AppColors.placeholder,
                      fontSize: 13,
                      fontFamily: 'Poppins',
                    ),
                  ),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.logout, color: AppColors.primaryText),
                title: const Text(
                  'Sign out',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w500,
                  ),
                ),
                onTap: () async {
                  Navigator.of(context).pop();
                  await ref.read(authRepositoryProvider).signOut();
                  if (context.mounted) context.go(AppRoutes.welcome);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final summaryAsync = ref.watch(adminRevenueSummaryProvider);
    final transactionsAsync = ref.watch(adminRecentTransactionsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(adminRevenueSummaryProvider);
            ref.invalidate(adminRecentTransactionsProvider);
          },
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              _Header(
                onNotificationTap: () => _comingSoon(context, 'Notifications'),
                onSettingsTap: () => _showAccountSheet(context, ref),
              ),
              const SizedBox(height: 20),
              _OverviewCard(summaryAsync: summaryAsync),
              const SizedBox(height: 12),
              _QuickActionsCard(
                onAddSale: () => context.push(AppRoutes.addSale),
                onDayBook: () => context.push(AppRoutes.dayBook),
                onAllTxnsReport: () => context.push(AppRoutes.allTransactions),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Transactions',
                    style: TextStyle(
                      color: AppColors.primaryText,
                      fontSize: 18,
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.push(AppRoutes.allTransactions),
                    child: const Text(
                      'See All',
                      style: TextStyle(
                        color: AppColors.secondary,
                        fontSize: 14,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              transactionsAsync.when(
                data: (transactions) {
                  if (transactions.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'No transactions yet.',
                          style: TextStyle(
                            color: AppColors.placeholder,
                            fontSize: 14,
                            fontFamily: 'Poppins',
                          ),
                        ),
                      ),
                    );
                  }
                  return Column(
                    children: [
                      for (var i = 0; i < transactions.length; i++) ...[
                        TransactionCard(
                          index: i + 1,
                          transaction: transactions[i],
                          isSharing: _sharingOrderId == transactions[i].orderId,
                          onTap: () => context.push(
                            AppRoutes.addSale,
                            extra: transactions[i].orderId,
                          ),
                          onPrint: () => _comingSoon(context, 'Print'),
                          onShare: () =>
                              _showShareSheet(context, transactions[i]),
                        ),
                        if (i != transactions.length - 1)
                          const SizedBox(height: 12),
                      ],
                    ],
                  );
                },
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, _) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'Could not load transactions.',
                      style: const TextStyle(
                        color: AppColors.placeholder,
                        fontSize: 14,
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

class _Header extends StatelessWidget {
  const _Header({required this.onNotificationTap, required this.onSettingsTap});

  final VoidCallback onNotificationTap;
  final VoidCallback onSettingsTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: Color(0xFFD9D9D9),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Admin',
              style: TextStyle(
                color: AppColors.secondaryText,
                fontSize: 20,
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w400,
              ),
            ),
          ],
        ),
        Row(
          children: [
            InkWell(
              onTap: onNotificationTap,
              child: SvgPicture.asset(
                'assets/icons/icon_admin_notification.svg',
                width: 24,
                height: 24,
              ),
            ),
            const SizedBox(width: 16),
            InkWell(
              onTap: onSettingsTap,
              child: SvgPicture.asset(
                'assets/icons/icon_admin_settings.svg',
                width: 24,
                height: 24,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.summaryAsync});

  final AsyncValue<AdminRevenueSummary> summaryAsync;

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
          summaryAsync.when(
            data: (summary) => Row(
              children: [
                Expanded(
                  child: _OverviewStat(
                    amount: summary.totalReceivable,
                    label: 'YOU WILL GET',
                  ),
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: _OverviewStat(
                    amount: summary.totalSale,
                    label: 'SALE',
                  ),
                ),
              ],
            ),
            loading: () => const SizedBox(
              height: 90,
              child: Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
            error: (error, _) => const SizedBox(
              height: 90,
              child: Center(
                child: Text(
                  'Could not load totals.',
                  style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Poppins',
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewStat extends StatelessWidget {
  const _OverviewStat({required this.amount, required this.label});

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

class _QuickActionsCard extends StatelessWidget {
  const _QuickActionsCard({
    required this.onAddSale,
    required this.onDayBook,
    required this.onAllTxnsReport,
  });

  final VoidCallback onAddSale;
  final VoidCallback onDayBook;
  final VoidCallback onAllTxnsReport;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _QuickAction(
            iconAsset: 'assets/icons/icon_add_sale.svg',
            label: 'Add Sale',
            onTap: onAddSale,
          ),
          _QuickAction(
            iconAsset: 'assets/icons/icon_day_book.svg',
            label: 'Day Book',
            onTap: onDayBook,
          ),
          _QuickAction(
            iconAsset: 'assets/icons/icon_all_txns_report.svg',
            label: 'All Txns Report',
            onTap: onAllTxnsReport,
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.iconAsset,
    required this.label,
    required this.onTap,
  });

  final String iconAsset;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary),
              ),
              alignment: Alignment.center,
              child: SvgPicture.asset(iconAsset, width: 24, height: 24),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 12,
                fontFamily: 'Poppins',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
