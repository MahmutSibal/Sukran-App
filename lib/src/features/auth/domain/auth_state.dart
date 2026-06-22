import 'app_user_role.dart';

class AuthState {
  const AuthState({
    required this.accessToken,
    required this.refreshToken,
    required this.role,
  });

  const AuthState.empty()
      : accessToken = null,
        refreshToken = null,
        role = null;

  final String? accessToken;
  final String? refreshToken;
  final AppUserRole? role;

  bool get isAuthenticated => accessToken != null;
}