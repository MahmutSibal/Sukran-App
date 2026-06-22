import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/models/backend_dtos.dart';
import '../../../core/network/backend_api_client.dart';
import '../../../core/storage/app_session_store.dart';
import '../../session/data/session_repository.dart';

/// Kart numarasının Luhn algoritmasıyla geçerliliğini kontrol eder (istemci ön doğrulaması).
bool isCardNumberValid(String input) {
  final digits = input.replaceAll(RegExp(r'\D'), '');
  if (digits.length < 13 || digits.length > 19) return false;
  var sum = 0;
  var doubleDigit = false;
  for (var i = digits.length - 1; i >= 0; i--) {
    var d = digits.codeUnitAt(i) - 48;
    if (d < 0 || d > 9) return false;
    if (doubleDigit) {
      d *= 2;
      if (d > 9) d -= 9;
    }
    sum += d;
    doubleDigit = !doubleDigit;
  }
  return sum % 10 == 0;
}

/// Kart son kullanma tarihinin gelecekte (veya bu ay) olup olmadığını kontrol eder.
bool isCardExpiryValid(int month, int year) {
  if (month < 1 || month > 12) return false;
  if (year < 2000 || year > 2100) return false;
  final now = DateTime.now();
  final lastDay = DateTime(year, month + 1, 0);
  return !lastDay.isBefore(DateTime(now.year, now.month, now.day));
}

/// Kart numarasının ön ekine göre markasını döndürür (UI ipucu için).
String detectCardBrand(String input) {
  final n = input.replaceAll(RegExp(r'\D'), '');
  if (n.isEmpty) return 'Kart';
  if (n.startsWith('4')) return 'Visa';
  if (n.startsWith('34') || n.startsWith('37')) return 'American Express';
  if (RegExp(r'^5[1-5]').hasMatch(n)) return 'Mastercard';
  if (n.startsWith('6011') || n.startsWith('65')) return 'Discover';
  if (n.startsWith('9792')) return 'Troy';
  return 'Kart';
}

final customerCardRepositoryProvider = Provider<CustomerCardRepository>((ref) {
  return CustomerCardRepository(apiClient: ref.watch(backendApiClientProvider), sessionStore: ref.watch(appSessionStoreProvider));
});

class CustomerCardRepository {
  CustomerCardRepository({required BackendApiClient apiClient, required AppSessionStore sessionStore})
      : _apiClient = apiClient,
        _sessionStore = sessionStore;

  final BackendApiClient _apiClient;
  final AppSessionStore _sessionStore;

  Future<List<CustomerCardResponse>> fetchMyCards({String? accessToken}) async {
    try {
      final response = await _apiClient.getJson('/api/customercards/me', accessToken: accessToken);
      return (response as List<dynamic>? ?? const []).whereType<Map<String, dynamic>>().map(CustomerCardResponse.fromJson).toList(growable: false);
    } catch (_) {
      if (AppConfig.useMockFallback) {
        return const [];
      }
      rethrow;
    }
  }

  Future<CustomerCardResponse> createCard({
    required String cardholderName,
    required String cardNumber,
    required int expiryMonth,
    required int expiryYear,
    required String cvv,
    required bool isDefault,
    String? accessToken,
  }) async {
    final payload = <String, dynamic>{
      'cardholderName': cardholderName,
      'cardNumber': cardNumber,
      'expiryMonth': expiryMonth,
      'expiryYear': expiryYear,
      'cvv': cvv,
      'isDefault': isDefault,
    };

    try {
      final response = await _apiClient.postJson('/api/customercards', payload, accessToken: accessToken);
      final card = CustomerCardResponse.fromJson(response as Map<String, dynamic>);
      await _sessionStore.saveCustomerCardNumber(card.id, cardNumber);
      return card;
    } on ApiException {
      // Sunucuya ulaşıldı ama isteği reddetti (ör. geçersiz kart, mükerrer kart).
      // Demo karta DÜŞME — gerçek hatayı yukarı taşı ki kullanıcı düzeltsin.
      rethrow;
    } catch (_) {
      // Yalnızca ağ/bağlantı hatasında demo karta düş.
      if (!AppConfig.useMockFallback) {
        rethrow;
      }
      final normalized = cardNumber.replaceAll(RegExp(r'\D'), '');
      final last4 = normalized.length <= 4 ? normalized : normalized.substring(normalized.length - 4);
      final card = CustomerCardResponse(
        id: 'card-demo-${DateTime.now().millisecondsSinceEpoch}',
        cardholderName: cardholderName,
        brand: detectCardBrand(normalized),
        last4: last4,
        expiryMonth: expiryMonth,
        expiryYear: expiryYear,
        isDefault: isDefault,
        isActive: true,
        createdAt: DateTime.now(),
      );
      await _sessionStore.saveCustomerCardNumber(card.id, cardNumber);
      return card;
    }
  }

  Future<CustomerCardVerificationResponse> verifyCard({required String cardId, required String cardNumber, String? accessToken}) async {
    try {
      final response = await _apiClient.postJson('/api/customercards/verify', <String, dynamic>{'customerCardId': cardId, 'cardNumber': cardNumber}, accessToken: accessToken);
      return CustomerCardVerificationResponse.fromJson(response as Map<String, dynamic>);
    } on ApiException {
      // Sunucu doğrulamayı reddetti — gerçek sonucu yukarı taşı.
      rethrow;
    } catch (_) {
      if (!AppConfig.useMockFallback) {
        rethrow;
      }
      final normalized = cardNumber.replaceAll(RegExp(r'\D'), '');
      final last4 = normalized.length <= 4 ? normalized : normalized.substring(normalized.length - 4);
      return CustomerCardVerificationResponse(isValid: true, brand: detectCardBrand(normalized), last4: last4, message: 'Demo doğrulama başarılı.');
    }
  }

  Future<void> deleteCard({required String cardId, String? accessToken}) async {
    try {
      await _apiClient.deleteJson('/api/customercards/$cardId', accessToken: accessToken);
      await _sessionStore.deleteCustomerCardNumber(cardId);
    } catch (_) {
      if (!AppConfig.useMockFallback) {
        rethrow;
      }
    }
  }

  Future<String?> readStoredCardNumber(String cardId) => _sessionStore.readCustomerCardNumber(cardId);

  Future<PaymentResultDto> payRemainingAmountWithCard({
    required String billId,
    required int amount,
    required String paidByUserId,
    required String cardId,
    required String cardNumber,
    String? accessToken,
  }) async {
    final response = await _apiClient.postJson(
      '/api/payments/custom-amount',
      <String, dynamic>{
        'billId': billId,
        'amount': amount,
        'paidByUserId': paidByUserId,
        'customerCardId': cardId,
        'cardNumber': cardNumber,
      },
      accessToken: accessToken,
    );
    return PaymentResultDto.fromJson(response as Map<String, dynamic>);
  }
}
