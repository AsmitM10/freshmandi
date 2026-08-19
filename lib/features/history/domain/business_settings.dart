/// Mirrors the single admin-seeded row of `public.business_settings` — the
/// wholesaler's own business info shown on the downloadable invoice
/// (name/address/phone/email/UPI id). There is exactly one wholesaler in
/// this app (no multi-vendor concept), so this is always a single row,
/// never per-restaurant data.
class BusinessSettings {
  const BusinessSettings({
    required this.businessName,
    required this.address,
    required this.phoneNumber,
    this.email,
    this.upiId,
  });

  factory BusinessSettings.fromMap(Map<String, dynamic> map) => BusinessSettings(
    businessName: map['business_name'] as String,
    address: map['address'] as String,
    phoneNumber: map['phone_number'] as String,
    email: map['email'] as String?,
    upiId: map['upi_id'] as String?,
  );

  final String businessName;
  final String address;
  final String phoneNumber;
  final String? email;

  /// Null until an admin configures one — the invoice's QR/UPI section is
  /// omitted rather than shown with an invented id when this is null.
  final String? upiId;
}
