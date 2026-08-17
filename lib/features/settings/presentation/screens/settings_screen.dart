import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

/// Settings screen: account/app menu list + logout + a support banner.
///
/// Business Details, Privacy Policy, About Us, Terms and Conditions, and
/// Return Order all route to real screens now. Language is the one
/// remaining row with no spec or backing screen — it shows a "coming
/// soon" message on tap, same treatment already used for Home's
/// notification bell and Cart's voice icon. Logout is real (unchanged
/// from the previous placeholder). The row icons and the support
/// banner's decorative art are Material-icon substitutes — the Figma
/// export only had empty placeholder boxes for them, no real assets to
/// port.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: AppColors.backgroundHome,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(
            16,
            16,
            16,
            AppSpacing.bottomNavHeight + AppSpacing.base,
          ),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Settings',
                        style: TextStyle(
                          color: AppColors.textHeading,
                          fontSize: 20,
                          fontFamily: AppTextStyles.fontFamily,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('Manage your account and app preferences', style: AppTextStyles.caption),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                _LogoutButton(
                  onTap: () async {
                    await ref.read(authRepositoryProvider).signOut();
                    if (context.mounted) context.go(AppRoutes.welcome);
                  },
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: AppColors.surfaceWhite,
                borderRadius: BorderRadius.circular(10),
                boxShadow: const [
                  BoxShadow(color: Color(0x3F000000), blurRadius: 4, offset: Offset(0, 1)),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                child: Column(
                  children: [
                    for (var i = 0; i < _rows.length; i++) ...[
                      _SettingsRow(
                        row: _rows[i],
                        onTap: () => switch (_rows[i].title) {
                          'Business Details' => context.push(AppRoutes.businessDetails),
                          'Privacy Policy' => context.push(AppRoutes.privacyPolicy),
                          'About Us' => context.push(AppRoutes.aboutUs),
                          'Terms and Conditions' => context.push(AppRoutes.termsView),
                          'Return Order' => context.push(AppRoutes.returnOrder),
                          _ => _showComingSoon(context, _rows[i].title),
                        },
                      ),
                      if (i < _rows.length - 1)
                        const Divider(color: AppColors.cardBorder, height: 1),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.base),
            const _HelpBanner(),
          ],
        ),
      ),
    );
  }

  void _showComingSoon(BuildContext context, String label) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$label is coming soon')));
  }
}

class _SettingsRowData {
  const _SettingsRowData({required this.icon, required this.title, required this.subtitle});

  final IconData icon;
  final String title;
  final String subtitle;
}

const _rows = [
  _SettingsRowData(
    icon: Icons.storefront_outlined,
    title: 'Business Details',
    subtitle: 'View and manage business information',
  ),
  _SettingsRowData(
    icon: Icons.verified_user_outlined,
    title: 'Privacy Policy',
    subtitle: 'Read our privacy policy',
  ),
  _SettingsRowData(
    icon: Icons.person_outline,
    title: 'About Us',
    subtitle: 'Learn more about our app and team',
  ),
  _SettingsRowData(
    icon: Icons.translate,
    title: 'Language',
    subtitle: 'Change your preferred language',
  ),
  _SettingsRowData(
    icon: Icons.assignment_return_outlined,
    title: 'Return Order',
    subtitle: 'View return policy and raise a request',
  ),
  _SettingsRowData(
    icon: Icons.description_outlined,
    title: 'Terms and Conditions',
    subtitle: 'Know your rights and responsibilities.',
  ),
];

class _SettingsRow extends StatelessWidget {
  const _SettingsRow({required this.row, required this.onTap});

  final _SettingsRowData row;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 6),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: const Color(0xFFA4FCA8),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(row.icon, color: AppColors.primary, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    row.title,
                    style: AppTextStyles.itemName.copyWith(fontSize: 14),
                  ),
                  Text(row.subtitle, style: AppTextStyles.caption),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.secondary, size: 20),
          ],
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  const _LogoutButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Log out',
      button: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: const Padding(
          padding: EdgeInsets.all(4),
          child: Icon(Icons.logout, color: AppColors.error, size: 24),
        ),
      ),
    );
  }
}

class _HelpBanner extends StatelessWidget {
  const _HelpBanner();

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(16)),
      child: Stack(
        children: [
          Positioned(
            right: -16,
            bottom: -16,
            child: Icon(
              Icons.storefront,
              size: 110,
              color: Colors.white.withValues(alpha: 0.12),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.call_outlined, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 14),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Need a help?',
                      style: TextStyle(
                        color: AppColors.ctaText,
                        fontSize: 16,
                        fontFamily: AppTextStyles.fontFamily,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    Text(
                      "We're here for you.",
                      style: TextStyle(
                        color: AppColors.ctaText,
                        fontSize: 16,
                        fontFamily: AppTextStyles.urbanistFontFamily,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
