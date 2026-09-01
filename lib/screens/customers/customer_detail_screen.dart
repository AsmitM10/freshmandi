import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../models/customer.dart';
import '../../providers/customer_orders_provider.dart';
import '../../providers/customers_providers.dart';
import '../../providers/repository_providers.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/stat_card.dart';
import '../../widgets/status_chip.dart';

class CustomerDetailScreen extends ConsumerWidget {
  final String customerId;
  const CustomerDetailScreen({super.key, required this.customerId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customerAsync = ref.watch(customerDetailProvider(customerId));
    final ordersAsync = ref.watch(customerOrdersProvider(customerId));

    return Scaffold(
      appBar: AppBar(
        title: customerAsync.maybeWhen(data: (c) => Text(c.businessName), orElse: () => const Text('Customer')),
      ),
      body: customerAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorStateView(error: e, onRetry: () => ref.invalidate(customerDetailProvider(customerId))),
        data: (customer) {
          final orders = ordersAsync.valueOrNull ?? [];
          final totalSpent = orders.fold<double>(0, (sum, o) => sum + o.total);
          final aov = orders.isEmpty ? 0.0 : totalSpent / orders.length;

          return ListView(
            padding: const EdgeInsets.all(AppSpacing.s4),
            children: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.payments_outlined),
                      label: const Text('Receive Payment'),
                      onPressed: customer.outstandingBalance > 0 ? () => context.go('/admin/transactions') : null,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s3),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: Icon(customer.status == CustomerStatus.blocked ? Icons.lock_open : Icons.block, color: AppColors.crit600),
                      label: Text(customer.status == CustomerStatus.blocked ? 'Unblock' : 'Block', style: const TextStyle(color: AppColors.crit600)),
                      onPressed: () async {
                        await ref.read(customersRepositoryProvider).setBlocked(
                              customer.id,
                              customer.status != CustomerStatus.blocked,
                            );
                        ref.invalidate(customerDetailProvider(customerId));
                        ref.invalidate(allCustomersProvider);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s5),
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: AppSpacing.s3,
                crossAxisSpacing: AppSpacing.s3,
                childAspectRatio: 1.6,
                children: [
                  StatCard(label: 'Total orders', value: '${orders.length}', period: 'All time'),
                  StatCard(label: 'Total spending', value: formatInr(totalSpent), period: 'All time'),
                  StatCard(label: 'Average order value', value: formatInr(aov), period: 'All time'),
                  StatCard(
                    label: 'Outstanding balance',
                    value: formatInr(customer.outstandingBalance),
                    tone: customer.outstandingBalance > 0 ? StatTone.warn : StatTone.ok,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s5),
              Text('Orders', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.s2),
              ordersAsync.when(
                loading: () => const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator())),
                error: (e, _) => ErrorStateView(error: e, onRetry: () => ref.invalidate(customerOrdersProvider(customerId))),
                data: (orders) {
                  if (orders.isEmpty) {
                    return const EmptyStateView(icon: Icons.receipt_long_outlined, title: 'No orders yet', body: 'Orders from this customer will show up here.');
                  }
                  return Card(
                    child: Column(
                      children: [
                        for (final order in orders)
                          ListTile(
                            title: Text(
                              'Order ${order.orderNumber}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                            subtitle: Text(formatDate(order.placed)),
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
                          ),
                      ],
                    ),
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }
}
