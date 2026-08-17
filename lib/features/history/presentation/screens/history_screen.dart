import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../orders/domain/history_tab.dart';
import '../../../orders/domain/order_history_entry.dart';
import '../../../orders/presentation/providers/orders_providers.dart';
import '../widgets/order_primary_action.dart';
import '../widgets/order_summary_card.dart';

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
          crossAxisAlignment: CrossAxisAlignment.stretch,
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
    return OrderSummaryCard(
      entry: entry,
      actions: Row(
        children: [
          Expanded(
            child: OrderActionButton(
              label: 'View Details',
              filled: false,
              onPressed: () => context.push('/history/order/${entry.orderId}'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(child: OrderPrimaryAction(entry: entry)),
        ],
      ),
    );
  }
}
