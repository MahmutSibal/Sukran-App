// Feature removed.
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/demo/demo_seed.dart';
import '../../../core/models/backend_dtos.dart';
import '../../../core/network/backend_api_client.dart';
import '../../orders/data/order_repository.dart';
import '../../session/data/session_repository.dart';

final waiterRepositoryProvider = Provider<WaiterRepository>((ref) {
  return WaiterRepository(apiClient: ref.watch(backendApiClientProvider), orderRepository: ref.watch(orderRepositoryProvider));
});

class WaiterRepository {
  WaiterRepository({required BackendApiClient apiClient, required OrderRepository orderRepository})
      : _apiClient = apiClient,
        _orderRepository = orderRepository;

  final BackendApiClient _apiClient;
  final OrderRepository _orderRepository;

  Future<List<OrderResponse>> fetchPendingOrders(String restaurantId, {String? accessToken}) async {
    return _orderRepository.fetchOrdersByRestaurant(restaurantId, accessToken: accessToken);
  }

  Future<List<BillResponse>> fetchBillsByRestaurant(String restaurantId, {String? accessToken}) async {
    try {
      final response = await _apiClient.getJson('/api/bills/restaurant/$restaurantId', accessToken: accessToken);
      return (response as List<dynamic>? ?? const []).whereType<Map<String, dynamic>>().map(BillResponse.fromJson).toList(growable: false);
    } catch (_) {
      if (AppConfig.useMockFallback && restaurantId == DemoSeed.restaurantId) {
        return DemoSeed.bills;
      }
      rethrow;
    }
  }

  Future<List<WaiterTableSummary>> fetchTableSummaries(String restaurantId, {String? accessToken}) async {
    final orders = await fetchPendingOrders(restaurantId, accessToken: accessToken);
    final bills = await fetchBillsByRestaurant(restaurantId, accessToken: accessToken);

    final tableNos = <int>{...orders.map((order) => order.tableNo), ...bills.map((bill) => bill.tableNo), 1, 2, 3, 4, 5, 6, 7, 8, 9}.toList()..sort();

    return tableNos.map((tableNo) {
      final order = orders.where((item) => item.tableNo == tableNo).firstOrNull;
      final bill = bills.where((item) => item.tableNo == tableNo).firstOrNull;
      final hasAttention = bill != null && bill.remainingAmount > 0 && bill.items.any((item) => item.paymentStatus == PaymentStatus.unpaid);

      return WaiterTableSummary(
        tableNo: tableNo,
        hasActiveOrder: order != null,
        hasPaymentAttention: hasAttention,
        totalAmount: bill?.totalAmount ?? order?.totalAmount ?? 0,
        remainingAmount: bill?.remainingAmount ?? order?.remainingAmount ?? 0,
      );
    }).toList(growable: false);
  }

  Future<PaymentResultDto> paySpecificItems({required String billId, required List<String> itemIds, required String paidByUserId, String? accessToken}) async {
    try {
      final response = await _apiClient.postJson('/api/payments/specific-items', <String, dynamic>{'billId': billId, 'itemIds': itemIds, 'paidByUserId': paidByUserId}, accessToken: accessToken);
      return PaymentResultDto.fromJson(response as Map<String, dynamic>);
    } catch (_) {
      if (!AppConfig.useMockFallback) {
        rethrow;
      }
      final paidAmount = itemIds.length * 1000;
      return PaymentResultDto(billId: billId, paidAmount: paidAmount, remainingAmount: 0, status: 'Paid');
    }
  }

  Future<void> markDelivered({required String orderId, required String orderItemId, String? accessToken}) {
    return _orderRepository.updateOrderItemStatus(orderId: orderId, orderItemId: orderItemId, status: OrderItemStatus.delivered, accessToken: accessToken);
  }
}

class WaiterTableSummary {
  WaiterTableSummary({required this.tableNo, required this.hasActiveOrder, required this.hasPaymentAttention, required this.totalAmount, required this.remainingAmount});

  final int tableNo;
  final bool hasActiveOrder;
  final bool hasPaymentAttention;
  final int totalAmount;
  final int remainingAmount;
}