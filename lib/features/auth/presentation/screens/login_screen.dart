import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_config.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/fm_error_banner.dart';
import '../../../../shared/widgets/fm_otp_input.dart';
import '../../../../shared/widgets/fm_phone_field.dart';
import '../../../../shared/widgets/fm_primary_button.dart';
import '../../domain/account_status.dart';
import '../providers/auth_providers.dart';

/// Figma shows the phone field and the OTP block together on one screen
/// with a single "Login" CTA and a "Resend OTP" link — no separate
/// "Send OTP" button. Reproduced here by having that same link do double
/// duty: it reads "Send OTP" until a code has been requested for the
/// current phone number, then flips to "Resend OTP" (with a cooldown) —
/// the OTP boxes stay disabled until then. This is the "simple text-state
/// change" the spec allows for the (undesigned) resend behavior.
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _phoneController = TextEditingController();

  String? _phoneError;
  String? _otpError;
  String _otpCode = '';
  int _otpResetToken = 0;

  bool _isOtpSent = false;
  bool _isSendingOtp = false;
  bool _isVerifying = false;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  @override
  void dispose() {
    _phoneController.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  String get _e164Phone => Validators.toE164(_phoneController.text.trim());

  /// The one admin's phone field is a client-side UI trigger only — not
  /// sent to Supabase as a real phone number. See AppConfig.adminPhoneDigits.
  bool get _isAdminPhone => _phoneController.text.trim() == AppConfig.adminPhoneDigits;

  Future<void> _sendOtp() async {
    if (_isSendingOtp || _resendCooldown > 0) return;
    final phoneError = Validators.phoneDigits(_phoneController.text);
    if (phoneError != null) {
      setState(() => _phoneError = phoneError);
      return;
    }

    if (_isAdminPhone) {
      // No real phone number to send an SMS to — just reveal the code
      // boxes, which double as PIN entry for the admin sign-in path below.
      setState(() {
        _isOtpSent = true;
        _otpCode = '';
        _otpResetToken++;
        _otpError = null;
      });
      return;
    }

    setState(() {
      _isSendingOtp = true;
      _phoneError = null;
    });
    try {
      await ref.read(authRepositoryProvider).sendPhoneOtp(_e164Phone);
      setState(() {
        _isOtpSent = true;
        _otpCode = '';
        _otpResetToken++;
        _otpError = null;
      });
      _startResendCooldown();
    } catch (error) {
      if (mounted) {
        showAppSnackBar(context, mapErrorToAppException(error).message);
      }
    } finally {
      if (mounted) setState(() => _isSendingOtp = false);
    }
  }

  void _startResendCooldown() {
    _cooldownTimer?.cancel();
    setState(() => _resendCooldown = AppConfig.otpResendCooldownSeconds);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendCooldown <= 1) {
        timer.cancel();
        setState(() => _resendCooldown = 0);
      } else {
        setState(() => _resendCooldown -= 1);
      }
    });
  }

  // TEMPORARY debug instrumentation — remove once the "stuck on login"
  // report is confirmed fixed. Prints to the `flutter run` terminal so we
  // can see exactly which step a stalled login attempt is stuck on.
  Future<void> _login() async {
    if (_isVerifying) return;
    final phoneError = Validators.phoneDigits(_phoneController.text);
    if (phoneError != null) {
      // ignore: avoid_print
      print('[LOGIN] blocked: phone invalid ($phoneError)');
      setState(() => _phoneError = phoneError);
      return;
    }
    if (!_isOtpSent) {
      // ignore: avoid_print
      print('[LOGIN] blocked: _isOtpSent is false — OTP was never sent for this number');
      showAppSnackBar(context, 'Send the OTP first');
      return;
    }
    final otpError = Validators.otp(_otpCode);
    if (otpError != null) {
      // ignore: avoid_print
      print('[LOGIN] blocked: otp invalid ($otpError), _otpCode="$_otpCode"');
      setState(() => _otpError = otpError);
      return;
    }

    setState(() {
      _isVerifying = true;
      _otpError = null;
    });

    if (_isAdminPhone) {
      try {
        await ref.read(authRepositoryProvider).signInAdmin(_otpCode);
        await ref.read(authRepositoryProvider).claimAdmin();
        if (!mounted) return;
        context.go(AppRoutes.adminHome);
      } catch (error) {
        if (mounted) {
          setState(() => _otpError = mapErrorToAppException(error).message);
        }
      } finally {
        if (mounted) setState(() => _isVerifying = false);
      }
      return;
    }

    // ignore: avoid_print
    print('[LOGIN] verifying otp for $_e164Phone...');
    try {
      await ref
          .read(authRepositoryProvider)
          .verifyPhoneOtp(e164Phone: _e164Phone, otp: _otpCode);
      // ignore: avoid_print
      print('[LOGIN] otp verified, session=${ref.read(supabaseClientProvider).auth.currentSession != null}');

      // Calling the repository directly here rather than awaiting
      // currentRestaurantProvider.future — that Future was observed to
      // never resolve after a fresh ref.invalidate() immediately followed
      // by a read, even though the provider's own async body completed
      // and returned a value (reproduced repeatedly with full Flutter +
      // Zone error instrumentation showing nothing thrown). The
      // repository call itself is proven reliable. Still invalidate the
      // provider afterward (not awaited) so Home's own
      // ref.watch(currentRestaurantProvider) picks up a fresh value.
      final restaurant = await ref.read(restaurantRepositoryProvider).fetchForCurrentUser();
      ref.invalidate(currentRestaurantProvider);
      // ignore: avoid_print
      print('[LOGIN] restaurant fetched: ${restaurant?.accountStatus}');

      if (restaurant == null) {
        // Verified a real phone number but there's no restaurant on file —
        // don't leave them signed in with nowhere valid to go.
        // ignore: avoid_print
        print('[LOGIN] no restaurant row for this user — signing back out');
        await ref.read(authRepositoryProvider).signOut();
        if (mounted) {
          showAppSnackBar(
            context,
            'No account found for this number. Please register first.',
          );
        }
        return;
      }

      if (!mounted) return;
      // ignore: avoid_print
      print('[LOGIN] navigating to ${restaurant.accountStatus.destinationRoute}');
      context.go(restaurant.accountStatus.destinationRoute);
    } catch (error, stack) {
      // ignore: avoid_print
      print('[LOGIN] error: $error\n$stack');
      if (mounted) {
        showAppSnackBar(context, mapErrorToAppException(error).message);
      }
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    const imageSize = 200.0;

    return Scaffold(
      backgroundColor: AppColors.primary,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            SizedBox(
              height: 304,
              child: Stack(
                children: [
                  Positioned(
                    left: 8,
                    top: 8,
                    child: _BackButton(
                      onTap: () => context.canPop()
                          ? context.pop()
                          : context.go(AppRoutes.welcome),
                    ),
                  ),
                  Positioned(
                    top: 82,
                    left: (screenWidth - imageSize).clamp(0, double.infinity) / 2,
                    child: Image.asset(
                      'lib/assets/images/login.png',
                      width: imageSize,
                      height: imageSize,
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x15000000),
                      blurRadius: 12,
                      offset: Offset(0, -2),
                    ),
                  ],
                ),
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    24,
                    16,
                    MediaQuery.of(context).viewInsets.bottom + 16,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'Welcome',
                              style: TextStyle(
                                color: Color(0xFF4A8754),
                                fontSize: 24,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            TextSpan(
                              text: ' back!',
                              style: TextStyle(
                                color: Color(0xFF242424),
                                fontSize: 24,
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'login to access your account',
                        style: TextStyle(
                          color: Color(0xFF242424),
                          fontSize: 14,
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 20),
                      FMPhoneField(
                        controller: _phoneController,
                        errorText: _phoneError,
                        enabled: !_isVerifying,
                        onChanged: (_) {
                          if (_isOtpSent) {
                            // Phone changed after an OTP was already sent —
                            // that OTP no longer applies to this number.
                            setState(() {
                              _isOtpSent = false;
                              _otpCode = '';
                              _otpResetToken++;
                              _cooldownTimer?.cancel();
                              _resendCooldown = 0;
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),
                      Opacity(
                        opacity: _isOtpSent ? 1 : 0.5,
                        child: IgnorePointer(
                          ignoring: !_isOtpSent,
                          child: FMOTPInput(
                            resetToken: _otpResetToken,
                            enabled: _isOtpSent && !_isVerifying,
                            onChanged: (value) => setState(() {
                              _otpCode = value;
                              _otpError = null;
                            }),
                          ),
                        ),
                      ),
                      if (_otpError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            _otpError!,
                            style: const TextStyle(
                              color: AppColors.error,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _resendCooldown > 0 ? null : _sendOtp,
                          child: _isSendingOtp
                              ? const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : Text(
                                  _resendCooldown > 0
                                      ? 'Resend OTP in ${_resendCooldown}s'
                                      : (_isOtpSent ? 'Resend OTP' : 'Send OTP'),
                                  style: const TextStyle(
                                    color: Color(0xFF355C7D),
                                    fontSize: 12,
                                    fontFamily: 'Poppins',
                                    fontWeight: FontWeight.w400,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      FMPrimaryButton(
                        label: 'Login',
                        isLoading: _isVerifying,
                        onPressed: _login,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: const SizedBox(
          width: 44,
          height: 44,
          child: Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}
