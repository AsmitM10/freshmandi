import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../providers/auth_providers.dart';
import '../../../providers/settings_providers.dart';

class SyncAccountSection extends ConsumerWidget {
  const SyncAccountSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sync = ref.watch(syncProvider);
    final email = ref.watch(currentUserEmailProvider) ?? '—';

    final (label, color, bg) = switch (sync.status) {
      SyncStatus.idle => ('Not synced yet', AppColors.textMuted, AppColors.neutral100),
      SyncStatus.syncing => ('Syncing…', AppColors.info600, AppColors.info100),
      SyncStatus.synced => ('Synced', AppColors.ok600, AppColors.ok100),
      SyncStatus.failed => ('Sync failed', AppColors.crit600, AppColors.crit100),
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Business Account — FreshMandi', style: TextStyle(fontWeight: FontWeight.w700)),
                      Text(email, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
                  child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Last synced', style: TextStyle(color: AppColors.textMuted)),
                Text(sync.lastSynced != null ? formatDateTime(sync.lastSynced!) : 'Never'),
              ],
            ),
            const SizedBox(height: AppSpacing.s4),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: sync.status == SyncStatus.syncing ? null : () => ref.read(syncProvider.notifier).sync(),
                icon: sync.status == SyncStatus.syncing
                    ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.sync),
                label: Text(sync.status == SyncStatus.syncing ? 'Syncing…' : 'Sync Data'),
              ),
            ),
            if (sync.status == SyncStatus.failed)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.s2),
                child: Text(
                  'Sync failed: ${sync.errorMessage ?? 'unknown error'}',
                  style: const TextStyle(color: AppColors.crit600, fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
