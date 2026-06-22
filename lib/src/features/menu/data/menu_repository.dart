import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/demo/demo_mode.dart';
import '../../../core/demo/demo_seed.dart';
import '../../../core/models/backend_dtos.dart';
import '../../../core/network/backend_api_client.dart';
import '../../session/domain/customer_session.dart';
import '../../session/data/session_repository.dart';

final menuRepositoryProvider = Provider<MenuRepository>((ref) {
  return MenuRepository(apiClient: ref.watch(backendApiClientProvider));
});

class MenuRepository {
  MenuRepository({required BackendApiClient apiClient}) : _apiClient = apiClient;

  final BackendApiClient _apiClient;

  Future<List<MenuItemResponse>> fetchMenuItems(String restaurantId) async {
    try {
      final response = await _apiClient.getJson('/api/menuitems/restaurant/$restaurantId');
      clearDemoFallback();
      return (response as List<dynamic>? ?? const []).whereType<Map<String, dynamic>>().map(MenuItemResponse.fromJson).toList(growable: false);
    } catch (_) {
      if (AppConfig.useMockFallback && restaurantId == DemoSeed.restaurantId) {
        markDemoFallback();
        return DemoSeed.menuItems;
      }
      rethrow;
    }
  }

  Future<OrderResponse> createOrder({required CustomerSession session, required List<MenuItemResponse> selectedItems}) async {
    final payload = <String, dynamic>{
      'restaurantId': session.restaurantId,
      'tableNo': session.tableNo,
      'tableSessionId': session.tableSessionId,
      'qrToken': session.accessToken,
      'items': selectedItems.map((item) => <String, dynamic>{'menuItemId': item.id, 'name': item.name, 'price': item.price, 'orderedBy': 'Masa ${session.tableNo}', 'status': 1, 'paymentStatus': 1}).toList(growable: false),
    };

    try {
      final response = await _apiClient.postJson('/api/orders', payload, accessToken: session.accessToken);
      clearDemoFallback();
      final orderId = response?.toString() ?? 'order-generated';
      return OrderResponse(
        id: orderId,
        restaurantId: session.restaurantId,
        tableNo: session.tableNo,
        sessionStatus: OrderSessionStatus.active,
        items: selectedItems
            .map((item) => OrderItemResponse(orderItemId: 'item-${item.id}', menuItemId: item.id, name: item.name, price: item.price, orderedBy: 'Masa ${session.tableNo}', status: OrderItemStatus.pending, paymentStatus: PaymentStatus.unpaid))
            .toList(growable: false),
        totalAmount: selectedItems.fold<int>(0, (sum, item) => sum + item.price),
        remainingAmount: selectedItems.fold<int>(0, (sum, item) => sum + item.price),
      );
    } catch (_) {
      if (!AppConfig.useMockFallback) {
        rethrow;
      }
      markDemoFallback();
      final total = selectedItems.fold<int>(0, (sum, item) => sum + item.price);
      return OrderResponse(
        id: 'demo-order-${DateTime.now().millisecondsSinceEpoch}',
        restaurantId: session.restaurantId,
        tableNo: session.tableNo,
        sessionStatus: OrderSessionStatus.active,
        items: selectedItems
            .map((item) => OrderItemResponse(orderItemId: 'demo-${item.id}', menuItemId: item.id, name: item.name, price: item.price, orderedBy: 'Masa ${session.tableNo}', status: OrderItemStatus.pending, paymentStatus: PaymentStatus.unpaid))
            .toList(growable: false),
        totalAmount: total,
        remainingAmount: total,
      );
    }
  }
}