enum CustomerStatus { active, blocked }

class Customer {
  final String id;
  final String businessName;
  final String contactName;
  final String phone;
  final String? businessType;
  final DateTime joined;
  final CustomerStatus status;
  final double outstandingBalance;

  const Customer({
    required this.id,
    required this.businessName,
    required this.contactName,
    required this.phone,
    this.businessType,
    required this.joined,
    this.status = CustomerStatus.active,
    this.outstandingBalance = 0,
  });

  factory Customer.fromJson(Map<String, dynamic> json) => Customer(
        id: json['id'] as String,
        businessName: json['business_name'] as String,
        contactName: (json['contact_name'] as String?) ?? '',
        phone: (json['phone'] as String?) ?? '',
        businessType: json['business_type'] as String?,
        joined: DateTime.parse(json['created_at'] as String),
        status: (json['status'] as String? ?? 'active') == 'blocked'
            ? CustomerStatus.blocked
            : CustomerStatus.active,
        outstandingBalance: (json['outstanding_balance'] as num?)?.toDouble() ?? 0,
      );
}
