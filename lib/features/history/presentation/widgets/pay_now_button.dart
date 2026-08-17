import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../orders/presentation/providers/orders_providers.dart';

/// Opens Razorpay Checkout for an order's unpaid invoice. The amount comes
/// only from the server (`create-razorpay-order`, which reads the real
/// `invoices.total_amount` — never something this widget could construct
/// or tamper with), and a successful Checkout result is itself just a
/// claim until `verify-razorpay-payment` recomputes Razorpay's signature
/// server-side and marks the invoice paid; this widget never marks
/// anything paid on its own.
class PayNowButton extends ConsumerStatefulWidget {
  const PayNowButton({super.key, required this.orderId});

  final String orderId;

  @override
  ConsumerState<PayNowButton> createState() => _PayNowButtonState();
}

class _PayNowButtonState extends ConsumerState<PayNowButton> {
  late final Razorpay _razorpay;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _razorpay = Razorpay()
      ..on(Razorpay.EVENT_PAYMENT_SUCCESS, _handlePaymentSuccess)
      ..on(Razorpay.EVENT_PAYMENT_ERROR, _handlePaymentError)
      ..on(Razorpay.EVENT_EXTERNAL_WALLET, _handleExternalWallet);
  }

  @override
  void dispose() {
    _razorpay.clear();
    super.dispose();
  }

  Future<void> _handleTap() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      final details = await ref.read(paymentsRepositoryProvider).createRazorpayOrder(widget.orderId);
      _razorpay.open({
        'key': details.keyId,
        'order_id': details.razorpayOrderId,
        'amount': details.amountPaise,
        'currency': details.currency,
        'name': 'FreshMandi',
        'description': 'Order payment',
      });
    } catch (error) {
      if (mounted) {
        _showMessage(mapErrorToAppException(error).message);
        setState(() => _isProcessing = false);
      }
    }
  }

  Future<void> _handlePaymentSuccess(PaymentSuccessResponse response) async {
    try {
      await ref
          .read(paymentsRepositoryProvider)
          .verifyPayment(
            orderId: widget.orderId,
            razorpayOrderId: response.orderId!,
            razorpayPaymentId: response.paymentId!,
            razorpaySignature: response.signature!,
          );
      ref.invalidate(orderSummaryProvider(widget.orderId));
      ref.invalidate(historyControllerProvider);
      if (mounted) _showMessage('Payment successful!');
    } catch (error) {
      if (mounted) {
        _showMessage(
          "Payment went through, but couldn't be confirmed: ${mapErrorToAppException(error).message}",
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  void _handlePaymentError(PaymentFailureResponse response) {
    if (!mounted) return;
    _showMessage(response.message?.isNotEmpty == true ? response.message! : 'Payment failed.');
    setState(() => _isProcessing = false);
  }

  void _handleExternalWallet(ExternalWalletResponse response) {
    if (!mounted) return;
    setState(() => _isProcessing = false);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: _handleTap,
          child: Center(
            child: _isProcessing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.ctaText),
                  )
                : Text(
                    'Pay Now',
                    style: TextStyle(
                      color: AppColors.ctaText,
                      fontSize: 14,
                      fontFamily: AppTextStyles.urbanistFontFamily,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
