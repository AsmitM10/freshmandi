import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../providers/auth_providers.dart';
import '../../providers/dashboard_providers.dart';
import '../../providers/orders_providers.dart';
import '../../providers/repository_providers.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/stat_card.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final snapshotAsync = ref.watch(dashboardSnapshotProvider);
    final email = ref.watch(currentUserEmailProvider);
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good Morning' : (hour < 17 ? 'Good Afternoon' : 'Good Evening');

    return Scaffold(
      // No AppBar — a plain Material AppBar (even with a transparent/cream
      // background) still draws its own elevation/shadow chrome around
      // itself, which read as an unwanted boxed border once it no longer
      // stood out as a distinct white bar. The greeting lives directly in
      // the body instead, matching the restaurant app's own Home Page
      // hierarchy: a large title with the action icon beside it, a muted
      // subtitle underneath, nothing boxed around either.
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.s4, AppSpacing.s4, AppSpacing.s4, AppSpacing.s2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        greeting,
                        style: GoogleFonts.urbanist(fontSize: 20, fontWeight: FontWeight.w500, color: AppColors.textPrimary),
                      ),
                      IconButton(
                        icon: const Icon(Icons.logout),
                        tooltip: 'Sign out',
                        onPressed: () => ref.read(authRepositoryProvider).signOut(),
                      ),
                    ],
                  ),
                  if (email != null)
                    Text("Here's how FreshMandi is performing today.", style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => ref.invalidate(dashboardSnapshotProvider),
                child: snapshotAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => ListView(
                    children: [ErrorStateView(error: e, onRetry: () => ref.invalidate(dashboardSnapshotProvider))],
                  ),
                  data: (snapshot) => ListView(
                    padding: const EdgeInsets.fromLTRB(AppSpacing.s4, AppSpacing.s2, AppSpacing.s4, AppSpacing.s4),
                    children: [
                      // ---- Overview: what's owed vs. lifetime sales -----------------
                      _OverviewCard(
                        youWillGet: snapshot.totalReceivable,
                        sale: snapshot.totalSale,
                      ),
                      const SizedBox(height: AppSpacing.s5),

                      // ---- Stat grid --------------------------------------------------
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: AppSpacing.s3,
                        crossAxisSpacing: AppSpacing.s3,
                        childAspectRatio: 1.5,
                        children: [
                          StatCard(
                            label: "Today's Orders",
                            value: '${snapshot.pendingOrders + snapshot.confirmedOrders}',
                            period: 'Today',
                          ),
                          StatCard(label: 'Pending Orders', value: '${snapshot.pendingOrders}', tone: StatTone.warn),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.s5),

                      // ---- Recent orders ------------------------------------------------
                      Text(
                        'Recent Orders',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 20, fontWeight: FontWeight.w400),
                      ),
                      const SizedBox(height: AppSpacing.s3),
                      const _RecentOrders(),
                    ],
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

/// "You will get" (unpaid invoices, i.e. what's still owed) vs. "Paid
/// this month" (money_transactions actually received since the 1st) —
/// two different numbers that are easy to conflate otherwise.
class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.youWillGet, required this.sale});

  final double youWillGet;
  final double sale;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: ShapeDecoration(
        color: AppColors.primary,
        shape: RoundedRectangleBorder(
          side: const BorderSide(width: 1, color: AppColors.cardBorder),
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Overview',
            style: GoogleFonts.urbanist(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(child: _OverviewStat(label: 'You will get', value: formatInr(youWillGet))),
              const SizedBox(width: 12),
              Expanded(child: _OverviewStat(label: 'Sale', value: formatInr(sale))),
            ],
          ),
        ],
      ),
    );
  }
}

class _OverviewStat extends StatelessWidget {
  const _OverviewStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
      clipBehavior: Clip.antiAlias,
      padding: const EdgeInsets.fromLTRB(12, 18, 12, 12),
      decoration: ShapeDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.urbanist(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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

class _RecentOrders extends ConsumerWidget {
  const _RecentOrders();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(ordersListProvider);
    return ordersAsync.when(
      loading: () => const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
      error: (e, _) => ErrorStateView(error: e, onRetry: () => ref.invalidate(ordersListProvider)),
      data: (orders) {
        final recent = orders.take(8).toList();
        if (recent.isEmpty) {
          return const EmptyStateView(icon: Icons.receipt_long_outlined, title: 'No orders yet', body: 'Orders will show up here once placed.');
        }
        return Card(
          child: Column(
            children: [
              for (final order in recent)
                ListTile(
                  // A ListTile's built-in title/subtitle slots are only a
                  // couple px apart with no way to widen that gap, so the
                  // order number and hotel name read as cramped — building
                  // both into `title` as a Column instead, with an explicit
                  // gap between them, keeps the rest of ListTile's layout
                  // (trailing amount, tap target, dividers) unchanged.
                  title: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Order ${order.orderNumber}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.urbanist(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      // Explicit muted style — this line no longer sits in
                      // ListTile's own `subtitle` slot (which applies that
                      // styling for free), so without this it would
                      // inherit the bolder `title` slot's text style.
                      Text(
                        '${order.customerName} · ${order.displayItemCount} items',
                        style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.normal),
                      ),
                    ],
                  ),
                  trailing: Text(formatInr(order.total), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                  onTap: () => context.push('/admin/orders/${order.id}'),
                ),
            ],
          ),
        );
      },
    );
  }
}
