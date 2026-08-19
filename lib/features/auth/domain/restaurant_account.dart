import 'account_status.dart';

/// Mirrors a row of the `restaurants` table.
class RestaurantAccount {
  const RestaurantAccount({
    required this.id,
    required this.userId,
    required this.restaurantName,
    required this.ownerName,
    required this.phoneNumber,
    required this.accountStatus,
    this.billingAddress,
    this.deliveryAddress,
  });

  factory RestaurantAccount.fromMap(Map<String, dynamic> map) => RestaurantAccount(
    id: map['id'] as String,
    userId: map['user_id'] as String,
    restaurantName: map['restaurant_name'] as String,
    ownerName: map['owner_name'] as String,
    phoneNumber: map['phone_number'] as String,
    accountStatus: (map['account_status'] as String).toAccountStatus(),
    billingAddress: map['billing_address'] as String?,
    deliveryAddress: map['delivery_address'] as String?,
  );

  final String id;
  final String userId;
  final String restaurantName;
  final String ownerName;
  final String phoneNumber;
  final AccountStatus accountStatus;

  /// Null until the restaurant sets one — neither field exists to fill in
  /// automatically, so this is a real "not provided yet" state, not an
  /// empty string standing in for one.
  final String? billingAddress;
  final String? deliveryAddress;
}
