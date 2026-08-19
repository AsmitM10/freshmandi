import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/fm_phone_field.dart';
import '../../../../shared/widgets/fm_primary_button.dart';
import '../../../../shared/widgets/fm_text_field.dart';
import '../../../auth/domain/restaurant_account.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

/// Edit Details — reached from Business Details' "Edit Profile" button.
/// Saves for real: Contact Person, Email, Delivery Address, and GST
/// Number all write back to `restaurants` (see the
/// restaurant-profile-editable-fields migration, which also had to fix
/// the RLS update policy — it previously only allowed writes while
/// account_status was still 'pending', which made this screen impossible
/// for any already-approved restaurant to use).
///
/// Restaurant Name and Phone Number are deliberately not editable here:
/// the phone number is the actual Supabase Auth identity (OTP login), so
/// changing it needs its own re-verification flow, not a plain profile
/// edit — shown read-only via the same [FMPhoneField] used at
/// registration rather than inventing a change-number flow that isn't
/// specified anywhere.
///
/// Returns `true` via [context.pop] on a successful save so the caller
/// (Business Details) knows to refresh and show a confirmation.
class EditDetailsScreen extends ConsumerWidget {
  const EditDetailsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final restaurantAsync = ref.watch(currentRestaurantProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundHome,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _Header(onBack: () => context.pop()),
            Expanded(
              child: restaurantAsync.when(
                loading: () => const LoadingState(),
                error: (error, _) => EmptyState(
                  icon: Icons.wifi_off_outlined,
                  message: "Couldn't load your details.",
                  action: TextButton(
                    onPressed: () => ref.refresh(currentRestaurantProvider),
                    child: const Text('Retry'),
                  ),
                ),
                data: (restaurant) => restaurant == null
                    ? const EmptyState(
                        icon: Icons.storefront_outlined,
                        message: 'No business details found.',
                      )
                    : _EditForm(restaurant: restaurant),
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
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: onBack,
                child: const Center(
                  child: Icon(Icons.arrow_back_ios_new, color: AppColors.primaryText, size: 20),
                ),
              ),
            ),
          ),
          Expanded(
            child: Text(
              'Edit Details',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: AppTextStyles.urbanistFontFamily,
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryText,
              ),
            ),
          ),
          const SizedBox(width: 32),
        ],
      ),
    );
  }
}

class _EditForm extends ConsumerStatefulWidget {
  const _EditForm({required this.restaurant});

  final RestaurantAccount restaurant;

  @override
  ConsumerState<_EditForm> createState() => _EditFormState();
}

class _EditFormState extends ConsumerState<_EditForm> {
  late final _ownerNameController = TextEditingController(text: widget.restaurant.ownerName);
  late final _phoneController = TextEditingController(text: _localDigits(widget.restaurant.phoneNumber));
  late final _emailController = TextEditingController(text: widget.restaurant.email ?? '');
  late final _deliveryAddressController = TextEditingController(
    text: widget.restaurant.deliveryAddress ?? '',
  );
  late final _gstController = TextEditingController(text: widget.restaurant.gstNumber ?? '');

  bool _isSaving = false;
  String? _ownerNameError;

  @override
  void dispose() {
    _ownerNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _deliveryAddressController.dispose();
    _gstController.dispose();
    super.dispose();
  }

  String _localDigits(String e164Phone) {
    // Stored as "+91XXXXXXXXXX" — FMPhoneField only ever holds the 10
    // local digits, the "+91" is its own fixed prefix.
    return e164Phone.startsWith('+91') ? e164Phone.substring(3) : e164Phone;
  }

  Future<void> _handleSave() async {
    final ownerName = _ownerNameController.text.trim();
    setState(() => _ownerNameError = ownerName.isEmpty ? 'Contact person is required' : null);
    if (_ownerNameError != null) return;

    setState(() => _isSaving = true);
    try {
      await ref
          .read(restaurantRepositoryProvider)
          .updateProfile(
            ownerName: ownerName,
            email: _emailController.text,
            deliveryAddress: _deliveryAddressController.text,
            gstNumber: _gstController.text,
          );
      ref.invalidate(currentRestaurantProvider);
      if (mounted) context.pop(true);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(const SnackBar(content: Text('Could not save your details. Please try again.')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.fromLTRB(16, 0, 16, AppSpacing.bottomNavHeight + AppSpacing.base),
      children: [
        const SizedBox(height: 16),
        Center(
          child: Container(
            width: 108,
            height: 108,
            decoration: const BoxDecoration(color: Color(0xFFD9D9D9), shape: BoxShape.circle),
          ),
        ),
        const SizedBox(height: 40),
        FMTextField(
          label: 'Contact Person',
          controller: _ownerNameController,
          textCapitalization: TextCapitalization.words,
          errorText: _ownerNameError,
          onChanged: (_) {
            if (_ownerNameError != null) setState(() => _ownerNameError = null);
          },
        ),
        const SizedBox(height: 16),
        FMPhoneField(controller: _phoneController, enabled: false),
        const SizedBox(height: 16),
        FMTextField(
          label: 'E-mail Address',
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        FMTextField(label: 'Delivery Address', controller: _deliveryAddressController),
        const SizedBox(height: 16),
        FMTextField(
          label: 'GST Number (optional)',
          controller: _gstController,
          textCapitalization: TextCapitalization.characters,
        ),
        const SizedBox(height: 32),
        FMPrimaryButton(label: 'Save Details', onPressed: _handleSave, isLoading: _isSaving),
      ],
    );
  }
}
