import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../shared/widgets/fm_primary_button.dart';

/// Not part of the original Figma inventory this app was first built
/// against — added per an updated spec: Welcome -> Terms & Conditions ->
/// Registration, with acceptance recorded on every restaurant account.
///
/// Two assets this spec calls for don't exist in the project and have no
/// substitute supplied: the T&C hero illustration (clipboard/document PNG,
/// 128x120.5) and the 8 "Vuesax note" row icons. Both are substituted below
/// with Material icons in brand colors — a minimal, design-consistent
/// placeholder per "if an asset is missing, report it clearly," not a
/// silent redesign. Swap in the real assets when available.
///
/// Row 5's title is rendered as "Data and Privacy" — the spec's source
/// text reads "Date and Privacy", flagged there as a likely typo. Same
/// handling as the "RESTURANT NAME" label: corrected here, flagged here,
/// not silently carried forward.
///
/// [readOnly] reuses this exact UI for Settings > Terms and Conditions —
/// same hero/last-updated/terms-card content the restaurant already agreed
/// to at registration, minus the interactive checkbox + "Proceed to
/// Register" button (which don't apply to an already-registered user
/// revisiting this from Settings). The agreement row instead shows as
/// already checked, non-interactively, since they already agreed once.
class TermsAndConditionsScreen extends StatefulWidget {
  const TermsAndConditionsScreen({super.key, this.readOnly = false});

  final bool readOnly;

  @override
  State<TermsAndConditionsScreen> createState() => _TermsAndConditionsScreenState();
}

class _TermsAndConditionsScreenState extends State<TermsAndConditionsScreen> {
  late bool _agreed = widget.readOnly;

  static const List<(String title, String body)> _rows = [
    (
      'Acceptance of Terms',
      'By using FreshMandi, you agree to comply with these Terms & Conditions and our Privacy Policy.',
    ),
    (
      'Eligibility',
      'FreshMandi is intended for registered restaurants, wholesalers, and authorized business users only.',
    ),
    (
      'Use of the App',
      'Users must use FreshMandi only for lawful business transactions and must not misuse the platform.',
    ),
    (
      'Orders and Payments',
      'All orders and payment responsibilities are governed by the agreement between the restaurant and the wholesaler.',
    ),
    (
      'Data and Privacy',
      'We securely collect and protect your business information in accordance with our Privacy Policy.',
    ),
    (
      'Limitations of Liability',
      'FreshMandi acts as a technology platform and is not responsible for commercial disputes between users.',
    ),
    (
      'Changes to Terms',
      'We may update these Terms & Conditions from time to time, and continued use indicates your acceptance.',
    ),
    (
      'Contact Us',
      'For any questions regarding these Terms & Conditions, please contact the FreshMandi support team.',
    ),
  ];

  void _proceed() {
    if (!_agreed) return;
    context.push(AppRoutes.register, extra: DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _Header(
              onBack: () =>
                  context.canPop() ? context.pop() : context.go(AppRoutes.welcome),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _HeroRow(),
                    const SizedBox(height: 20),
                    const _LastUpdatedRow(),
                    const SizedBox(height: 16),
                    _TermsCard(rows: _rows),
                    const SizedBox(height: 16),
                    _AgreementRow(
                      agreed: _agreed,
                      onToggle: widget.readOnly ? null : () => setState(() => _agreed = !_agreed),
                    ),
                    if (!widget.readOnly) ...[
                      const SizedBox(height: 16),
                      FMPrimaryButton(
                        label: 'Proceed to Register',
                        onPressed: _agreed ? _proceed : null,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
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
    return SizedBox(
      height: 56,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Align(
            alignment: Alignment.centerLeft,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onBack,
                customBorder: const CircleBorder(),
                child: const SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(
                    Icons.arrow_back_ios_new,
                    color: AppColors.primaryText,
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
          Text(
            'Terms and Conditions',
            style: GoogleFonts.urbanist(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.primaryText,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroRow extends StatelessWidget {
  const _HeroRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text.rich(
                TextSpan(
                  children: [
                    const TextSpan(
                      text: 'Welcome to ',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 20,
                        color: AppColors.secondaryText,
                      ),
                    ),
                    TextSpan(
                      text: 'FreshMandi',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 20,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Please read these Terms and Conditions carefully before using the app.',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: AppColors.placeholder,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // Placeholder for the missing T&C hero illustration — see class doc.
        Container(
          width: 128,
          height: 120.5,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: AppColors.iconBgLight,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.fact_check_outlined,
            size: 48,
            color: AppColors.primary,
          ),
        ),
      ],
    );
  }
}

class _LastUpdatedRow extends StatelessWidget {
  const _LastUpdatedRow();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.calendar_today_outlined,
            size: 20,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Last Updated',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: AppColors.placeholder,
              ),
            ),
            Text(
              '22 July 2026',
              style: GoogleFonts.urbanist(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.secondaryText,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TermsCard extends StatelessWidget {
  const _TermsCard({required this.rows});

  final List<(String title, String body)> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        boxShadow: AppShadows.card,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++)
            _TermsRow(
              title: rows[i].$1,
              body: rows[i].$2,
              iconBg: i < 5 ? AppColors.iconBgLight : AppColors.iconBgMuted,
              showTopBorder: i != 0,
            ),
        ],
      ),
    );
  }
}

class _TermsRow extends StatelessWidget {
  const _TermsRow({
    required this.title,
    required this.body,
    required this.iconBg,
    required this.showTopBorder,
  });

  final String title;
  final String body;
  final Color iconBg;
  final bool showTopBorder;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 94),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 12),
      decoration: BoxDecoration(
        border: showTopBorder
            ? const Border(top: BorderSide(color: AppColors.cardBorder, width: 0.5))
            : null,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            // Placeholder for the missing "Vuesax note" icon — see class doc.
            child: const Icon(
              Icons.description_outlined,
              size: 24,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: GoogleFonts.urbanist(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.secondaryText,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: AppColors.placeholder,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AgreementRow extends StatelessWidget {
  const _AgreementRow({required this.agreed, required this.onToggle});

  final bool agreed;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(8),
        child: Semantics(
          label: 'I agree to the Terms and Conditions',
          checked: agreed,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: agreed ? AppColors.primary : Colors.transparent,
                    border: Border.all(color: AppColors.primary, width: 1.5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: agreed
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'I have read and agree to the Terms and Conditions and Privacy Policy.',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      color: Colors.black,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
