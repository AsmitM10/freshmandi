import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/fm_primary_button.dart';
import '../providers/auth_providers.dart';

/// None of these four screens are defined by Figma (out of Phase 1 UI
/// scope) — they exist only so the post-login branches (approved / pending
/// / rejected / suspended) are reachable and testable end-to-end. Minimal,
/// on-token styling, explicitly marked TEMPORARY. Replace in a later phase
/// with the real restaurant home screen and real status screens.
class _StatusScaffold extends ConsumerWidget {
  const _StatusScaffold({
    required this.title,
    required this.message,
    required this.icon,
  });

  final String title;
  final String message;
  final IconData icon;

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
                Icon(icon, size: 56, color: AppColors.primary),
                const SizedBox(height: 16),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.heading,
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall,
                ),
                const SizedBox(height: 4),
                const Text(
                  '(TEMPORARY screen — Phase 1 placeholder)',
                  style: TextStyle(
                    fontFamily: AppTextStyles.fontFamily,
                    fontSize: 11,
                    color: AppColors.placeholder,
                  ),
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

class PendingApprovalScreen extends StatelessWidget {
  const PendingApprovalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _StatusScaffold(
      title: 'Application Under Review',
      message:
          'Your restaurant registration is pending admin approval. '
          "We'll notify you once it's reviewed.",
      icon: Icons.hourglass_top_rounded,
    );
  }
}

class AccountRejectedScreen extends StatelessWidget {
  const AccountRejectedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _StatusScaffold(
      title: 'Application Not Approved',
      message:
          'Your restaurant registration was not approved. '
          'Contact support for more information.',
      icon: Icons.cancel_outlined,
    );
  }
}

class AccountSuspendedScreen extends StatelessWidget {
  const AccountSuspendedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const _StatusScaffold(
      title: 'Account Suspended',
      message: 'Your account has been suspended. Contact support for help.',
      icon: Icons.block_rounded,
    );
  }
}
