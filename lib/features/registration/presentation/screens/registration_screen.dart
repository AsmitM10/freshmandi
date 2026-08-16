import 'dart:async';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_config.dart';
import '../../../../core/constants/app_routes.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../core/utils/file_validators.dart';
import '../../../../core/utils/validators.dart';
import '../../../../shared/widgets/fm_error_banner.dart';
import '../../../../shared/widgets/fm_file_upload_field.dart';
import '../../../../shared/widgets/fm_otp_input.dart';
import '../../../../shared/widgets/fm_phone_field.dart';
import '../../../../shared/widgets/fm_primary_button.dart';
import '../../../../shared/widgets/fm_text_field.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/selected_document.dart';

enum _RegistrationStep { form, otp }

/// Figma only designs the registration *form* (name/owner/phone/FSSAI +
/// Register CTA) — it does not design an OTP step for registration, even
/// though the product flow requires phone verification before the
/// restaurant row is created. Per "minimal design-consistent state": this
/// screen's OTP step reuses the same OTP block design as the Login screen
/// (FMOTPInput + resend text) inside the same bottom-sheet container,
/// rather than inventing a new visual pattern. Flagged here, not silently
/// designed.
class RegistrationScreen extends ConsumerStatefulWidget {
  const RegistrationScreen({super.key, this.termsAcceptedAt});

  /// When the user tapped "Proceed to Register" on the Terms screen. Passed
  /// through go_router's `extra`. A restaurant can never be created without
  /// this — see the guard in initState — because terms_accepted_at is a
  /// required column (see migration 20260808000003).
  final DateTime? termsAcceptedAt;

