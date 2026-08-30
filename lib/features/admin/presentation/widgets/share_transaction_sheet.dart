import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/theme/app_colors.dart';

/// "Share Transaction" bottom sheet — WhatsApp/SMS/Share row. All three
/// trigger the same image-generation-and-share flow (see the caller);
/// WhatsApp/SMS can't carry a file attachment via URL scheme, so the
/// native share/download flow is the only way any of them gets a real
/// image out — the three buttons are just labeled hints toward where you
/// might send it next, not three different behaviors.
Future<void> showShareTransactionSheet(
  BuildContext context, {
  required VoidCallback onWhatsApp,
  required VoidCallback onSms,
  required VoidCallback onShare,
}) {
  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.surfaceWhite,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 12, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Share Transaction',
                  style: TextStyle(
                    color: AppColors.primaryText,
                    fontSize: 18,
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.placeholder),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(color: AppColors.cardBorder, height: 24),
            Row(
              children: [
                _ShareOption(
                  // TEMPORARY: no WhatsApp SVG provided yet — swap for the
                  // real asset once given.
                  icon: const Icon(
                    Icons.chat_bubble_outline,
                    color: AppColors.secondary,
                    size: 24,
                  ),
                  label: 'Whatsapp',
                  onTap: () {
                    Navigator.of(context).pop();
                    onWhatsApp();
                  },
                ),
                _ShareOption(
                  icon: SvgPicture.asset(
                    'assets/icons/icon_sms.svg',
                    width: 24,
                    height: 24,
                    colorFilter: const ColorFilter.mode(
                      AppColors.secondary,
                      BlendMode.srcIn,
                    ),
                  ),
                  label: 'SMS',
                  onTap: () {
                    Navigator.of(context).pop();
                    onSms();
                  },
                ),
                _ShareOption(
                  icon: SvgPicture.asset(
                    'assets/icons/icon_share_admin.svg',
                    width: 24,
                    height: 24,
                    colorFilter: const ColorFilter.mode(
                      AppColors.secondary,
                      BlendMode.srcIn,
                    ),
                  ),
                  label: 'Share',
                  onTap: () {
                    Navigator.of(context).pop();
                    onShare();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

class _ShareOption extends StatelessWidget {
  const _ShareOption({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final Widget icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 28),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              icon,
              const SizedBox(height: 8),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.primaryText,
                  fontSize: 13,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
