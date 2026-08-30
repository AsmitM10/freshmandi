import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/save_pdf.dart';
import '../../../../core/utils/share_image.dart';
import '../../../../shared/widgets/fm_error_banner.dart';
import '../../domain/admin_transaction.dart';
import '../providers/admin_dashboard_providers.dart';
import '../utils/transactions_pdf.dart';

enum _ViewMode { daily, weekly, monthly, custom }

extension on _ViewMode {
  String get label => switch (this) {
    _ViewMode.daily => 'Daily',
    _ViewMode.weekly => 'Weekly',
    _ViewMode.monthly => 'Monthly',
    _ViewMode.custom => 'Custom',
  };
}

/// Every invoiced transaction across a date range, with quick Daily/Weekly/
/// Monthly presets or a manually picked custom range — the admin Home
/// dashboard's "All Txns Report" quick action.
class AllTransactionsScreen extends ConsumerStatefulWidget {
  const AllTransactionsScreen({super.key});

  @override
  ConsumerState<AllTransactionsScreen> createState() =>
      _AllTransactionsScreenState();
}

class _AllTransactionsScreenState extends ConsumerState<AllTransactionsScreen> {
  _ViewMode _viewMode = _ViewMode.monthly;
  late DateTime _from = _presetFrom(_ViewMode.monthly);
  late DateTime _to = _dateOnly(DateTime.now());
  bool _isGeneratingPdf = false;

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static DateTime _presetFrom(_ViewMode mode) {
    final today = _dateOnly(DateTime.now());
    return switch (mode) {
      _ViewMode.daily => today,
      _ViewMode.weekly => today.subtract(const Duration(days: 6)),
      _ViewMode.monthly => DateTime(today.year, today.month, 1),
      _ViewMode.custom => today,
    };
  }

