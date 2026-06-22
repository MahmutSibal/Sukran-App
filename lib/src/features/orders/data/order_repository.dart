import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/demo/demo_mode.dart';
import '../../../core/demo/demo_seed.dart';
import '../../../core/models/backend_dtos.dart';
import '../../../core/network/backend_api_client.dart';
import '../../../core/realtime/order_hub_service.dart';
import '../../session/data/session_repository.dart';

final orderHubServiceProvider = Provider<OrderHubService>((ref) {
  return OrderHubService(sessionStore: ref.watch(appSessionStoreProvider));
});

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository(apiClient: ref.watch(backendApiClientProvider), hubService: ref.watch(orderHubServiceProvider));
});

class OrderRepository {
  OrderRepository({required BackendApiClient apiClient, required OrderHubService hubService})
      : _apiClient = apiClient,
        _hubService = hubService;

  final BackendApiClient _apiClient;
  final OrderHubService _hubService;

  Future<List<OrderResponse>> fetchOrdersByRestaurant(String restaurantId, {String? accessToken}) async {
    try {
      final response = await _apiClient.getJson('/api/orders/restaurant/$restaurantId', accessToken: accessToken);
      clearDemoFallback();
      return (response as List<dynamic>? ?? const []).whereType<Map<String, dynamic>>().map(OrderResponse.fromJson).toList(growable: false);
    } catch (_) {
      if (AppConfig.useMockFallback && restaurantId == DemoSeed.restaurantId) {
        markDemoFallback();
        return DemoSeed.orders;
      }
      rethrow;
    }
  }

  Future<OrderResponse?> fetchOrderById(String orderId, {String? accessToken}) async {
    try {
      final response = await _apiClient.getJson('/api/orders/$orderId', accessToken: accessToken);
      if (response is Map<String, dynamic>) {
        clearDemoFallback();
        return OrderResponse.fromJson(response);
      }
      return null;
    } catch (_) {
      if (AppConfig.useMockFallback) {
        markDemoFallback();
        for (final order in DemoSeed.orders) {
          if (order.id == orderId) {
            return order;
          }
        }
      }
      return null;
    }
  }

  /// Siparişleri canlı izler. SignalR bağlantısı kurulamazsa akış çökmez;
  /// bunun yerine periyodik polling devreye girer (gerçek zamanlı yoksa daha
  /// sık, varken yavaş bir yedek nabız). Her tetiklemede REST'ten yeniden çeker.
  Stream<List<OrderResponse>> watchOrdersByRestaurant(String restaurantId, {String? accessToken}) {
    final controller = StreamController<List<OrderResponse>>();
    StreamSubscription<void>? hubSub;
    Timer? pollTimer;
    var closed = false;
    var refreshing = false;

    Future<void> refresh() async {
      if (closed || refreshing) return;
      refreshing = true;
      try {
        final orders = await fetchOrdersByRestaurant(restaurantId, accessToken: accessToken);
        if (!closed) controller.add(orders);
      } catch (error, stack) {
        if (!closed) controller.addError(error, stack);
      } finally {
        refreshing = false;
      }
    }

    controller.onListen = () async {
      await refresh();
      // Bağlantı başarısız olsa bile (false döner) akış yaşamaya devam eder.
      final connected = await _hubService.connect(restaurantId, accessToken: accessToken);
      if (closed) return;
      hubSub = _hubService.watchRestaurant(restaurantId).listen((_) => refresh());
      pollTimer = Timer.periodic(
        connected ? const Duration(seconds: 30) : const Duration(seconds: 8),
        (_) => refresh(),
      );
    };

    controller.onCancel = () async {
      closed = true;
      await hubSub?.cancel();
      pollTimer?.cancel();
    };

    return controller.stream;
  }

  Future<void> updateOrderItemStatus({required String orderId, required String orderItemId, required OrderItemStatus status, String? accessToken}) async {
    await _apiClient.putJson('/api/orders/$orderId/items/$orderItemId/status', <String, dynamic>{'status': _statusToApiValue(status)}, accessToken: accessToken);
  }

  Future<void> updateOrderStatus({required String orderId, required OrderSessionStatus sessionStatus, String? accessToken}) async {
    await _apiClient.putJson('/api/orders/$orderId/status', <String, dynamic>{'sessionStatus': sessionStatus == OrderSessionStatus.active ? 1 : 2}, accessToken: accessToken);
  }

  int _statusToApiValue(OrderItemStatus status) {
    switch (status) {
      case OrderItemStatus.pending:
        return 1;
      case OrderItemStatus.kitchen:
        return 2;
      case OrderItemStatus.preparing:
        return 3;
      case OrderItemStatus.ready:
        return 4;
      case OrderItemStatus.delivered:
        return 5;
    }
  }
}