import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../domain/admin_transaction.dart';

/// One transaction row — #index, restaurant name + date, total/balance,
/// print + share actions. Shared by the Home dashboard's Transactions list
/// and the Day Book screen (same card, same data shape, just a different
/// query behind it), so this look only needs to be built once.
class TransactionCard extends StatelessWidget {
  const TransactionCard({
    super.key,
    required this.index,
    required this.transaction,
    required this.isSharing,
    required this.onTap,
    required this.onPrint,
    required this.onShare,
  });

  final int index;
  final AdminTransaction transaction;
  final bool isSharing;
  final VoidCallback onTap;
  final VoidCallback onPrint;
  final VoidCallback onShare;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onTap, child: _buildCard(context)),
    );
  }

  Widget _buildCard(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: '#$index  ',
                        style: const TextStyle(
                          color: AppColors.primaryText,
                          fontSize: 15,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                      TextSpan(
                        text: transaction.restaurantName,
                        style: const TextStyle(
                          color: AppColors.primaryText,
                          fontSize: 15,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                DateFormat('dd MMM, yyyy').format(transaction.createdAt),
                style: const TextStyle(
                  color: AppColors.placeholder,
                  fontSize: 12,
                  fontFamily: 'Poppins',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.cardBorder),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'TOTAL AMT.',
                      style: AppTextStyles.labelUppercase,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '₹${NumberFormat('#,##0').format(transaction.invoiceTotal)}',
                      style: AppTextStyles.amountMedium,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    const Text(
                      'BALANCE',
                      textAlign: TextAlign.right,
                      style: AppTextStyles.labelUppercase,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '₹${NumberFormat('#,##0').format(transaction.balance)}',
                      textAlign: TextAlign.right,
                      style: AppTextStyles.amountMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              InkWell(
                onTap: onPrint,
                child: SvgPicture.asset(
                  'assets/icons/icon_print.svg',
                  width: 22,
                  height: 22,
                ),
              ),
              const SizedBox(width: 12),
              if (isSharing)
                const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                InkWell(
                  onTap: onShare,
                  child: SvgPicture.asset(
                    'assets/icons/icon_share_admin.svg',
                    width: 22,
                    height: 22,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
