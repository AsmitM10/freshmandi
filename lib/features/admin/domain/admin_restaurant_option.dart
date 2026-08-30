/// A restaurant as shown in the admin's customer picker — just enough to
/// display and to attach a sale to (`restaurants.id`), not the full
/// RestaurantAccount used on the restaurant's own side.
class AdminRestaurantOption {
  const AdminRestaurantOption({
    required this.id,
    required this.restaurantName,
    required this.phoneNumber,
  });

  final String id;
  final String restaurantName;
  final String phoneNumber;

  factory AdminRestaurantOption.fromJson(Map<String, dynamic> json) {
    return AdminRestaurantOption(
      id: json['id'] as String,
      restaurantName: json['restaurant_name'] as String,
      phoneNumber: json['phone_number'] as String,
    );
  }
}
