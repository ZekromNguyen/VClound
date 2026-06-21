import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/failure.dart';

/// Thin facade around supabase auth. All auth flows in the app go
/// through here so the controllers don't talk to Supabase directly.
class AuthRepository {
  AuthRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  User? get currentUser => _client.auth.currentUser;

  Stream<AuthState> get onAuthChange => _client.auth.onAuthStateChange;

  Future<User> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      final res = await _client.auth.signUp(
        email: email,
        password: password,
        data: <String, dynamic>{'display_name': displayName},
      );
      final user = res.user;
      if (user == null) {
        throw Failure('Sign-up failed — no user returned.');
      }
      return user;
    } on AuthException catch (e) {
      throw Failure(_friendlyAuth(e));
    } catch (e) {
      throw Failure('Sign-up failed: ${e.toString()}');
    }
  }

  Future<User> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final res = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      final user = res.user;
      if (user == null) throw Failure('Login failed — no session.');
      return user;
    } on AuthException catch (e) {
      throw Failure(_friendlyAuth(e));
    } catch (e) {
      throw Failure('Login failed: ${e.toString()}');
    }
  }

  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  static String _friendlyAuth(AuthException e) {
    final msg = e.message.toLowerCase();
    if (msg.contains('invalid login credentials') ||
        msg.contains('invalid_credentials')) {
      return 'Wrong email or password.';
    }
    if (msg.contains('email not confirmed')) {
      return 'Email not yet confirmed. Please check your inbox.';
    }
    if (msg.contains('user already registered')) {
      return 'An account already exists for this email.';
    }
    if (msg.contains('password') && msg.contains('short')) {
      return 'Password is too short (min 6 characters).';
    }
    return e.message;
  }
}
