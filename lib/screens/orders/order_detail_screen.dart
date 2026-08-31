import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../models/order.dart';
import '../../providers/orders_providers.dart';
import '../../providers/repository_providers.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/status_chip.dart';
import 'widgets/order_share_actions.dart';

class OrderDetailScreen extends ConsumerWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderDetailProvider(orderId));

    return Scaffold(
      appBar: AppBar(title: Text(orderId)),
      body: orderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorStateView(error: e, onRetry: () => ref.invalidate(orderDetailProvider(orderId))),
        data: (order) => ListView(
          padding: const EdgeInsets.all(AppSpacing.s4),
          children: [
            Row(
              children: [
                StatusChip.orderStatus(order.status),
                const SizedBox(width: AppSpacing.s2),
                StatusChip.paymentStatus(order.paymentStatus),
              ],
            ),
            const SizedBox(height: AppSpacing.s4),

            // ---- Share actions — clearly visible, one tap each, no menu. ----
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => shareOrderAsImage(context, order),
                    icon: const Icon(Icons.image_outlined),
                    label: const Text('Share as Image'),
                  ),
                ),
                const SizedBox(width: AppSpacing.s3),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => shareOrderAsPdf(context, order),
                    icon: const Icon(Icons.picture_as_pdf_outlined),
                    label: const Text('Share as PDF'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s5),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.s4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Customer', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: AppSpacing.s2),
                    Text(order.customerName),
                    const SizedBox(height: AppSpacing.s3),
                    Text('Placed', style: Theme.of(context).textTheme.titleSmall),
                    const SizedBox(height: AppSpacing.s2),
                    Text(formatDateTime(order.placed)),
                    if (order.slot != null) ...[
                      const SizedBox(height: AppSpacing.s3),
                      Text('Slot', style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: AppSpacing.s2),
                      Text(order.slot!),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s4),

            Text('Items', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.s2),
            Card(
              child: Column(
                children: [
                  for (final item in order.items)
                    ListTile(
                      leading: Text(item.emoji, style: const TextStyle(fontSize: 20)),
                      title: Text(item.name),
                      subtitle: Text('${item.qty} ${item.unit} × ${formatInr(item.rate)}'),
                      trailing: Text(formatInr(item.amount), style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  const Divider(height: 1),
                  Padding(
                    padding: const EdgeInsets.all(AppSpacing.s4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total', style: TextStyle(fontWeight: FontWeight.w800)),
                        Text(formatInr(order.total), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.s5),

            if (order.status == OrderStatus.pending)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: AppColors.brand600),
                  icon: const Icon(Icons.check),
                  label: const Text('Confirm order'),
                  onPressed: () async {
                    await ref.read(ordersRepositoryProvider).confirm(order.id);
                    ref.invalidate(orderDetailProvider(orderId));
                    ref.invalidate(ordersListProvider);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Order confirmed')));
                    }
                  },
                ),
              )
            else
              const Text('No further action needed on this order.', style: TextStyle(color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}
