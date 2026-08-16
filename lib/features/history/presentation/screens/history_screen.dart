import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../orders/domain/history_tab.dart';
import '../../../orders/domain/order_history_entry.dart';
import '../../../orders/presentation/providers/orders_providers.dart';
import '../widgets/repeat_order_button.dart';

/// History screen: three tabs (All Orders / Transaction / Pending
/// Invoice), each independently paginated (see HistoryController) so
/// switching tabs back and forth is free and scrolling near the bottom
/// loads the next page rather than the whole history at once.
///
/// Never shows a per-item price — only a generated invoice's final total
/// (Transaction tab), and never any amount at all for orders without one
/// yet (Pending Invoice tab), per the explicit business rule.
class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_handleScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_handleScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _handleScroll() {
    if (_scrollController.position.pixels >
        _scrollController.position.maxScrollExtent - 200) {
      final tab = ref.read(selectedHistoryTabProvider);
      ref.read(historyControllerProvider(tab).notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedTab = ref.watch(selectedHistoryTabProvider);
    final state = ref.watch(historyControllerProvider(selectedTab));

    return Scaffold(
      backgroundColor: AppColors.backgroundHome,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _Header(),
            ),
            const SizedBox(height: AppSpacing.lg),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: _TabRow(),
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(child: _HistoryList(tab: selectedTab, state: state)),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'History',
          style: AppTextStyles.headingScreen.copyWith(color: AppColors.secondaryText),
        ),
        Text('Farm freshed and handpicked daily', style: AppTextStyles.caption),
      ],
    );
  }
}

class _TabRow extends ConsumerWidget {
  const _TabRow();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedHistoryTabProvider);
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: HistoryTab.values.map((tab) {
          final isSelected = tab == selected;
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: InkWell(
              borderRadius: BorderRadius.circular(50),
              onTap: () => ref.read(selectedHistoryTabProvider.notifier).state = tab,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.secondary : AppColors.inputBackground,
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text(
                  tab.label,
                  style: AppTextStyles.caption.copyWith(
                    fontSize: 14,
                    color: isSelected ? AppColors.background : AppColors.secondaryText,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _HistoryList extends ConsumerWidget {
  const _HistoryList({required this.tab, required this.state});

  final HistoryTab tab;
  final HistoryState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.isLoading) return const LoadingState();

    if (state.error != null && state.entries.isEmpty) {
      return EmptyState(
        icon: Icons.wifi_off_outlined,
        message: "Couldn't load history. Check your connection and try again.",
        action: TextButton(
          onPressed: () => ref.read(historyControllerProvider(tab).notifier).retry(),
          child: const Text('Retry'),
        ),
      );
    }

    if (state.entries.isEmpty) {
      return EmptyState(icon: Icons.receipt_long_outlined, message: tab.emptyMessage);
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(
        16,
        0,
        16,
        AppSpacing.bottomNavHeight + AppSpacing.base,
      ),
      itemCount: state.entries.length + (state.isLoadingMore ? 1 : 0),
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.base),
      itemBuilder: (context, index) {
        if (index >= state.entries.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
          );
        }
        return _OrderCard(entry: state.entries[index]);
      },
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.entry});

  final OrderHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        DateFormat('dd/MM/yyyy').format(entry.createdAt),
                        style: const TextStyle(
                          color: AppColors.ctaText,
                          fontSize: 16,
                          fontFamily: AppTextStyles.fontFamily,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        DateFormat('hh:mm a').format(entry.createdAt),
                        style: const TextStyle(
                          color: AppColors.ctaText,
                          fontSize: 14,
                          fontFamily: AppTextStyles.fontFamily,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusBadge(entry: entry),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.background,
              border: Border.all(color: Colors.black.withValues(alpha: 0.20)),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const _Field(label: 'ORDER NO.'),
                              Text(entry.orderNumber, style: _valueStyle),
                              const SizedBox(height: 16),
                              const _Field(label: 'ITEMS'),
                              Text('${entry.itemCount}', style: _valueStyle),
                            ],
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: VerticalDivider(color: AppColors.cardBorder, width: 1),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const _Field(label: 'DELIVERY ON', alignEnd: true),
                              Text(
                                entry.deliveryDate != null
                                    ? DateFormat('dd MMMM yyyy')
                                          .format(entry.deliveryDate!)
                                          .toUpperCase()
                                    : '—',
                                textAlign: TextAlign.right,
                                style: _valueStyle,
                              ),
                              const SizedBox(height: 16),
                              _Field(
                                label: entry.hasInvoice ? 'TOTAL AMT.' : 'INVOICE',
                                alignEnd: true,
                              ),
                              Text(
                                entry.hasInvoice
                                    ? '₹${NumberFormat('#,##0').format(entry.invoiceTotal)}'
                                    : 'Awaiting invoice',
                                textAlign: TextAlign.right,
                                style: entry.hasInvoice
                                    ? _valueStyle.copyWith(color: AppColors.invoiceGreen)
                                    : _valueStyle.copyWith(
                                        fontSize: 14,
                                        color: AppColors.placeholder,
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _ActionButton(
                          label: 'View Details',
                          filled: false,
                          onPressed: () => context.push('/history/order/${entry.orderId}'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: RepeatOrderButton(orderId: entry.orderId, filled: true),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

const _valueStyle = TextStyle(
  color: Colors.black,
  fontSize: 16,
  fontFamily: AppTextStyles.urbanistFontFamily,
  fontWeight: FontWeight.w600,
);

class _Field extends StatelessWidget {
  const _Field({required this.label, this.alignEnd = false});

  final String label;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      textAlign: alignEnd ? TextAlign.right : TextAlign.left,
      style: const TextStyle(
        color: AppColors.labelGray,
        fontSize: 12,
        fontFamily: AppTextStyles.fontFamily,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.48,
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.entry});

  final OrderHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final String text;
    final Color color;
    if (!entry.hasInvoice) {
      text = 'Pending';
      color = AppColors.accentYellow;
    } else if (entry.isPaid) {
      text = 'Paid';
      color = AppColors.accentGreen;
    } else {
      text = 'Unpaid';
      color = AppColors.accentYellow;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(50)),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.primaryText,
          fontSize: 13,
          fontFamily: AppTextStyles.fontFamily,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({required this.label, required this.filled, this.onPressed});

  final String label;
  final bool filled;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: filled ? AppColors.secondary : AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.secondary),
        boxShadow: const [
          BoxShadow(color: Color(0x3F000000), blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onPressed,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: filled ? AppColors.ctaText : AppColors.secondary,
                fontSize: 14,
                fontFamily: AppTextStyles.fontFamily,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
