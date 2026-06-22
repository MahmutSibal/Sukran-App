import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../session/data/session_repository.dart';
import '../data/auth_repository.dart';
import '../domain/app_user_role.dart';
import '../domain/auth_state.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(
    ref.read(backendApiClientProvider),
    ref.read(appSessionStoreProvider),
  );
});

final authControllerProvider = AsyncNotifierProvider<AuthController, AuthState>(AuthController.new);

class AuthController extends AsyncNotifier<AuthState> {
  @override
  Future<AuthState> build() async {
    final snapshot = await ref.read(authRepositoryProvider).restore();
    return AuthState(
      accessToken: snapshot.accessToken,
      refreshToken: snapshot.refreshToken,
      role: snapshot.role,
    );
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    await ref.read(authRepositoryProvider).login(
          email: email,
          password: password,
        );
    state = AsyncData(
      AuthState(
        accessToken: await ref.read(appSessionStoreProvider).readAccessToken(),
        refreshToken: await ref.read(appSessionStoreProvider).readRefreshToken(),
        role: appUserRoleFromStorage(await ref.read(appSessionStoreProvider).readUserRole()),
      ),
    );
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    state = const AsyncLoading();
    await ref.read(authRepositoryProvider).register(
          name: name,
          email: email,
          password: password,
        );
    state = AsyncData(
      AuthState(
        accessToken: await ref.read(appSessionStoreProvider).readAccessToken(),
        refreshToken: await ref.read(appSessionStoreProvider).readRefreshToken(),
        role: appUserRoleFromStorage(await ref.read(appSessionStoreProvider).readUserRole()),
      ),
    );
  }

  Future<void> logout() async {
    state = const AsyncLoading();
    await ref.read(authRepositoryProvider).logout();
    state = const AsyncData(AuthState.empty());
  }
}