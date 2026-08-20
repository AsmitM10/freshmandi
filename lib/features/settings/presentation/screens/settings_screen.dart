import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/localization/app_language.dart';
import '../../../../core/localization/language_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

/// Settings screen: account/app menu list + logout + a support banner.
///
/// Every row now routes to a real screen — Language was the last
/// remaining stub, now wired to [LanguageScreen]. Row navigation is keyed
/// on [_SettingsRowId], not the row's (localized, Hindi-in-Hindi-mode)
/// display title — matching on the literal English title would silently
/// break once the UI is in Hindi.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final language = ref.watch(languageProvider);
    final rows = _buildRows(l10n, language);

    return Scaffold(
      backgroundColor: AppColors.backgroundHome,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, 16, 16, AppSpacing.bottomNavHeight + AppSpacing.base),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        l10n.settingsTitle,
                        style: TextStyle(
                          color: AppColors.textHeading,
                          fontSize: 20,
                          fontFamily: AppTextStyles.fontFamily,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(l10n.settingsSubtitle, style: AppTextStyles.caption),
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
                    for (var i = 0; i < rows.length; i++) ...[
                      _SettingsRow(
                        row: rows[i],
                        onTap: () => switch (rows[i].id) {
                          _SettingsRowId.businessDetails => context.push(AppRoutes.businessDetails),
                          _SettingsRowId.privacyPolicy => context.push(AppRoutes.privacyPolicy),
                          _SettingsRowId.aboutUs => context.push(AppRoutes.aboutUs),
                          _SettingsRowId.language => context.push(AppRoutes.language),
                          _SettingsRowId.returnOrder => context.push(AppRoutes.returnOrder),
                          _SettingsRowId.terms => context.push(AppRoutes.termsView),
                        },
                      ),
                      if (i < rows.length - 1) const Divider(color: AppColors.cardBorder, height: 1),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.base),
            _HelpBanner(
              title: l10n.settingsHelpTitle,
              subtitle: l10n.settingsHelpSubtitle,
              onTap: () => context.push(AppRoutes.contactUs),
            ),
          ],
        ),
      ),
    );
  }

  List<_SettingsRowData> _buildRows(AppLocalizations l10n, AppLanguage language) {
    return [
      _SettingsRowData(
        id: _SettingsRowId.businessDetails,
        icon: Icons.storefront_outlined,
        title: l10n.settingsBusinessDetailsTitle,
        subtitle: l10n.settingsBusinessDetailsSubtitle,
      ),
      _SettingsRowData(
        id: _SettingsRowId.privacyPolicy,
        icon: Icons.verified_user_outlined,
        title: l10n.settingsPrivacyPolicyTitle,
        subtitle: l10n.settingsPrivacyPolicySubtitle,
      ),
      _SettingsRowData(
        id: _SettingsRowId.aboutUs,
        icon: Icons.person_outline,
        title: l10n.settingsAboutUsTitle,
        subtitle: l10n.settingsAboutUsSubtitle,
      ),
      _SettingsRowData(
        id: _SettingsRowId.language,
        icon: Icons.translate,
        title: l10n.settingsLanguageTitle,
        // Shows the currently selected language itself (not the generic
        // "change your preferred language" description) once one has
        // been chosen — same rule the Language screen's own row uses.
        subtitle: language == AppLanguage.english ? l10n.languageEnglish : l10n.languageHindi,
      ),
      _SettingsRowData(
        id: _SettingsRowId.returnOrder,
        icon: Icons.assignment_return_outlined,
        title: l10n.settingsReturnOrderTitle,
        subtitle: l10n.settingsReturnOrderSubtitle,
      ),
      _SettingsRowData(
        id: _SettingsRowId.terms,
        icon: Icons.description_outlined,
        title: l10n.settingsTermsTitle,
        subtitle: l10n.settingsTermsSubtitle,
      ),
    ];
  }
}

enum _SettingsRowId { businessDetails, privacyPolicy, aboutUs, language, returnOrder, terms }

class _SettingsRowData {
  const _SettingsRowData({
    required this.id,
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final _SettingsRowId id;
  final IconData icon;
  final String title;
  final String subtitle;
}

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
                  Text(row.title, style: AppTextStyles.itemName.copyWith(fontSize: 14)),
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
  const _HelpBanner({required this.title, required this.subtitle, required this.onTap});

  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      clipBehavior: Clip.antiAlias,
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        child: Stack(
          children: [
            Positioned(
              right: -16,
              bottom: -16,
              child: Icon(Icons.storefront, size: 110, color: Colors.white.withValues(alpha: 0.12)),
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
                        title,
                        style: TextStyle(
                          color: AppColors.ctaText,
                          fontSize: 16,
                          fontFamily: AppTextStyles.fontFamily,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      Text(
                        subtitle,
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
      ),
    );
  }
}
