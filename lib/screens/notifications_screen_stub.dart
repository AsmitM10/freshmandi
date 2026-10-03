import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';

class NotificationsScreenStub extends StatelessWidget {
  const NotificationsScreenStub({super.key});

  static const _items = [
    _NotificationItem(
      title: 'Payment received',
      subtitle: 'Aman Verma cleared ₹1,520 via UPI for Walk-in sales.',
      time: '2 min ago',
      type: 'success',
      badge: 'Orders',
    ),
    _NotificationItem(
      title: 'Low stock alert',
      subtitle: 'Tomatoes are below the reorder threshold for today’s demand.',
      time: '18 min ago',
      type: 'warn',
      badge: 'Inventory',
    ),
    _NotificationItem(
      title: 'System updates',
      subtitle: 'Backup completed successfully and sync is running normally.',
      time: '1 hour ago',
      type: 'info',
      badge: 'System',
    ),
    _NotificationItem(
      title: 'Return request',
      subtitle: 'A customer asked for a return on order #1042. Review now.',
      time: '3 hours ago',
      type: 'alert',
      badge: 'Support',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.s4),
        children: [
          Row(
            children: const [
              _FilterChip(label: 'All', selected: true),
              _FilterChip(label: 'Orders'),
              _FilterChip(label: 'Inventory'),
              _FilterChip(label: 'System'),
            ],
          ),
          const SizedBox(height: AppSpacing.s4),
          Container(
            padding: const EdgeInsets.all(AppSpacing.s4),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _SummaryTile(label: 'Unread', value: '12', accent: AppColors.brand600),
                ),
                const SizedBox(width: AppSpacing.s3),
                Expanded(
                  child: _SummaryTile(label: 'Today', value: '6', accent: AppColors.ok600),
                ),
                const SizedBox(width: AppSpacing.s3),
                Expanded(
                  child: _SummaryTile(label: 'Action', value: '3', accent: AppColors.warn600),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s4),
          Text(
            'Latest updates',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: AppSpacing.s3),
          Card(
            child: Column(
              children: [
                for (final item in _items)
                  ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.s4, vertical: AppSpacing.s2),
                    leading: CircleAvatar(
                      backgroundColor: _notificationColor(item.type),
                      child: Icon(_notificationIcon(item.type), color: Colors.white, size: 18),
                    ),
                    title: Row(
                      children: [
                        Expanded(
                          child: Text(item.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.brand50,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            item.badge,
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.brand700),
                          ),
                        ),
                      ],
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text('${item.subtitle}\n${item.time}', style: const TextStyle(height: 1.4)),
                    ),
                    isThreeLine: true,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Color _notificationColor(String type) {
    switch (type) {
      case 'success':
        return AppColors.ok600;
      case 'warn':
        return AppColors.warn600;
      case 'alert':
        return AppColors.crit600;
      case 'info':
      default:
        return AppColors.info600;
    }
  }

  IconData _notificationIcon(String type) {
    switch (type) {
      case 'success':
        return Icons.check_circle_rounded;
      case 'warn':
        return Icons.warning_amber_rounded;
      case 'alert':
        return Icons.priority_high_rounded;
      case 'info':
      default:
        return Icons.info_outline_rounded;
    }
  }
}

class _NotificationItem {
  const _NotificationItem({
    required this.title,
    required this.subtitle,
    required this.time,
    required this.type,
    required this.badge,
  });

  final String title;
  final String subtitle;
  final String time;
  final String type;
  final String badge;
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, this.selected = false});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: AppSpacing.s2),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? AppColors.brand100 : AppColors.ink50,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: selected ? AppColors.brand400 : AppColors.border),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: selected ? AppColors.brand700 : AppColors.textSecondary,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({required this.label, required this.value, required this.accent});

  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s3),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: accent,
            ),
          ),
          const SizedBox(height: AppSpacing.s1),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
