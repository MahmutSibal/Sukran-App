import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/session/domain/customer_session.dart';

class AppSessionStore {
  static const _keyAccessToken = 'appsukran_access_token';
  static const _keyUserRole = 'appsukran_user_role';
  static const _keyUserId = 'appsukran_user_id';
  static const _keyRestaurantId = 'appsukran_restaurant_id';
  static const _keyTableNo = 'appsukran_table_no';
  static const _keyTableSessionId = 'appsukran_table_session_id';
  static const _keyRefreshToken = 'appsukran_refresh_token';

  final FlutterSecureStorage _secureStorage;

  AppSessionStore({FlutterSecureStorage? secureStorage})
      : _secureStorage = secureStorage ?? const FlutterSecureStorage();

  Future<void> saveCustomerSession(CustomerSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyRestaurantId, session.restaurantId);
    await prefs.setInt(_keyTableNo, session.tableNo);
    await prefs.setString(_keyTableSessionId, session.tableSessionId);
    await prefs.setString(_keyUserRole, 'customer');
    await _secureStorage.write(key: _keyAccessToken, value: session.accessToken);
    if (session.refreshToken != null) {
      await _secureStorage.write(key: _keyRefreshToken, value: session.refreshToken);
    }
  }

  Future<CustomerSession?> readCustomerSession() async {
    final prefs = await SharedPreferences.getInstance();
    final restaurantId = prefs.getString(_keyRestaurantId);
    final tableNo = prefs.getInt(_keyTableNo);
    final tableSessionId = prefs.getString(_keyTableSessionId);
    final accessToken = await _secureStorage.read(key: _keyAccessToken);

    if (restaurantId == null || tableNo == null || tableSessionId == null || accessToken == null) {
      return null;
    }

    return CustomerSession(
      restaurantId: restaurantId,
      tableNo: tableNo,
      tableSessionId: tableSessionId,
      accessToken: accessToken,
      refreshToken: await _secureStorage.read(key: _keyRefreshToken),
    );
  }

  Future<String?> readAccessToken() => _secureStorage.read(key: _keyAccessToken);

  Future<void> saveAccessToken(String token) => _secureStorage.write(key: _keyAccessToken, value: token);

  Future<void> saveUserRole(String role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyUserRole, role);
  }

  Future<void> saveUserId(String userId) async {
    await _secureStorage.write(key: _keyUserId, value: userId);
  }

  Future<String?> readUserId() => _secureStorage.read(key: _keyUserId);

  Future<String?> readUserRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserRole);
  }

  Future<String?> readRefreshToken() => _secureStorage.read(key: _keyRefreshToken);

  Future<void> clearCustomerSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyRestaurantId);
    await prefs.remove(_keyTableNo);
    await prefs.remove(_keyTableSessionId);
    await prefs.remove(_keyUserRole);
    await _secureStorage.delete(key: _keyUserId);
    await _secureStorage.delete(key: _keyAccessToken);
    await _secureStorage.delete(key: _keyRefreshToken);
  }

  String _customerCardSecretKey(String cardId) => 'appsukran_customer_card_$cardId';

  Future<void> saveCustomerCardNumber(String cardId, String cardNumber) =>
      _secureStorage.write(key: _customerCardSecretKey(cardId), value: cardNumber);

  Future<String?> readCustomerCardNumber(String cardId) => _secureStorage.read(key: _customerCardSecretKey(cardId));

  Future<void> deleteCustomerCardNumber(String cardId) => _secureStorage.delete(key: _customerCardSecretKey(cardId));

  Future<void> saveRefreshToken(String? token) async {
    if (token == null || token.isEmpty) {
      await _secureStorage.delete(key: _keyRefreshToken);
      return;
    }
    await _secureStorage.write(key: _keyRefreshToken, value: token);
  }
}