  Future<void> _pickView() async {
    final picked = await showModalBottomSheet<_ViewMode>(
      context: context,
      backgroundColor: AppColors.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final mode in _ViewMode.values)
              ListTile(
                title: Text(mode.label),
                trailing: mode == _viewMode
                    ? const Icon(Icons.check, color: AppColors.secondary)
                    : null,
                onTap: () => Navigator.of(context).pop(mode),
              ),
          ],
        ),
      ),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _viewMode = picked;
      if (picked != _ViewMode.custom) {
        _from = _presetFrom(picked);
        _to = _dateOnly(DateTime.now());
      }
    });
  }

  Future<void> _pickFrom() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _from,
      firstDate: DateTime.now().subtract(const Duration(days: 3650)),
      lastDate: _to,
    );
    if (picked == null) return;
    setState(() {
      _from = _dateOnly(picked);
      _viewMode = _ViewMode.custom;
    });
  }

  Future<void> _pickTo() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _to,
      firstDate: _from,
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) return;
    setState(() {
      _to = _dateOnly(picked);
      _viewMode = _ViewMode.custom;
    });
  }

  Future<void> _showMenu() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.surfaceWhite,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.picture_as_pdf_outlined,
                color: AppColors.secondary,
              ),
              title: const Text('Generate PDF'),
              onTap: () => Navigator.of(context).pop('generate_pdf'),
            ),
          ],
        ),
      ),
    );
    if (action == 'generate_pdf') _generatePdf();
  }

  /// Builds a PDF of the currently loaded transactions list (same range/
  /// view the screen is showing) and shares it — same generate-then-share
  /// flow as [shareAdminReceipt], including the timeout fallback for
  /// `navigator.share()` hanging on desktop web.
  Future<void> _generatePdf() async {
    if (_isGeneratingPdf) return;
    final transactions = ref
        .read(adminTransactionsForRangeProvider((_from, _to)))
        .valueOrNull;
    if (transactions == null) {
      showAppSnackBar(context, 'Still loading — try again in a moment.');
      return;
    }
    if (transactions.isEmpty) {
      showAppSnackBar(context, 'No transactions in this range to export.');
      return;
    }
    setState(() => _isGeneratingPdf = true);
    try {
      final bytes = await buildTransactionsPdf(
        transactions: transactions,
        from: _from,
        to: _to,
        viewLabel: _viewMode.label,
      );
      final fileName =
          'freshmandi_transactions_${DateFormat('yyyyMMdd').format(_from)}_${DateFormat('yyyyMMdd').format(_to)}';
      try {
        await sharePdfBytes(
          bytes,
          fileName,
          text: 'FreshMandi transactions (${_viewMode.label})',
        ).timeout(const Duration(seconds: 6));
        if (mounted) showAppSnackBar(context, 'PDF shared.');
      } on TimeoutException {
        await savePdfBytes(bytes, fileName);
        if (mounted) showAppSnackBar(context, 'PDF downloaded.');
      }
    } catch (error, stack) {
      debugPrint('Transactions PDF generation failed: $error\n$stack');
      if (mounted) {
        showAppSnackBar(context, 'Could not generate the PDF. Try again.');
      }
    } finally {
      if (mounted) setState(() => _isGeneratingPdf = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(
      adminTransactionsForRangeProvider((_from, _to)),
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
          'All Transactions',
          style: TextStyle(
            color: AppColors.primaryText,
            fontSize: 20,
            fontFamily: 'Urbanist',
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          if (_isGeneratingPdf)
            const Padding(
              padding: EdgeInsets.all(16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            )
          else
            IconButton(
              icon: SvgPicture.asset(
                'assets/icons/icon_kebab_menu.svg',
                width: 24,
                height: 24,
              ),
              onPressed: _showMenu,
            ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          children: [
            _InfoBox(
              label: 'VIEW',
              value: _viewMode.label,
              onTap: _pickView,
              trailing: const Icon(
                Icons.keyboard_arrow_down,
                color: AppColors.placeholder,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _InfoBox(
                    label: 'FROM',
                    value: DateFormat('dd/MM/yyyy').format(_from),
                    onTap: _pickFrom,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _InfoBox(
                    label: 'TO',
                    value: DateFormat('dd/MM/yyyy').format(_to),
                    onTap: _pickTo,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            transactionsAsync.when(
              data: (transactions) {
                if (transactions.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Center(
                      child: Text(
                        'No transactions in this range.',
                        style: TextStyle(
                          color: AppColors.placeholder,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ),
                  );
                }
                return _TransactionsListCard(transactions: transactions);
              },
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(
                  child: Text(
                    'Could not load transactions.',
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
    );
  }
}

class _InfoBox extends StatelessWidget {
  const _InfoBox({
    required this.label,
    required this.value,
    required this.onTap,
    this.trailing,
  });

  final String label;
  final String value;
  final VoidCallback onTap;
  final Widget? trailing;

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
        child: Row(
          children: [
            Expanded(
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
            ?trailing,
          ],
        ),
      ),
    );
  }
}

class _TransactionsListCard extends StatelessWidget {
  const _TransactionsListCard({required this.transactions});

  final List<AdminTransaction> transactions;

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
                  'Total',
                  style: TextStyle(color: Colors.white, fontFamily: 'Poppins'),
                ),
              ],
            ),
          ),
          for (var i = 0; i < transactions.length; i++)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                          transactions[i].restaurantName,
                          style: const TextStyle(
                            fontFamily: 'Urbanist',
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          DateFormat(
                            'dd MMM, yyyy',
                          ).format(transactions[i].createdAt),
                          style: const TextStyle(
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
                        '₹${NumberFormat('#,##0').format(transactions[i].invoiceTotal)}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontFamily: 'Urbanist',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Balance : ₹${NumberFormat('#,##0').format(transactions[i].balance)}',
                        style: const TextStyle(
                          color: AppColors.secondaryText,
                          fontSize: 12,
                          fontFamily: 'Poppins',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
