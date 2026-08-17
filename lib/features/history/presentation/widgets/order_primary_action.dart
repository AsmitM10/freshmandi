import 'package:flutter/widgets.dart';

import '../../../orders/domain/order_history_entry.dart';
import 'pay_now_button.dart';
import 'repeat_order_button.dart';

/// The primary (filled) action on an order card: "Pay Now" for any order
/// that isn't marked paid yet — including the Pending Invoice tab's cards,
/// which don't have an invoice generated yet. Only once an order is Paid
/// does the button switch to "Repeat Order". Shared by the History list,
/// the Invoice detail screen, and the post-Place-Order success screen so
/// the three can't drift on this rule.
///
/// Tapping Pay Now before a wholesaler has generated the invoice will
/// surface a clear "Invoice not found" message rather than charging
/// nothing — there's no amount to charge yet in that state, and inventing
/// one isn't something this button can safely do.
class OrderPrimaryAction extends StatelessWidget {
  const OrderPrimaryAction({super.key, required this.entry});

  final OrderHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    return entry.isPaid
        ? RepeatOrderButton(orderId: entry.orderId, filled: true)
        : PayNowButton(orderId: entry.orderId);
  }
}
