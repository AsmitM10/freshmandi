import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';

class EmptyStateView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final String? actionLabel;
  final VoidCallback? onAction;

  const EmptyStateView({
    super.key,
    required this.icon,
    required this.title,
    required this.body,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.s7),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(color: AppColors.brand50, shape: BoxShape.circle),
            child: Icon(icon, color: AppColors.brand600, size: 26),
          ),
          const SizedBox(height: AppSpacing.s4),
          Text(title, style: Theme.of(context).textTheme.titleMedium, textAlign: TextAlign.center),
          const SizedBox(height: AppSpacing.s2),
          Text(body, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.center),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: AppSpacing.s4),
            ElevatedButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

class ErrorStateView extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const ErrorStateView({super.key, required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return EmptyStateView(
      icon: Icons.error_outline,
      title: 'Something went wrong',
      body: '$error',
      actionLabel: 'Retry',
      onAction: onRetry,
    );
  }
}
