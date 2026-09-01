/// A restaurant result in the Add Sale customer picker — deliberately not
/// the full `Customer` model, which carries fields (balance, status) that
/// don't apply to a lightweight search result.
class AdminCustomerOption {
  const AdminCustomerOption({required this.id, required this.name, required this.phone});

  final String id;
  final String name;
  final String phone;

  factory AdminCustomerOption.fromJson(Map<String, dynamic> json) => AdminCustomerOption(
        id: json['id'] as String,
        name: json['restaurant_name'] as String,
        phone: json['phone_number'] as String,
      );
}
