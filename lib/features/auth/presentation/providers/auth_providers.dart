import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../registration/data/fssai_document_repository.dart';
import '../../data/auth_repository.dart';
import '../../data/restaurant_repository.dart';
import '../../domain/restaurant_account.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.watch(supabaseClientProvider));
});

final restaurantRepositoryProvider = Provider<RestaurantRepository>((ref) {
  return RestaurantRepository(ref.watch(supabaseClientProvider));
});

final fssaiDocumentRepositoryProvider = Provider<FssaiDocumentRepository>((ref) {
  return FssaiDocumentRepository(ref.watch(supabaseClientProvider));
});

/// Fires on sign-in, sign-out, token refresh, and session recovery.
final authStateChangesProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authRepositoryProvider).authStateChanges;
});

/// The signed-in user's restaurant row, or null if signed out / not yet
/// registered. Re-fetches automatically whenever session presence actually
/// changes (sign-in <-> sign-out), but NOT on every single auth event.
///
/// Supabase's auth client commonly fires more than one event around a
/// sign-in (e.g. SIGNED_IN immediately followed by TOKEN_REFRESHED). A
/// plain `ref.watch(authStateChangesProvider)` here would restart this
/// provider's async body from scratch on every one of those events — if a
/// second event lands while `fetchForCurrentUser()` is still in flight,
/// that request gets abandoned mid-flight, and the `.future` a caller is
/// awaiting (e.g. right after login) can hang forever with no result and
/// no error. `.select` only triggers a rebuild when the *boolean* result
/// changes, so a same-state re-emission (still signed in) is a no-op.
final currentRestaurantProvider = FutureProvider<RestaurantAccount?>((ref) async {
  // ignore: avoid_print
  print('[RESTAURANT] provider body starting');
  final hasSessionFromStream = ref.watch(
    authStateChangesProvider.select((state) => state.valueOrNull?.session != null),
  );
  final hasSession =
      hasSessionFromStream || ref.watch(supabaseClientProvider).auth.currentSession != null;
  // ignore: avoid_print
  print('[RESTAURANT] hasSession=$hasSession (fromStream=$hasSessionFromStream)');
  if (!hasSession) return null;
  // ignore: avoid_print
  print('[RESTAURANT] calling fetchForCurrentUser()...');
  final result = await ref.watch(restaurantRepositoryProvider).fetchForCurrentUser();
  // ignore: avoid_print
  print('[RESTAURANT] fetchForCurrentUser() returned: ${result?.accountStatus}');
  return result;
});
