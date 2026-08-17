import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../domain/razorpay_order_details.dart';

/// Talks to the two payment Edge Functions (`create-razorpay-order`,
/// `verify-razorpay-payment`) — never calls Razorpay's API directly, and
/// never writes `invoices.payment_status` from the client. Both functions
/// re-derive ownership from the caller's own session (the same JWT
/// `functions.invoke` already sends), so this repository doesn't need to
/// pass or check a restaurant/invoice id beyond the order id itself.
class PaymentsRepository {
  PaymentsRepository(this._client);

  final SupabaseClient _client;

  Future<RazorpayOrderDetails> createRazorpayOrder(String orderId) async {
    try {
      final response = await _client.functions.invoke(
        'create-razorpay-order',
        body: {'orderId': orderId},
      );
      if (response.status != 200) {
        throw AppException(_extractError(response.data));
      }
      return RazorpayOrderDetails.fromMap(response.data as Map<String, dynamic>);
    } on AppException {
      rethrow;
    } catch (error) {
      throw mapErrorToAppException(error);
    }
  }

  Future<void> verifyPayment({
    required String orderId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    try {
      final response = await _client.functions.invoke(
        'verify-razorpay-payment',
        body: {
          'orderId': orderId,
          'razorpayOrderId': razorpayOrderId,
          'razorpayPaymentId': razorpayPaymentId,
          'razorpaySignature': razorpaySignature,
        },
      );
      if (response.status != 200) {
        throw AppException(_extractError(response.data));
      }
    } on AppException {
      rethrow;
    } catch (error) {
      throw mapErrorToAppException(error);
    }
  }

  String _extractError(Object? data) {
    if (data is Map && data['error'] is String) return data['error'] as String;
    return 'Payment could not be completed. Please try again.';
  }
}
