import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'auth_repository.dart';
import 'user.dart';

/// Ағымдағы пайдаланушы: null — кірмеген.
final authProvider = AsyncNotifierProvider<AuthController, User?>(
  AuthController.new,
);

class AuthController extends AsyncNotifier<User?> {
  AuthRepository get _repo => ref.read(authRepositoryProvider);

  @override
  Future<User?> build() => _repo.currentUser();

  Future<void> login(String phone, String password) async {
    await _repo.login(phone, password);
    state = AsyncData(await _repo.currentUser());
  }

  Future<void> register(
    String phone,
    String password,
    String passwordConfirm,
  ) async {
    await _repo.register(phone, password, passwordConfirm);
    await login(phone, password);
  }

  Future<void> reload() async {
    state = AsyncData(await _repo.currentUser());
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AsyncData(null);
  }
}

/// Қонақ режимі: тіркелмей-ақ қосымшаны қарау.
final guestModeProvider = NotifierProvider<GuestMode, bool>(GuestMode.new);

class GuestMode extends Notifier<bool> {
  @override
  bool build() => false;

  void enter() => state = true;
  void exit() => state = false;
}
