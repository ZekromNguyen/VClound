import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../data/auth_repository.dart';

final _authRepoProvider = Provider<AuthRepository>((_) => AuthRepository());

/// Single source of truth for the current user.
///
/// Bootstrap reads `supabase.auth.currentSession` synchronously (which the
/// secure storage backed `SecureLocalStorage` restored at startup), then
/// subscribes to `onAuthStateChange` so subsequent sign-in/sign-out events
/// propagate. Splash, login, signup and GoRouter all watch this provider.
final authControllerProvider =
    AsyncNotifierProvider<AuthController, User?>(AuthController.new);

class AuthController extends AsyncNotifier<User?> {
  late final AuthRepository _repo;
  StreamSubscription<AuthState>? _sub;

  @override
  Future<User?> build() async {
    _repo = ref.watch(_authRepoProvider);
    _sub?.cancel();
    _sub = _repo.onAuthChange.listen((event) {
      final next = event.session?.user;
      state = AsyncData(next);
    });
    ref.onDispose(() => _sub?.cancel());
    return _repo.currentUser;
  }

  Future<void> signIn(String email, String password) async {
    state = const AsyncLoading();
    try {
      final user = await _repo.signIn(email: email, password: password);
      state = AsyncData(user);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    state = const AsyncLoading();
    try {
      final user = await _repo.signUp(
        email: email,
        password: password,
        displayName: displayName,
      );
      state = AsyncData(user);
    } catch (e, st) {
      state = AsyncError(e, st);
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _repo.signOut();
    // The onAuthStateChange listener will update `state` to null;
    // explicitly setting it removes a 1-frame stale user.
    state = const AsyncData(null);
  }
}
