import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/demo/demo_mode.dart';
import '../../../core/models/backend_dtos.dart';
import '../../../core/network/backend_api_client.dart';
import '../../../core/storage/app_session_store.dart';
import '../../session/data/session_repository.dart';

final reviewRepositoryProvider = Provider<ReviewRepository>((ref) {
  return ReviewRepository(
    apiClient: ref.watch(backendApiClientProvider),
    sessionStore: ref.watch(appSessionStoreProvider),
  );
});

/// Bir restoranın yorumlarını canlı tutan provider (restaurantId ile parametrelenir).
final restaurantReviewsProvider = FutureProvider.family<List<ReviewResponse>, String>((ref, restaurantId) async {
  return ref.watch(reviewRepositoryProvider).fetchByRestaurant(restaurantId);
});

/// Oturum açan kullanıcının kendi yorumları (profil ekranı için).
final myReviewsProvider = FutureProvider<List<ReviewResponse>>((ref) async {
  return ref.watch(reviewRepositoryProvider).fetchMine();
});

class ReviewRepository {
  ReviewRepository({required BackendApiClient apiClient, required AppSessionStore sessionStore})
      : _apiClient = apiClient,
        _sessionStore = sessionStore;

  final BackendApiClient _apiClient;
  final AppSessionStore _sessionStore;

  Future<String?> _token() async {
    final session = await _sessionStore.readCustomerSession();
    return session?.accessToken ?? await _sessionStore.readAccessToken();
  }

  Future<List<ReviewResponse>> fetchByRestaurant(String restaurantId) async {
    try {
      final response = await _apiClient.getJson('/api/reviews/restaurant/$restaurantId', accessToken: await _token());
      clearDemoFallback();
      return (response as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(ReviewResponse.fromJson)
          .toList(growable: false);
    } catch (_) {
      if (AppConfig.useMockFallback) {
        markDemoFallback();
        return const [];
      }
      rethrow;
    }
  }

  Future<List<ReviewResponse>> fetchMine() async {
    try {
      final response = await _apiClient.getJson('/api/reviews/me', accessToken: await _token());
      clearDemoFallback();
      return (response as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(ReviewResponse.fromJson)
          .toList(growable: false);
    } catch (_) {
      if (AppConfig.useMockFallback) {
        markDemoFallback();
        return const [];
      }
      rethrow;
    }
  }

  Future<ReviewResponse> createReview({
    required String restaurantId,
    required String comment,
    required int rating,
  }) async {
    final response = await _apiClient.postJson(
      '/api/reviews',
      <String, dynamic>{'restaurantId': restaurantId, 'comment': comment, 'rating': rating},
      accessToken: await _token(),
    );
    return ReviewResponse.fromJson(response as Map<String, dynamic>);
  }

  /// Yoruma beğeni/beğenmeme verir. Aynı tepki tekrar gönderilirse backend geri alır.
  Future<ReviewResponse> react({required String reviewId, required bool isLike}) async {
    final response = await _apiClient.postJson(
      '/api/reviews/$reviewId/react',
      <String, dynamic>{'isLike': isLike},
      accessToken: await _token(),
    );
    return ReviewResponse.fromJson(response as Map<String, dynamic>);
  }

  Future<void> deleteReview(String reviewId) async {
    await _apiClient.deleteJson('/api/reviews/$reviewId', accessToken: await _token());
  }

  /// Bir yoruma yanıt ekler; [mentionedUserName] verilirse o kişi @ ile etiketlenir.
  Future<ReviewResponse> addReply({
    required String reviewId,
    required String comment,
    String? mentionedUserName,
  }) async {
    final response = await _apiClient.postJson(
      '/api/reviews/$reviewId/replies',
      <String, dynamic>{'comment': comment, 'mentionedUserName': mentionedUserName},
      accessToken: await _token(),
    );
    return ReviewResponse.fromJson(response as Map<String, dynamic>);
  }

  Future<void> deleteReply({required String reviewId, required String replyId}) async {
    await _apiClient.deleteJson('/api/reviews/$reviewId/replies/$replyId', accessToken: await _token());
  }
}
