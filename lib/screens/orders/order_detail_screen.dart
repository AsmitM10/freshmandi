import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';
import '../../models/order.dart';
import '../../models/order_item.dart';
import '../../providers/orders_providers.dart';
import '../../providers/repository_providers.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/status_chip.dart';
import 'widgets/order_share_actions.dart';

/// Admin-side lifecycle for a customer-placed order: it arrives here as a
/// [OrderStatus.pending] *request* — the restaurant hasn't been billed
/// yet, so there's nothing meaningful to share — the admin's one job is to
/// accept it. Accepting computes and generates the invoice
/// (OrdersRepository.confirm -> admin_confirm_order), which is what turns
/// on the Share as Image/PDF actions: only a confirmed, invoiced order has
/// a real total worth sending to the customer.
class OrderDetailScreen extends ConsumerWidget {
  final String orderId;
  const OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orderAsync = ref.watch(orderDetailProvider(orderId));

    return Scaffold(
      // The order/invoice number belongs in the body next to the rest of
      // the order's details, not as the raw UUID used to be shown here —
      // this bar is just navigation chrome.
      appBar: AppBar(
        centerTitle: true,
        title: Text('Order details', style: GoogleFonts.urbanist(fontSize: 20, fontWeight: FontWeight.w600)),
      ),
      body: orderAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorStateView(error: e, onRetry: () => ref.invalidate(orderDetailProvider(orderId))),
        data: (order) {
          final isPending = order.status == OrderStatus.pending;
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.s4),
            children: [
              _OrderHeaderCard(order: order),
              const SizedBox(height: AppSpacing.s5),

              Text('Items', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: AppSpacing.s2),
              Card(
                child: Column(
                  children: [
                    for (final item in order.items)
                      ListTile(
                        leading: _OrderItemAvatar(item: item),
                        title: Text(item.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text('${item.qty} ${item.unit} × ${formatInr(item.rate)}'),
                        trailing: Text(formatInr(item.amount), style: const TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.all(AppSpacing.s4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            isPending ? 'Estimated total' : 'Total',
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            // Pending orders price from current catalog
                            // rates (see OrdersRepository.fetchById) — an
                            // estimate, not yet the invoiced amount, which
                            // is only final once accepted.
                            formatInr(isPending ? order.subtotal : order.total),
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: isPending ? AppColors.textMuted : AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.s5),

              if (isPending)
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    // Blue (navy600, the theme's default FilledButton
                    // fill) is this app's only CTA color — green is
                    // reserved for cards/icons.
                    icon: const Icon(Icons.check),
                    label: const Text('Accept order'),
                    onPressed: () async {
                      await ref.read(ordersRepositoryProvider).confirm(order.id);
                      ref.invalidate(orderDetailProvider(orderId));
                      ref.invalidate(ordersListProvider);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Order accepted — invoice generated')),
                        );
                      }
                    },
                  ),
                )
              else ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4, vertical: AppSpacing.s3),
                  decoration: BoxDecoration(color: AppColors.ok100, borderRadius: BorderRadius.circular(12)),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle, size: 18, color: AppColors.ok600),
                      SizedBox(width: AppSpacing.s2),
                      Text('Order accepted — invoice ready to share', style: TextStyle(color: AppColors.ok600, fontWeight: FontWeight.w700, fontSize: 13)),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.s5),
                Text('Share invoice', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: AppSpacing.s3),
                Row(
                  children: [
                    Expanded(
                      child: _ShareTile(
                        icon: Icons.image_outlined,
                        label: 'Share as Image',
                        onTap: () => shareOrderAsImage(context, ref, order),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s3),
                    Expanded(
                      child: _ShareTile(
                        icon: Icons.picture_as_pdf_outlined,
                        label: 'Share as PDF',
                        onTap: () => shareOrderAsPdf(context, ref, order),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

/// Order/invoice number, status, and customer details — the "main
/// details" the raw UUID used to stand in for at the top of the screen.
class _OrderHeaderCard extends StatelessWidget {
  const _OrderHeaderCard({required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final isPending = order.status == OrderStatus.pending;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s4),
      decoration: BoxDecoration(
        color: AppColors.surfaceTint,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isPending ? 'New order request' : 'Order',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 11.5, fontWeight: FontWeight.w700, letterSpacing: 0.3),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      order.orderNumber,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    if (order.invoiceNumber != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Invoice ${order.invoiceNumber}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.s2),
              // Payment status only means anything once the order has been
              // accepted and invoiced — showing it alongside "Pending"
              // order status before that just doubles up on the same word.
              if (isPending)
                StatusChip.orderStatus(order.status)
              else
                StatusChip.paymentStatus(order.paymentStatus),
            ],
          ),
          const SizedBox(height: AppSpacing.s4),
          Container(height: 1, color: AppColors.border),
          const SizedBox(height: AppSpacing.s3),
          _DetailRow(icon: Icons.store_outlined, label: 'Customer', value: order.customerName),
          if (order.customerPhone != null)
            _DetailRow(icon: Icons.call_outlined, label: 'Phone', value: order.customerPhone!),
          _DetailRow(icon: Icons.schedule_outlined, label: 'Placed', value: formatDateTime(order.placed)),
          if (order.slot != null) _DetailRow(icon: Icons.local_shipping_outlined, label: 'Slot', value: order.slot!),
        ],
      ),
    );
  }
}

/// Icon-over-label action tile — each button gets its own full-width half
/// of the row to grow into, so "Share as Image"/"Share as PDF" always sit
/// on one line instead of squeezing into a side-by-side pill button.
class _ShareTile extends StatelessWidget {
  const _ShareTile({required this.icon, required this.label, required this.onTap});

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.s4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.primary.withValues(alpha: 0.28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                foregroundColor: AppColors.primary,
                child: Icon(icon, size: 20),
              ),
              const SizedBox(height: AppSpacing.s2),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.s2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: AppSpacing.s2),
          SizedBox(
            width: 68,
            child: Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 12.5)),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

/// The real catalog photo when the line item has one (`OrderItem.imageUrl`,
/// resolved by OrdersRepository.fetchById from admin_items_console), same
/// fallback behavior as the Items screen's own avatar — falls back to the
/// category emoji when there's no image or it fails to load.
class _OrderItemAvatar extends StatelessWidget {
  const _OrderItemAvatar({required this.item});

  final OrderItem item;

  @override
  Widget build(BuildContext context) {
    final url = item.imageUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: SizedBox(
        width: 40,
        height: 40,
        child: url == null || url.isEmpty
            ? _fallback()
            : CachedNetworkImage(
                imageUrl: url,
                fit: BoxFit.cover,
                placeholder: (context, _) => _fallback(),
                errorWidget: (context, _, _) => _fallback(),
              ),
      ),
    );
  }

  Widget _fallback() => Container(
        color: AppColors.primary.withValues(alpha: 0.1),
        alignment: Alignment.center,
        child: Text(item.emoji, style: const TextStyle(fontSize: 16)),
      );
}
