import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/backend_dtos.dart';
import '../../../core/network/backend_api_client.dart';
import '../../../core/storage/app_session_store.dart';
import '../../session/data/session_repository.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(
    apiClient: ref.watch(backendApiClientProvider),
    sessionStore: ref.watch(appSessionStoreProvider),
  );
});

/// Oturum açan kullanıcının profilini getirir. QR-only oturumlarda backend
/// kullanıcı bulamaz ve hata döner; bu durumda null döndürürüz.
final myProfileProvider = FutureProvider<UserProfileResponse?>((ref) async {
  return ref.watch(profileRepositoryProvider).fetchMe();
});

class ProfileRepository {
  ProfileRepository({required BackendApiClient apiClient, required AppSessionStore sessionStore})
      : _apiClient = apiClient,
        _sessionStore = sessionStore;

  final BackendApiClient _apiClient;
  final AppSessionStore _sessionStore;

  Future<String?> _token() => _sessionStore.readAccessToken();

  Future<UserProfileResponse?> fetchMe() async {
    try {
      final response = await _apiClient.getJson('/api/profile/me', accessToken: await _token());
      if (response is Map<String, dynamic>) {
        return UserProfileResponse.fromJson(response);
      }
      return null;
    } catch (_) {
      // QR oturumu / kayıtsız kimlik / çevrimdışı: profil yok kabul et.
      return null;
    }
  }

  Future<UserProfileResponse> updateName(String name) async {
    final response = await _apiClient.putJson(
      '/api/profile/me',
      <String, dynamic>{'name': name},
      accessToken: await _token(),
    );
    return UserProfileResponse.fromJson(response as Map<String, dynamic>);
  }
}
