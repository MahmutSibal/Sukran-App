import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/demo/demo_mode.dart';
import '../../../core/demo/demo_seed.dart';
import '../../../core/models/backend_dtos.dart';
import '../../../core/network/backend_api_client.dart';
import '../../../core/storage/app_session_store.dart';
import '../domain/customer_session.dart';

final appSessionStoreProvider = Provider<AppSessionStore>((ref) => AppSessionStore());

final backendApiClientProvider = Provider<BackendApiClient>((ref) {
  final store = ref.watch(appSessionStoreProvider);
  return BackendApiClient(
    sessionStore: store,
    // Refresh token da öldüğünde oturumu temizle; QR ekranına dönülür.
    onSessionExpired: () => store.clearCustomerSession(),
  );
});

final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  return SessionRepository(apiClient: ref.watch(backendApiClientProvider), sessionStore: ref.watch(appSessionStoreProvider));
});

class SessionRepository {
  SessionRepository({required BackendApiClient apiClient, required AppSessionStore sessionStore})
      : _apiClient = apiClient,
        _sessionStore = sessionStore;

  final BackendApiClient _apiClient;
  final AppSessionStore _sessionStore;

  Future<List<NearbyRestaurantDto>> fetchNearbyRestaurants({required double longitude, required double latitude}) async {
    try {
      final response = await _apiClient.getJson('/api/restaurants/nearby', queryParameters: {'longitude': longitude, 'latitude': latitude, 'maxDistanceMeters': 5000});
      clearDemoFallback();
      return (response as List<dynamic>? ?? const []).whereType<Map<String, dynamic>>().map(NearbyRestaurantDto.fromJson).toList(growable: false);
    } catch (_) {
      if (AppConfig.useMockFallback) {
        markDemoFallback();
        return DemoSeed.restaurants;
      }
      rethrow;
    }
  }

  Future<RestaurantDetailResponse?> fetchRestaurantById(String restaurantId) async {
    try {
      final response = await _apiClient.getJson('/api/restaurants/$restaurantId');
      if (response is Map<String, dynamic>) {
        clearDemoFallback();
        return RestaurantDetailResponse.fromJson(response);
      }
      return null;
    } catch (_) {
      if (AppConfig.useMockFallback && restaurantId == DemoSeed.restaurantId) {
        markDemoFallback();
        return DemoSeed.restaurantDetail;
      }
      return null;
    }
  }

  Future<CustomerSession?> loadSavedSession() => _sessionStore.readCustomerSession();

  Future<CustomerSession> createQrSession({required String restaurantId, required int tableNo, required String qrToken}) async {
    try {
      final response = await _apiClient.postJson('/api/auth/qr-session', <String, dynamic>{'restaurantId': restaurantId, 'tableNo': tableNo, 'qrToken': qrToken});
      final session = QrSessionResponse.fromJson(response as Map<String, dynamic>);
      final customerSession = CustomerSession(restaurantId: session.restaurantId, tableNo: session.tableNo, tableSessionId: session.tableSessionId, accessToken: session.accessToken);
      await _sessionStore.saveCustomerSession(customerSession);
      clearDemoFallback();
      return customerSession;
    } catch (_) {
      if (!AppConfig.useMockFallback) {
        rethrow;
      }
      markDemoFallback();
      final customerSession = CustomerSession(restaurantId: restaurantId, tableNo: tableNo, tableSessionId: AppConfig.defaultTableSessionId, accessToken: 'demo-access-token');
      await _sessionStore.saveCustomerSession(customerSession);
      return customerSession;
    }
  }

  Future<void> saveAccessToken(String token) => _sessionStore.saveAccessToken(token);

  Future<void> clearSession() => _sessionStore.clearCustomerSession();
}