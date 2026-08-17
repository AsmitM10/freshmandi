import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_routes.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../providers/orders_providers.dart';

/// Shown when Place Order fails — mirrors [OrderSuccessScreen]'s badge
/// treatment in red instead of green. "Try Again" re-runs the exact same
/// [submitCartOrder] submission the Cart screen's Place Order button uses
/// (the cart was never cleared since the earlier attempt failed, so
/// nothing was lost), replacing this screen with the success screen if it
/// works, or updating the shown message in place if it fails again.
class OrderFailureScreen extends ConsumerStatefulWidget {
  const OrderFailureScreen({super.key, required this.message});

  final String message;

  @override
  ConsumerState<OrderFailureScreen> createState() => _OrderFailureScreenState();
}

class _OrderFailureScreenState extends ConsumerState<OrderFailureScreen> {
  bool _isRetrying = false;
  late String _message = widget.message;

  Future<void> _handleRetry() async {
    if (_isRetrying) return;
    setState(() => _isRetrying = true);
    try {
      final orderId = await submitCartOrder(ref);
      if (!mounted) return;
      context.go('${AppRoutes.orderSuccess}/$orderId');
    } catch (error) {
      if (mounted) {
        setState(() {
          _message = mapErrorToAppException(error).message;
          _isRetrying = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundHome,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Row(
                children: [
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => context.pop(),
                        child: const Center(
                          child: Icon(
                            Icons.arrow_back_ios_new,
                            color: AppColors.primaryText,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                children: [
                  const _FailureBadge(),
                  const SizedBox(height: AppSpacing.base),
                  Text(
                    'Oops! Something went wrong',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.secondaryText,
                      fontSize: 20,
                      fontFamily: AppTextStyles.fontFamily,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  const Center(child: _ErrorCodeBadge()),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    _message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.placeholder,
                      fontSize: 14,
                      fontFamily: AppTextStyles.fontFamily,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  SizedBox(
                    height: 48,
                    child: FilledButton(
                      onPressed: _isRetrying ? null : _handleRetry,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.secondary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: _isRetrying
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              'Try Again',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontFamily: AppTextStyles.fontFamily,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SizedBox(
                    height: 48,
                    child: OutlinedButton(
                      onPressed: () => context.go(AppRoutes.home),
                      style: OutlinedButton.styleFrom(
                        backgroundColor: AppColors.background,
                        side: const BorderSide(color: AppColors.secondary),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text(
                        'Go To Home',
                        style: TextStyle(
                          color: AppColors.secondary,
                          fontSize: 16,
                          fontFamily: AppTextStyles.fontFamily,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
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

class _ErrorCodeBadge extends StatelessWidget {
  const _ErrorCodeBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFFFDCDB),
        borderRadius: BorderRadius.circular(50),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFB90B01), size: 16),
          const SizedBox(width: 8),
          Text(
            'Error Code ORD-500',
            style: TextStyle(
              color: const Color(0xFFB90B01),
              fontSize: 14,
              fontFamily: AppTextStyles.urbanistFontFamily,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Same concentric-circle badge treatment as [OrderSuccessScreen]'s
/// success badge, in red instead of green, with a warning triangle glyph.
class _FailureBadge extends StatelessWidget {
  const _FailureBadge();

  static const _innerRadius = 48.0;
  static const _outerRadius = 68.0;
  static const _innerCount = 8;
  static const _outerCount = 8;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 140,
      child: Center(
        child: SizedBox(
          width: 170,
          height: 140,
          child: Stack(
            alignment: Alignment.center,
            children: [
              for (var i = 0; i < _innerCount; i++)
                _ScatterDot(
                  angle: (2 * math.pi * i) / _innerCount,
                  radius: _innerRadius,
                  color: const Color(0xFFB90B01),
                ),
              for (var i = 0; i < _outerCount; i++)
                _ScatterDot(
                  angle: (2 * math.pi * i) / _outerCount + (math.pi / _outerCount),
                  radius: _outerRadius,
                  color: const Color(0xFFFFDCDB),
                ),
              Container(
                width: 90,
                height: 90,
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: Color(0xFFFFDCDB), shape: BoxShape.circle),
                child: Container(
                  width: 70,
                  height: 70,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(color: Color(0xFFFFA19C), shape: BoxShape.circle),
                  child: Container(
                    width: 50,
                    height: 50,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(color: Color(0xFFB90A01), shape: BoxShape.circle),
                    child: const Icon(
                      Icons.warning_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ScatterDot extends StatelessWidget {
  const _ScatterDot({required this.angle, required this.radius, required this.color});

  final double angle;
  final double radius;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(radius * math.cos(angle), radius * math.sin(angle)),
      child: Transform.rotate(
        angle: -0.77,
        child: Container(width: 8, height: 8, color: color),
      ),
    );
  }
}
