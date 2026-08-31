import 'package:flutter/material.dart';

import '../core/theme/app_colors.dart';
import '../core/theme/app_spacing.dart';

enum StatTone { neutral, ok, warn, crit }

/// A stat tile that always shows WHAT / VALUE / TIME PERIOD — per the
/// approved correction, every period-based stat must state its timeframe
/// explicitly (e.g. "Today", "This Week", "All time") rather than leaving
/// it to be guessed. Pass `period: null` only for a live/current-state
/// count (e.g. "Pending Orders") that isn't a period total.
class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String? period;
  final StatTone tone;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.period,
    this.tone = StatTone.neutral,
  });

  Color get _valueColor {
    switch (tone) {
      case StatTone.ok:
        return AppColors.ok600;
      case StatTone.warn:
        return AppColors.warn600;
      case StatTone.crit:
        return AppColors.crit600;
      case StatTone.neutral:
        return AppColors.textPrimary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label.toUpperCase(),
            style: textTheme.labelSmall?.copyWith(
              color: AppColors.textMuted,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: AppSpacing.s2),
          Text(
            value,
            style: textTheme.headlineSmall?.copyWith(color: _valueColor),
          ),
          if (period != null) ...[
            const SizedBox(height: AppSpacing.s1),
            Text(period!, style: textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}
