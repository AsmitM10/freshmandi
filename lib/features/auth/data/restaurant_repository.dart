import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/errors/app_exception.dart';
import '../domain/restaurant_account.dart';

/// Reads/writes the `restaurants` row for the signed-in user. RLS (see the
/// SQL migration) enforces server-side that a user can only ever touch their
/// own row and can never set account_status to anything but 'pending'.
class RestaurantRepository {
  RestaurantRepository(this._client);

  final SupabaseClient _client;

  Future<RestaurantAccount?> fetchForCurrentUser() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;
    try {
      final row = await _client
          .from('restaurants')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      if (row == null) return null;
      return RestaurantAccount.fromMap(row);
    } catch (error) {
      throw mapErrorToAppException(error);
    }
  }

  /// Updates the editable subset of the caller's own profile (Edit
  /// Details screen). `restaurant_name` and `phone_number` are
  /// deliberately not settable here — the phone number is the actual
  /// Supabase Auth identity (OTP login), so changing it needs its own
  /// re-verification flow, not a plain profile edit. `account_status` is
  /// structurally protected server-side (see the profile-editable-fields
  /// migration's trigger) regardless of what this sends.
  Future<RestaurantAccount> updateProfile({
    required String ownerName,
    String? email,
    String? deliveryAddress,
    String? gstNumber,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AppException('You need to be signed in to continue.');
    }
    try {
      final row = await _client
          .from('restaurants')
          .update({
            'owner_name': ownerName.trim(),
            'email': _nullIfBlank(email),
            'delivery_address': _nullIfBlank(deliveryAddress),
            'gst_number': _nullIfBlank(gstNumber),
          })
          .eq('user_id', userId)
          .select()
          .single();
      return RestaurantAccount.fromMap(row);
    } catch (error) {
      throw mapErrorToAppException(error);
    }
  }

  String? _nullIfBlank(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  /// Server-side check via a SECURITY DEFINER RPC so an unauthenticated
  /// caller (pre-OTP-verification) can learn whether a phone is already
  /// registered without RLS exposing any restaurant row data.
  Future<bool> isPhoneRegistered(String e164Phone) async {
    try {
      final result = await _client.rpc(
        'is_phone_registered',
        params: {'p_phone': e164Phone},
      );
      return result as bool;
    } catch (error) {
      throw mapErrorToAppException(error);
    }
  }

  /// Creates or updates the caller's restaurant row, keyed on the unique
  /// `user_id` constraint. Safe to call again after an OTP resend/retry —
  /// it never creates a second row for the same verified user, and
  /// account_status is left untouched (RLS pins it to 'pending' regardless).
  Future<RestaurantAccount> upsertRegistration({
    required String restaurantName,
    required String ownerName,
    required String phoneNumber,
    required DateTime termsAcceptedAt,
    required String termsVersion,
  }) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) {
      throw const AppException('You need to be signed in to continue.');
    }
    try {
      final row = await _client
          .from('restaurants')
          .upsert({
            'user_id': userId,
            'restaurant_name': restaurantName.trim(),
            'owner_name': ownerName.trim(),
            'phone_number': phoneNumber,
            'terms_accepted_at': termsAcceptedAt.toUtc().toIso8601String(),
            'terms_version': termsVersion,
          }, onConflict: 'user_id')
          .select()
          .single();
      return RestaurantAccount.fromMap(row);
    } catch (error) {
      throw mapErrorToAppException(error);
    }
  }
}
