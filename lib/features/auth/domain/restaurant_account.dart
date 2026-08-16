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
  });

  factory RestaurantAccount.fromMap(Map<String, dynamic> map) => RestaurantAccount(
    id: map['id'] as String,
    userId: map['user_id'] as String,
    restaurantName: map['restaurant_name'] as String,
    ownerName: map['owner_name'] as String,
    phoneNumber: map['phone_number'] as String,
    accountStatus: (map['account_status'] as String).toAccountStatus(),
  );

  final String id;
  final String userId;
  final String restaurantName;
  final String ownerName;
  final String phoneNumber;
  final AccountStatus accountStatus;
}
