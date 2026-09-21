import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/empty_state.dart' show EmptyState;
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../history/presentation/widgets/order_summary_card.dart'
    show OrderActionButton;
import '../../domain/app_notification.dart';
import '../providers/notifications_providers.dart';

/// Reached by tapping the bell icon on Home. Shows every notification
/// this restaurant has received. Opening this screen marks everything as
/// read (rather than requiring each card to be tapped individually), so
/// the bell's unread badge always clears back to its default state as
/// soon as the user has seen the list.
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(_markAllRead);
  }

  Future<void> _markAllRead() async {
    final restaurant = await ref.read(currentRestaurantProvider.future);
    if (restaurant == null) return;
    await ref
        .read(notificationsRepositoryProvider)
        .markAllAsRead(restaurant.id);
    if (mounted) ref.invalidate(notificationsProvider);
  }

  @override
  Widget build(BuildContext context) {
    final notificationsAsync = ref.watch(notificationsProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundHome,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _Header(onBack: () => context.pop()),
            Expanded(
              child: notificationsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) =>
                    Center(child: Text('Could not load notifications: $e')),
                data: (notifications) {
                  if (notifications.isEmpty) {
                    return const EmptyState(
                      icon: Icons.notifications_none,
                      message:
                          "No notifications yet.\nYou'll see updates about your orders here.",
                    );
                  }
                  return RefreshIndicator(
                    onRefresh: () async =>
                        ref.invalidate(notificationsProvider),
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(
                        16,
                        AppSpacing.base,
                        16,
                        AppSpacing.bottomNavHeight + AppSpacing.base,
                      ),
                      itemCount: notifications.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, index) =>
                          _NotificationCard(notification: notifications[index]),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationCard extends ConsumerWidget {
  const _NotificationCard({required this.notification});

  final AppNotification notification;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Material(
      color: AppColors.surfaceWhite,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: notification.isRead
            ? null
            : () => ref
                  .read(notificationsRepositoryProvider)
                  .markAsRead(notification.id)
                  .then((_) => ref.invalidate(notificationsProvider)),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: -10,
                    top: 6,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: notification.isRead
                            ? Colors.transparent
                            : AppColors.secondary,
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              notification.type == 'order_accepted'
                                  ? 'Order Accepted'
                                  : notification.title,
                              style: TextStyle(
                                fontFamily: AppTextStyles.urbanistFontFamily,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primaryText,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            DateFormat(
                              'd MMM, h:mm a',
                            ).format(notification.createdAt),
                            style: AppTextStyles.caption.copyWith(fontSize: 11),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.message,
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.placeholder,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              if (notification.imageUrl != null) ...[
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: CachedNetworkImage(
                    imageUrl: notification.imageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (context, _) => const SizedBox(
                      height: 120,
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                    errorWidget: (context, _, _) => const SizedBox.shrink(),
                  ),
                ),
              ],
              if (notification.type == 'order_accepted' &&
                  notification.orderId != null) ...[
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OrderActionButton(
                    label: 'View Invoice',
                    filled: false,
                    onPressed: () => context.push(
                      '${AppRoutes.invoiceView}/${notification.orderId}',
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: onBack,
                child: const Center(
                  child: Icon(
                    Icons.arrow_back_ios_new,
                    color: AppColors.primaryText,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Notifications',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTextStyles.urbanistFontFamily,
                fontSize: 18,
                fontWeight: FontWeight.w400,
                color: AppColors.primaryText,
              ),
            ),
          ),
          const SizedBox(width: 32),
        ],
      ),
    );
  }
}
