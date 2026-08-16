import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Persists the Supabase session (JWT access/refresh tokens) in the
/// platform keystore/keychain via flutter_secure_storage, instead of
/// supabase_flutter's default SharedPreferences-backed storage. Session
/// tokens are sensitive — SharedPreferences is unencrypted on-disk storage.
class SecureSessionStorage extends LocalStorage {
  SecureSessionStorage({
    this.persistSessionKey = 'supabase.auth.token',
    FlutterSecureStorage? secureStorage,
  }) : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  final String persistSessionKey;
  final FlutterSecureStorage _secureStorage;

  @override
  Future<void> initialize() async {}

  @override
  Future<bool> hasAccessToken() async {
    return _secureStorage.containsKey(key: persistSessionKey);
  }

  @override
  Future<String?> accessToken() async {
    return _secureStorage.read(key: persistSessionKey);
  }

  @override
  Future<void> removePersistedSession() async {
    await _secureStorage.delete(key: persistSessionKey);
  }

  @override
  Future<void> persistSession(String persistSessionString) async {
    await _secureStorage.write(
      key: persistSessionKey,
      value: persistSessionString,
    );
  }
}
