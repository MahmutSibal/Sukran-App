import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../storage/app_session_store.dart';

class ApiException implements Exception {
  ApiException(this.statusCode, this.message);

  final int statusCode;
  final String message;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class BackendApiClient {
  BackendApiClient({
    required AppSessionStore sessionStore,
    http.Client? httpClient,
    this.onSessionExpired,
  })  : _sessionStore = sessionStore,
        _httpClient = httpClient ?? http.Client();

  final AppSessionStore _sessionStore;
  final http.Client _httpClient;

  /// Refresh token da geçersizleştiğinde (yenileme başarısız) tetiklenir.
  /// Uygulama bu noktada oturumu temizleyip kullanıcıyı QR ekranına döndürür.
  final Future<void> Function()? onSessionExpired;

  /// Eşzamanlı 401 isteklerinin tek bir refresh çağrısını paylaşması için.
  Future<String?>? _refreshFuture;

  Uri _buildUri(String path, [Map<String, dynamic>? queryParameters]) {
    final uri = Uri.parse(AppConfig.apiBaseUrl).resolve(path);
    return queryParameters == null
        ? uri
        : uri.replace(
            queryParameters: queryParameters.map((key, value) => MapEntry(key, value.toString())),
          );
  }

  Map<String, String> _headers({String? accessToken}) {
    return <String, String>{
      'Content-Type': 'application/json; charset=utf-8',
      'Accept': 'application/json',
      // ngrok tüneli tarayıcı uyarı sayfası döndürmesin (JSON beklediğimiz için kritik).
      'ngrok-skip-browser-warning': 'true',
      if (accessToken != null && accessToken.isNotEmpty) 'Authorization': 'Bearer $accessToken',
    };
  }

  Future<dynamic> getJson(String path, {Map<String, dynamic>? queryParameters, String? accessToken}) {
    return _send('GET', path, queryParameters: queryParameters, accessToken: accessToken);
  }

  Future<dynamic> postJson(String path, Object body, {String? accessToken}) {
    return _send('POST', path, body: body, accessToken: accessToken);
  }

  Future<dynamic> putJson(String path, Object body, {String? accessToken}) {
    return _send('PUT', path, body: body, accessToken: accessToken);
  }

  Future<dynamic> deleteJson(String path, {String? accessToken}) {
    return _send('DELETE', path, accessToken: accessToken);
  }

  /// Tüm isteklerin tek geçiş noktası: 401 alınca refresh token ile bir kez
  /// access token yeniler ve isteği tekrar dener. Yenileme de başarısızsa
  /// [onSessionExpired] çağrılır.
  Future<dynamic> _send(
    String method,
    String path, {
    Map<String, dynamic>? queryParameters,
    Object? body,
    String? accessToken,
  }) async {
    final token = accessToken ?? await _sessionStore.readAccessToken();
    var response = await _dispatch(method, path, queryParameters: queryParameters, body: body, accessToken: token);

    if (response.statusCode == 401) {
      final refreshed = await _refreshAccessToken();
      if (refreshed != null) {
        // Eski (artık geçersiz) açık token yerine taze token ile tekrar dene.
        response = await _dispatch(method, path, queryParameters: queryParameters, body: body, accessToken: refreshed);
      }
      if (response.statusCode == 401) {
        await onSessionExpired?.call();
      }
    }

    return _decodeResponse(response);
  }

  Future<http.Response> _dispatch(
    String method,
    String path, {
    Map<String, dynamic>? queryParameters,
    Object? body,
    String? accessToken,
  }) {
    final uri = _buildUri(path, queryParameters);
    final headers = _headers(accessToken: accessToken);
    switch (method) {
      case 'POST':
        return _httpClient.post(uri, headers: headers, body: jsonEncode(body));
      case 'PUT':
        return _httpClient.put(uri, headers: headers, body: jsonEncode(body));
      case 'DELETE':
        return _httpClient.delete(uri, headers: headers);
      case 'GET':
      default:
        return _httpClient.get(uri, headers: headers);
    }
  }

  /// `/api/auth/refresh` ile yeni access token alır ve depoya yazar.
  /// Eşzamanlı çağrılar aynı Future'ı paylaşır (tek refresh).
  Future<String?> _refreshAccessToken() {
    return _refreshFuture ??= _performRefresh().whenComplete(() => _refreshFuture = null);
  }

  Future<String?> _performRefresh() async {
    final refreshToken = await _sessionStore.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      return null;
    }
    try {
      final response = await _httpClient.post(
        _buildUri('/api/auth/refresh'),
        headers: _headers(),
        body: jsonEncode(<String, dynamic>{'refreshToken': refreshToken}),
      );
      if (response.statusCode < 200 || response.statusCode >= 300 || response.body.isEmpty) {
        return null;
      }
      final body = jsonDecode(response.body);
      if (body is! Map<String, dynamic>) {
        return null;
      }
      final newAccess = body['accessToken'] as String?;
      final newRefresh = body['refreshToken'] as String?;
      if (newAccess == null || newAccess.isEmpty) {
        return null;
      }
      await _sessionStore.saveAccessToken(newAccess);
      await _sessionStore.saveRefreshToken(newRefresh);
      return newAccess;
    } catch (_) {
      return null;
    }
  }

  dynamic _decodeResponse(http.Response response) {
    if (response.statusCode == 204 || response.body.isEmpty) {
      return null;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    }

    throw ApiException(response.statusCode, response.body.isEmpty ? 'Request failed' : response.body);
  }
}
