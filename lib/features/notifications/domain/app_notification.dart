/// A row from the `notifications` table (see
/// 20260901000002_notifications.sql) — written by the admin app right
/// after accepting an order, read here on the restaurant side.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.isRead,
    required this.createdAt,
    this.orderId,
    this.imageUrl,
  });

  final String id;
  final String type;
  final String title;
  final String message;
  final bool isRead;
  final DateTime createdAt;
  final String? orderId;

  /// Already resolved to a displayable URL by the repository — see
  /// NotificationsRepository._resolveImageUrl.
  final String? imageUrl;

  factory AppNotification.fromMap(Map<String, dynamic> map, {String? Function(String? path)? resolveImageUrl}) {
    final rawImageUrl = map['image_url'] as String?;
    return AppNotification(
      id: map['id'] as String,
      type: map['type'] as String,
      title: map['title'] as String,
      message: map['message'] as String,
      isRead: map['is_read'] as bool,
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
      orderId: map['order_id'] as String?,
      imageUrl: resolveImageUrl != null ? resolveImageUrl(rawImageUrl) : rawImageUrl,
    );
  }
}
