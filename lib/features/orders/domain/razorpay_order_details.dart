/// What the `create-razorpay-order` Edge Function returns — everything
/// Razorpay Checkout needs to open, issued server-side so the amount can
/// never be tampered with client-side.
class RazorpayOrderDetails {
  const RazorpayOrderDetails({
    required this.razorpayOrderId,
    required this.amountPaise,
    required this.currency,
    required this.keyId,
  });

  factory RazorpayOrderDetails.fromMap(Map<String, dynamic> map) => RazorpayOrderDetails(
    razorpayOrderId: map['razorpayOrderId'] as String,
    amountPaise: map['amount'] as int,
    currency: map['currency'] as String,
    keyId: map['keyId'] as String,
  );

  final String razorpayOrderId;
  final int amountPaise;
  final String currency;
  final String keyId;
}
