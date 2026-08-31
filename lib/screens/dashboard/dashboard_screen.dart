import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
    final greeting = hour < 12 ? 'Good morning' : (hour < 17 ? 'Good afternoon' : 'Good evening');

    return Scaffold(
      appBar: AppBar(
        title: Text(greeting),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sign out',
            onPressed: () => ref.read(authRepositoryProvider).signOut(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(dashboardSnapshotProvider),
        child: snapshotAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => ListView(
            children: [ErrorStateView(error: e, onRetry: () => ref.invalidate(dashboardSnapshotProvider))],
          ),
          data: (snapshot) => ListView(
            padding: const EdgeInsets.all(AppSpacing.s4),
            children: [
              if (email != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.s4),
                  child: Text("Here's how FreshMandi is performing today.",
                      style: Theme.of(context).textTheme.bodyMedium),
                ),
              // ---- Business hero -------------------------------------------------
              Container(
                padding: const EdgeInsets.all(AppSpacing.s5),
                decoration: BoxDecoration(color: AppColors.brand800, borderRadius: BorderRadius.circular(16)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('TOTAL SALES TODAY', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text(formatInr(snapshot.salesToday),
                        style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w800)),
                    const SizedBox(height: AppSpacing.s4),
                    Row(
                      children: [
                        Expanded(
                          child: _HeroTile(
                            icon: Icons.check_circle_outline,
                            label: 'Money in today',
                            value: formatInr(snapshot.moneyInToday),
                            onTap: () => context.go('/admin/transactions'),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.s3),
                        Expanded(
                          child: _HeroTile(
                            icon: Icons.schedule,
                            label: 'Pending orders',
                            value: '${snapshot.pendingOrders}',
                            onTap: () => context.go('/admin/orders'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.s5),

              // ---- Stat grid -------------------------------------------------------
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: AppSpacing.s3,
                crossAxisSpacing: AppSpacing.s3,
                childAspectRatio: 1.5,
                children: [
                  StatCard(label: "Today's Revenue", value: formatInr(snapshot.salesToday), period: 'Today'),
                  StatCard(
                    label: "Today's Orders",
                    value: '${snapshot.pendingOrders + snapshot.confirmedOrders}',
                    period: 'Today',
                  ),
                  StatCard(label: 'Pending Orders', value: '${snapshot.pendingOrders}', tone: StatTone.warn),
                  StatCard(
                    label: 'Receivable',
                    value: formatInr(snapshot.totalReceivable),
                    tone: snapshot.totalReceivable > 0 ? StatTone.warn : StatTone.ok,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s5),

              // ---- Recent orders ----------------------------------------------------
              Text('Recent orders', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.s3),
              const _RecentOrders(),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  const _HeroTile({required this.icon, required this.label, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.s3),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(12)),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: AppSpacing.s2),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
                  Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ],
        ),
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
                  title: Text(order.id, style: const TextStyle(fontWeight: FontWeight.w700)),
                  subtitle: Text('${order.customerName} · ${order.items.length} items'),
                  trailing: Text(formatInr(order.total), style: const TextStyle(fontWeight: FontWeight.w700)),
                  onTap: () => context.push('/admin/orders/${order.id}'),
                ),
            ],
          ),
        );
      },
    );
  }
}
