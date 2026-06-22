import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/demo/demo_seed.dart';
import '../../../core/models/backend_dtos.dart';
import '../../../core/network/backend_api_client.dart';
import '../../session/data/session_repository.dart';

final restaurantOwnerRepositoryProvider = Provider<RestaurantOwnerRepository>((ref) {
  return RestaurantOwnerRepository(apiClient: ref.watch(backendApiClientProvider));
});

class RestaurantOwnerRepository {
  RestaurantOwnerRepository({required BackendApiClient apiClient}) : _apiClient = apiClient;

  final BackendApiClient _apiClient;

  Future<RestaurantDetailResponse?> fetchRestaurantByQuery(String query, {String? accessToken}) async {
    final normalized = query.trim();
    if (normalized.isEmpty) return null;

    try {
      final slugResponse = await _apiClient.getJson('/api/restaurants/by-slug/${Uri.encodeComponent(normalized)}', accessToken: accessToken);
      return RestaurantDetailResponse.fromJson(slugResponse as Map<String, dynamic>);
    } catch (_) {
      try {
        final idResponse = await _apiClient.getJson('/api/restaurants/${Uri.encodeComponent(normalized)}', accessToken: accessToken);
        return RestaurantDetailResponse.fromJson(idResponse as Map<String, dynamic>);
      } catch (_) {
        if (AppConfig.useMockFallback) {
          if (normalized == DemoSeed.restaurantId || normalized == DemoSeed.restaurantDetail.slug) {
            return DemoSeed.restaurantDetail;
          }
        }
        rethrow;
      }
    }
  }

  Future<List<MenuItemResponse>> fetchMenuItems(String restaurantId, {String? accessToken}) async {
    try {
      final response = await _apiClient.getJson('/api/menuitems/restaurant/${Uri.encodeComponent(restaurantId)}', accessToken: accessToken);
      return (response as List<dynamic>? ?? const []).whereType<Map<String, dynamic>>().map(MenuItemResponse.fromJson).toList(growable: false);
    } catch (_) {
      if (AppConfig.useMockFallback && restaurantId == DemoSeed.restaurantId) {
        return DemoSeed.menuItems;
      }
      rethrow;
    }
  }

  Future<void> openTableSession({required String restaurantId, required int tableNo, String? accessToken}) async {
    await _apiClient.postJson('/api/restaurants/${Uri.encodeComponent(restaurantId)}/tables/$tableNo/session/open', const <String, dynamic>{}, accessToken: accessToken);
  }

  Future<void> closeTableSession({required String restaurantId, required int tableNo, String? accessToken}) async {
    await _apiClient.postJson('/api/restaurants/${Uri.encodeComponent(restaurantId)}/tables/$tableNo/session/close', const <String, dynamic>{}, accessToken: accessToken);
  }
}