  @override
  ConsumerState<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends ConsumerState<RegistrationScreen> {
  final _restaurantNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _phoneController = TextEditingController();

  _RegistrationStep _step = _RegistrationStep.form;
  SelectedDocument? _document;

  String? _restaurantNameError;
  String? _ownerNameError;
  String? _phoneError;
  String? _fileError;
  String? _otpError;
  String _otpCode = '';
  int _otpResetToken = 0;

  bool _isSubmittingForm = false;
  bool _isPickingFile = false;
  bool _isVerifying = false;
  int _resendCooldown = 0;
  Timer? _cooldownTimer;

  @override
  void initState() {
    super.initState();
    if (widget.termsAcceptedAt == null) {
      // Reached without going through Terms (e.g. a direct deep link) —
      // send them there first rather than letting registration proceed
      // without a recorded acceptance.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) context.go(AppRoutes.terms);
      });
    }
  }

  @override
  void dispose() {
    _restaurantNameController.dispose();
    _ownerNameController.dispose();
    _phoneController.dispose();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  String get _e164Phone => Validators.toE164(_phoneController.text.trim());

  Future<void> _pickFssaiFile() async {
    setState(() => _isPickingFile = true);
    try {
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['pdf', 'jpg', 'jpeg', 'png'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final picked = result.files.single;
      final validation = FileValidators.validate(
        bytes: picked.bytes,
        sizeInBytes: picked.size,
      );
      if (!validation.isValid) {
        setState(() {
          _fileError = validation.errorMessage;
          _document = null;
        });
        return;
      }
      setState(() {
        _fileError = null;
        _document = SelectedDocument(
          fileName: picked.name,
          bytes: picked.bytes!,
          sizeInBytes: picked.size,
          mimeType: validation.mimeType!,
        );
      });
    } finally {
      if (mounted) setState(() => _isPickingFile = false);
    }
  }

  bool _validateForm() {
    final nameError = Validators.restaurantName(_restaurantNameController.text);
    final ownerError = Validators.ownerName(_ownerNameController.text);
    final phoneError = Validators.phoneDigits(_phoneController.text);
    final fileError = _document == null ? 'FSSAI certificate is required' : null;
    setState(() {
      _restaurantNameError = nameError;
      _ownerNameError = ownerError;
      _phoneError = phoneError;
      _fileError = fileError;
    });
    return nameError == null &&
        ownerError == null &&
        phoneError == null &&
        fileError == null;
  }

  Future<void> _submitForm() async {
    if (_isSubmittingForm || !_validateForm()) return;

    setState(() => _isSubmittingForm = true);
    try {
      final alreadyRegistered = await ref
          .read(restaurantRepositoryProvider)
          .isPhoneRegistered(_e164Phone);
      if (alreadyRegistered) {
        setState(
          () => _phoneError = 'This phone number is already registered',
        );
        return;
      }
      await ref.read(authRepositoryProvider).sendPhoneOtp(_e164Phone);
      if (!mounted) return;
      setState(() => _step = _RegistrationStep.otp);
      _startResendCooldown();
    } catch (error) {
      if (mounted) {
        showAppSnackBar(context, mapErrorToAppException(error).message);
      }
    } finally {
      if (mounted) setState(() => _isSubmittingForm = false);
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

  Future<void> _resendOtp() async {
    if (_resendCooldown > 0) return;
    try {
      await ref.read(authRepositoryProvider).sendPhoneOtp(_e164Phone);
      setState(() {
        _otpCode = '';
        _otpResetToken++;
        _otpError = null;
      });
      _startResendCooldown();
      if (mounted) showAppSnackBar(context, 'OTP sent again', isError: false);
    } catch (error) {
      if (mounted) {
        showAppSnackBar(context, mapErrorToAppException(error).message);
      }
    }
  }

  Future<void> _verifyAndRegister() async {
    if (_isVerifying) return;
    final termsAcceptedAt = widget.termsAcceptedAt;
    if (termsAcceptedAt == null) {
      context.go(AppRoutes.terms);
      return;
    }
    final otpValidation = Validators.otp(_otpCode);
    if (otpValidation != null) {
      setState(() => _otpError = otpValidation);
      return;
    }

    setState(() {
      _isVerifying = true;
      _otpError = null;
    });
    try {
      await ref
          .read(authRepositoryProvider)
          .verifyPhoneOtp(e164Phone: _e164Phone, otp: _otpCode);

      final restaurant = await ref
          .read(restaurantRepositoryProvider)
          .upsertRegistration(
            restaurantName: _restaurantNameController.text,
            ownerName: _ownerNameController.text,
            phoneNumber: _e164Phone,
            termsAcceptedAt: termsAcceptedAt,
            termsVersion: AppConfig.termsVersion,
          );

      final document = _document;
      if (document != null) {
        await ref
            .read(fssaiDocumentRepositoryProvider)
            .uploadAndRecord(
              restaurantId: restaurant.id,
              bytes: document.bytes,
              fileName: document.fileName,
              mimeType: document.mimeType,
              fileSize: document.sizeInBytes,
            );
      }

      ref.invalidate(currentRestaurantProvider);
      if (!mounted) return;
      context.go(AppRoutes.pendingApproval);
    } catch (error) {
      if (mounted) {
        showAppSnackBar(context, mapErrorToAppException(error).message);
      }
    } finally {
      if (mounted) setState(() => _isVerifying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.termsAcceptedAt == null) {
      // Redirecting to Terms (see initState) — avoid flashing the form.
      return const Scaffold(backgroundColor: AppColors.primary, body: SizedBox.shrink());
    }
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
                  const Positioned(
                    top: 82,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: SizedBox(
                        width: 195,
                        height: 200,
                        child: Image(
                          image: AssetImage('lib/assets/images/register.png'),
                          fit: BoxFit.contain,
                        ),
                      ),
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
                    16,
                    16,
                    MediaQuery.of(context).viewInsets.bottom + 16,
                  ),
                  child: _step == _RegistrationStep.form
                      ? _buildForm()
                      : _buildOtpStep(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: const TextSpan(
            children: [
              TextSpan(
                text: 'Create ',
                style: TextStyle(
                  color: Color(0xFF242424),
                  fontSize: 24,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  height: 1.8,
                ),
              ),
              TextSpan(
                text: 'Your Account\n',
                style: TextStyle(
                  color: Color(0xFF4A8754),
                  fontSize: 24,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  height: 1.8,
                ),
              ),
              TextSpan(
                text: "Let's get your restaurant registered",
                style: TextStyle(
                  color: Color(0xFF242424),
                  fontSize: 14,
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w500,
                  height: 1.8,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        FMTextField(
          label: 'Restaurant Name',
          controller: _restaurantNameController,
          textCapitalization: TextCapitalization.words,
          errorText: _restaurantNameError,
          enabled: !_isSubmittingForm,
        ),
        const SizedBox(height: 16),
        FMTextField(
          label: 'Owner Name',
          controller: _ownerNameController,
          textCapitalization: TextCapitalization.words,
          errorText: _ownerNameError,
          enabled: !_isSubmittingForm,
        ),
        const SizedBox(height: 16),
        FMPhoneField(
          controller: _phoneController,
          errorText: _phoneError,
          enabled: !_isSubmittingForm,
        ),
        const SizedBox(height: 16),
        FMFileUploadField(
          label: 'FSSAI Certificate',
          onTap: _isSubmittingForm ? () {} : _pickFssaiFile,
          selectedFileName: _document?.fileName,
          onClear: _isSubmittingForm
              ? null
              : () => setState(() {
                  _document = null;
                  _fileError = null;
                }),
          errorText: _fileError,
          isLoading: _isPickingFile,
        ),
        const SizedBox(height: 24),
        FMPrimaryButton(
          label: 'Register',
          isLoading: _isSubmittingForm,
          onPressed: _submitForm,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildOtpStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Verify Your Phone', style: AppTextStyles.heading),
        const SizedBox(height: 8),
        Text(
          'Enter the ${AppConfig.otpLength}-digit code sent to +91 ${_phoneController.text}',
          style: AppTextStyles.bodySmall,
        ),
        const SizedBox(height: 20),
        FMOTPInput(
          resetToken: _otpResetToken,
          enabled: !_isVerifying,
          onChanged: (value) => setState(() {
            _otpCode = value;
            _otpError = null;
          }),
        ),
        if (_otpError != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _otpError!,
              style: const TextStyle(color: AppColors.error, fontSize: 12),
            ),
          ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton(
              onPressed: _isVerifying
                  ? null
                  : () => setState(() => _step = _RegistrationStep.form),
              child: const Text(
                'Edit details',
                style: TextStyle(
                  color: AppColors.secondary,
                  fontSize: 12,
                  fontFamily: 'Poppins',
                ),
              ),
            ),
            TextButton(
              onPressed: _resendCooldown > 0 ? null : _resendOtp,
              child: Text(
                _resendCooldown > 0
                    ? 'Resend OTP in ${_resendCooldown}s'
                    : 'Resend OTP',
                style: const TextStyle(
                  color: AppColors.secondary,
                  fontSize: 12,
                  fontFamily: 'Poppins',
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        FMPrimaryButton(
          label: 'Verify & Register',
          isLoading: _isVerifying,
          onPressed: _verifyAndRegister,
        ),
        const SizedBox(height: 16),
      ],
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
