import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/models/backend_dtos.dart';
import '../../../core/network/backend_api_client.dart';
import '../../session/data/session_repository.dart';

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepository(apiClient: ref.watch(backendApiClientProvider));
});

/// Akıllı Ödeme akışının veri katmanı.
///
/// Backend `/api/payments/*` uçlarını saran tek sorumluluk noktası. Her metot
/// opsiyonel kart bilgisi alır (`customerCardId` verilirse `cardNumber`
/// zorunludur). Sunucu erişilemezse [AppConfig.useMockFallback] açıkken
/// demo bir [PaymentResultDto] üretir, böylece UI offline da denenebilir.
class PaymentRepository {
  PaymentRepository({required BackendApiClient apiClient}) : _apiClient = apiClient;

  final BackendApiClient _apiClient;

  /// "Kendi Aldıklarımı Öde" — seçili `orderItemId` listesi için tahsilat.
  Future<PaymentResultDto> paySpecificItems({
    required String billId,
    required List<String> itemIds,
    required String paidByUserId,
    required int amount,
    String? customerCardId,
    String? cardNumber,
    String? accessToken,
  }) {
    return _post(
      '/api/payments/specific-items',
      <String, dynamic>{
        'billId': billId,
        'itemIds': itemIds,
        'paidByUserId': paidByUserId,
        if (customerCardId != null) 'customerCardId': customerCardId,
        if (cardNumber != null) 'cardNumber': cardNumber,
      },
      billId: billId,
      fallbackPaid: amount,
      accessToken: accessToken,
    );
  }

  /// "Eşit Bölüş" — hesabı [personCount] kişiye böler, bir payı tahsil eder.
  Future<PaymentResultDto> paySplitEqually({
    required String billId,
    required int personCount,
    required String paidByUserId,
    required int shareAmount,
    String? customerCardId,
    String? cardNumber,
    String? accessToken,
  }) {
    return _post(
      '/api/payments/split-equally',
      <String, dynamic>{
        'billId': billId,
        'personCount': personCount,
        'paidByUserId': paidByUserId,
        if (customerCardId != null) 'customerCardId': customerCardId,
        if (cardNumber != null) 'cardNumber': cardNumber,
      },
      billId: billId,
      fallbackPaid: shareAmount,
      accessToken: accessToken,
    );
  }

  /// "Tutar Gir" — kullanıcının elle girdiği tutarı (kuruş) tahsil eder.
  Future<PaymentResultDto> payCustomAmount({
    required String billId,
    required int amount,
    required String paidByUserId,
    String? customerCardId,
    String? cardNumber,
    String? accessToken,
  }) {
    return _post(
      '/api/payments/custom-amount',
      <String, dynamic>{
        'billId': billId,
        'amount': amount,
        'paidByUserId': paidByUserId,
        if (customerCardId != null) 'customerCardId': customerCardId,
        if (cardNumber != null) 'cardNumber': cardNumber,
      },
      billId: billId,
      fallbackPaid: amount,
      accessToken: accessToken,
    );
  }

  Future<PaymentResultDto> _post(
    String path,
    Map<String, dynamic> body, {
    required String billId,
    required int fallbackPaid,
    String? accessToken,
  }) async {
    try {
      final response = await _apiClient.postJson(path, body, accessToken: accessToken);
      // Bazı uçlar yalnızca 200 OK döndürür (gövde olmadan); bu durumda
      // istemci tarafında başarı sonucu sentezlenir.
      if (response is Map<String, dynamic>) {
        return PaymentResultDto.fromJson(response);
      }
      return PaymentResultDto(billId: billId, paidAmount: fallbackPaid, remainingAmount: 0, status: 'paid');
    } catch (_) {
      if (!AppConfig.useMockFallback) {
        rethrow;
      }
      return PaymentResultDto(billId: billId, paidAmount: fallbackPaid, remainingAmount: 0, status: 'demo-paid');
    }
  }
}
