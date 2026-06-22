import 'dart:convert';

import '../../../core/network/backend_api_client.dart';
import '../../../core/storage/app_session_store.dart';
import '../domain/app_user_role.dart';

class AuthRepository {
  AuthRepository(this._apiClient, this._sessionStore);

  final BackendApiClient _apiClient;
  final AppSessionStore _sessionStore;

  Future<void> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.postJson(
      '/api/auth/login',
      {
        'email': email,
        'password': password,
      },
    );

    await _storeTokenResponse(response);
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.postJson(
      '/api/auth/register',
      {
        'name': name,
        'email': email,
        'password': password,
        // Always register as a customer; role assignments are performed by privileged accounts on the backend
        'role': AppUserRole.customer.apiValue,
      },
    );

    await _storeTokenResponse(response);
  }

  Future<void> logout() async {
    await _sessionStore.clearCustomerSession();
  }

  Future<AuthStateSnapshot> restore() async {
    return AuthStateSnapshot(
      accessToken: await _sessionStore.readAccessToken(),
      refreshToken: await _sessionStore.readRefreshToken(),
      role: appUserRoleFromStorage(await _sessionStore.readUserRole()),
    );
  }

  Future<void> _storeTokenResponse(dynamic response) async {
    final accessToken = response['accessToken'] as String?;
    final refreshToken = response['refreshToken'] as String?;

    if (accessToken == null || accessToken.isEmpty) {
      throw StateError('Auth response did not include an access token.');
    }

    await _sessionStore.saveAccessToken(accessToken);
    await _sessionStore.saveRefreshToken(refreshToken);
    final userId = _extractUserIdFromJwt(accessToken);
    if (userId != null) {
      await _sessionStore.saveUserId(userId);
    }
    // Attempt to extract role from JWT; if present save it so app can route accordingly.
    final roleFromToken = _extractRoleFromJwt(accessToken);
    if (roleFromToken != null) {
      await _sessionStore.saveUserRole(roleFromToken);
    }
  }

  String? _extractRoleFromJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = parts[1];
      var normalized = payload.replaceAll('-', '+').replaceAll('_', '/');
      while (normalized.length % 4 != 0) {
        normalized += '=';
      }
      final decoded = utf8.decode(base64Url.decode(normalized));
      final map = jsonDecode(decoded) as Map<String, dynamic>;
      // common claim names: 'role', 'roles', 'http://schemas.microsoft.com/ws/2008/06/identity/claims/role'
      if (map.containsKey('role')) return map['role'] as String?;
      if (map.containsKey('roles')) {
        final val = map['roles'];
        if (val is String) return val;
        if (val is List && val.isNotEmpty) return val.first as String;
      }
      const msRole = 'http://schemas.microsoft.com/ws/2008/06/identity/claims/role';
      if (map.containsKey(msRole)) {
        final val = map[msRole];
        if (val is String) return val;
        if (val is List && val.isNotEmpty) return val.first as String;
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  String? _extractUserIdFromJwt(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = parts[1];
      var normalized = payload.replaceAll('-', '+').replaceAll('_', '/');
      while (normalized.length % 4 != 0) {
        normalized += '=';
      }
      final decoded = utf8.decode(base64Url.decode(normalized));
      final map = jsonDecode(decoded) as Map<String, dynamic>;
      if (map.containsKey('http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier')) {
        return map['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier']?.toString();
      }
      if (map.containsKey('nameid')) {
        return map['nameid']?.toString();
      }
      if (map.containsKey('sub')) {
        return map['sub']?.toString();
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}

class AuthStateSnapshot {
  const AuthStateSnapshot({
    required this.accessToken,
    required this.refreshToken,
    required this.role,
  });

  final String? accessToken;
  final String? refreshToken;
  final AppUserRole? role;
}