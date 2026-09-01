import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_routes.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../models/order.dart';
import '../../providers/orders_providers.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/filter_pill.dart';
import '../../widgets/status_chip.dart';

class OrdersListScreen extends ConsumerWidget {
  const OrdersListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(ordersListProvider);
    final statusFilter = ref.watch(ordersStatusFilterProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Orders')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await context.push(AppRoutes.adminAddSale);
          ref.invalidate(ordersListProvider);
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Sale'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.s4, AppSpacing.s3, AppSpacing.s4, AppSpacing.s2),
            child: Column(
              children: [
                TextField(
                  decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Search order ID or customer…'),
                  onChanged: (v) => ref.read(ordersSearchProvider.notifier).state = v,
                ),
                const SizedBox(height: AppSpacing.s3),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: AppSpacing.s2,
                    runSpacing: AppSpacing.s2,
                    children: [
                      FilterPill(
                        label: 'All',
                        selected: statusFilter == null,
                        onSelected: () => ref.read(ordersStatusFilterProvider.notifier).state = null,
                      ),
                      FilterPill(
                        label: 'Pending',
                        selected: statusFilter == OrderStatus.pending,
                        onSelected: () => ref.read(ordersStatusFilterProvider.notifier).state = OrderStatus.pending,
                      ),
                      FilterPill(
                        label: 'Confirmed',
                        selected: statusFilter == OrderStatus.confirmed,
                        onSelected: () => ref.read(ordersStatusFilterProvider.notifier).state = OrderStatus.confirmed,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ordersAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => ErrorStateView(error: e, onRetry: () => ref.invalidate(ordersListProvider)),
              data: (orders) {
                if (orders.isEmpty) {
                  return const EmptyStateView(icon: Icons.receipt_long_outlined, title: 'No orders found', body: 'Try a different search or filter.');
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    ref.invalidate(ordersListProvider);
                    await ref.read(ordersListProvider.future);
                  },
                  child: ListView.separated(
                    itemCount: orders.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final order = orders[index];
                      return ListTile(
                        title: Text(
                          'Order ${order.orderNumber}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text('${order.customerName} · ${order.displayItemCount} items · ${timeAgo(order.placed)}'),
                        trailing: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(formatInr(order.total), style: const TextStyle(fontWeight: FontWeight.w700)),
                            const SizedBox(height: 4),
                            StatusChip.orderStatus(order.status),
                          ],
                        ),
                        onTap: () => context.push('/admin/orders/${order.id}'),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
