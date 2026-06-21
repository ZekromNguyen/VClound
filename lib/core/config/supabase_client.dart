import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Persistent secure storage for the Supabase auth session.
///
/// Stashes the access token in Keychain (iOS) / EncryptedSharedPreferences
/// (Android) so supabase-flutter's auto-refresh works after cold start.
/// Without this every launch forces a full re-login.
class SecureLocalStorage extends LocalStorage {
  SecureLocalStorage({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock,
              ),
            );

  final FlutterSecureStorage _storage;

  // supabase_flutter passes the persisted-session string here, and re-reads
  // it via accessToken(). For email/password auth, the string is the JWT.
  static const _key = 'vcloud_supabase_session';

  @override
  Future<void> initialize() async {
    // FlutterSecureStorage handles its own native init.
  }

  @override
  Future<bool> hasAccessToken() async {
    final raw = await _storage.read(key: _key);
    return raw != null && raw.isNotEmpty;
  }

  @override
  Future<String?> accessToken() => _storage.read(key: _key);

  @override
  Future<void> removePersistedSession() => _storage.delete(key: _key);

  @override
  Future<void> persistSession(String persistSessionString) =>
      _storage.write(key: _key, value: persistSessionString);
}
