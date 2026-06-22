import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/backend_api_client.dart';
import '../../session/data/session_repository.dart';
import '../domain/tenant.dart';

final superAdminRepositoryProvider = Provider<SuperAdminRepository>((ref) {
  return SuperAdminRepository(apiClient: ref.watch(backendApiClientProvider));
});

/// Süper admin için kiracı (tenant) yönetimi. Gerçek uç noktaları dener,
/// erişilemezse (mock fallback açıkken) yerel demo verisiyle çalışır.
class SuperAdminRepository {
  SuperAdminRepository({required BackendApiClient apiClient}) : _apiClient = apiClient;

  final BackendApiClient _apiClient;

  Future<List<Tenant>> fetchTenants() async {
    try {
      final response = await _apiClient.getJson('/api/admin/tenants');
      final list = (response as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(Tenant.fromJson)
          .toList(growable: false);
      if (list.isNotEmpty) return list;
      if (AppConfig.useMockFallback) return _demoTenants();
      return list;
    } catch (_) {
      if (AppConfig.useMockFallback) return _demoTenants();
      rethrow;
    }
  }

  Future<Tenant?> createTenant({
    required String name,
    required String ownerName,
    required String ownerEmail,
    required String city,
    required TenantPlan plan,
    required int tableCount,
  }) async {
    final body = <String, dynamic>{
      'name': name,
      'ownerName': ownerName,
      'ownerEmail': ownerEmail,
      'city': city,
      'plan': plan.apiValue,
      'tableCount': tableCount,
    };
    try {
      final response = await _apiClient.postJson('/api/admin/tenants', body);
      if (response is Map<String, dynamic>) return Tenant.fromJson(response);
    } catch (_) {
      if (!AppConfig.useMockFallback) rethrow;
    }

    // Yerel (mock) oluşturma — onay bekleyen yeni kiracı.
    return Tenant(
      id: 'tenant-${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      slug: _slugify(name),
      ownerName: ownerName,
      ownerEmail: ownerEmail,
      city: city,
      plan: plan,
      status: TenantStatus.pending,
      tableCount: tableCount,
      monthlyOrders: 0,
      monthlyRevenue: 0,
      createdAt: DateTime.now(),
    );
  }

  Future<void> setTenantStatus({required String tenantId, required TenantStatus status}) async {
    try {
      await _apiClient.putJson('/api/admin/tenants/$tenantId/status', {'status': status.name});
    } catch (_) {
      if (!AppConfig.useMockFallback) rethrow;
      // Mock modda sessizce geç — state katmanı yereldeki değişimi yansıtır.
    }
  }

  String _slugify(String input) {
    final lower = input.toLowerCase().trim();
    final buffer = StringBuffer();
    for (final ch in lower.split('')) {
      if (RegExp(r'[a-z0-9]').hasMatch(ch)) {
        buffer.write(ch);
      } else if (ch == ' ') {
        buffer.write('-');
      }
    }
    final slug = buffer.toString();
    return slug.isEmpty ? 'tenant' : slug;
  }

  List<Tenant> _demoTenants() {
    DateTime daysAgo(int d) => DateTime.now().subtract(Duration(days: d));
    return [
      Tenant(
        id: 'restaurant-demo-001',
        name: 'Sukran Kadıköy',
        slug: 'sukran-kadikoy',
        ownerName: 'Mert Yılmaz',
        ownerEmail: 'kadikoy@appsukran.local',
        city: 'İstanbul',
        plan: TenantPlan.enterprise,
        status: TenantStatus.active,
        tableCount: 24,
        monthlyOrders: 1840,
        monthlyRevenue: 48650000,
        createdAt: daysAgo(420),
      ),
      Tenant(
        id: 'restaurant-demo-002',
        name: 'Sukran Moda Sahil',
        slug: 'sukran-moda-sahil',
        ownerName: 'Elif Demir',
        ownerEmail: 'moda@appsukran.local',
        city: 'İstanbul',
        plan: TenantPlan.pro,
        status: TenantStatus.active,
        tableCount: 16,
        monthlyOrders: 1120,
        monthlyRevenue: 27340000,
        createdAt: daysAgo(260),
      ),
      Tenant(
        id: 'restaurant-demo-003',
        name: 'Sukran Bahariye Kafe',
        slug: 'sukran-bahariye',
        ownerName: 'Can Aksoy',
        ownerEmail: 'bahariye@appsukran.local',
        city: 'İstanbul',
        plan: TenantPlan.pro,
        status: TenantStatus.pending,
        tableCount: 12,
        monthlyOrders: 0,
        monthlyRevenue: 0,
        createdAt: daysAgo(6),
      ),
      Tenant(
        id: 'restaurant-demo-004',
        name: 'Sukran Yeldeğirmeni',
        slug: 'sukran-yeldegirmeni',
        ownerName: 'Zeynep Kaya',
        ownerEmail: 'yeldegirmeni@appsukran.local',
        city: 'İstanbul',
        plan: TenantPlan.free,
        status: TenantStatus.active,
        tableCount: 8,
        monthlyOrders: 420,
        monthlyRevenue: 8730000,
        createdAt: daysAgo(95),
      ),
      Tenant(
        id: 'restaurant-demo-005',
        name: 'Sukran Fenerbahçe',
        slug: 'sukran-fenerbahce',
        ownerName: 'Burak Şahin',
        ownerEmail: 'fenerbahce@appsukran.local',
        city: 'İstanbul',
        plan: TenantPlan.enterprise,
        status: TenantStatus.suspended,
        tableCount: 30,
        monthlyOrders: 60,
        monthlyRevenue: 1450000,
        createdAt: daysAgo(540),
      ),
      Tenant(
        id: 'restaurant-demo-006',
        name: 'Sukran Ankara Tunalı',
        slug: 'sukran-tunali',
        ownerName: 'Derya Öz',
        ownerEmail: 'tunali@appsukran.local',
        city: 'Ankara',
        plan: TenantPlan.pro,
        status: TenantStatus.active,
        tableCount: 18,
        monthlyOrders: 980,
        monthlyRevenue: 21900000,
        createdAt: daysAgo(150),
      ),
    ];
  }
}
