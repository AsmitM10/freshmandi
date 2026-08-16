import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/fm_primary_button.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

/// TEMPORARY placeholder — the full Settings screen (profile, FSSAI
/// details, account, T&C link) is Phase 7 scope. Logout is wired now
/// rather than deferred, since testers need a way to sign out of the
/// Home/Shop flow to test with a different account.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.settings_outlined, size: 48, color: AppColors.placeholder),
                const SizedBox(height: 12),
                Text(
                  'Full settings are coming soon.',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.placeholder),
                ),
                const SizedBox(height: 32),
                FMPrimaryButton(
                  label: 'Log out',
                  onPressed: () async {
                    await ref.read(authRepositoryProvider).signOut();
                    if (context.mounted) context.go(AppRoutes.welcome);
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
