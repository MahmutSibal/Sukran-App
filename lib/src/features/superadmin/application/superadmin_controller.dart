import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/superadmin_repository.dart';
import '../domain/tenant.dart';

/// Kiracı listesini yükleyen ve mutasyonları (oluşturma / durum değiştirme)
/// yöneten denetleyici.
final tenantsControllerProvider =
    AsyncNotifierProvider<TenantsController, List<Tenant>>(TenantsController.new);

class TenantsController extends AsyncNotifier<List<Tenant>> {
  @override
  Future<List<Tenant>> build() async {
    return ref.read(superAdminRepositoryProvider).fetchTenants();
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(superAdminRepositoryProvider).fetchTenants());
  }

  Future<void> createTenant({
    required String name,
    required String ownerName,
    required String ownerEmail,
    required String city,
    required TenantPlan plan,
    required int tableCount,
  }) async {
    final created = await ref.read(superAdminRepositoryProvider).createTenant(
          name: name,
          ownerName: ownerName,
          ownerEmail: ownerEmail,
          city: city,
          plan: plan,
          tableCount: tableCount,
        );
    if (created == null) return;
    final current = state.valueOrNull ?? const <Tenant>[];
    state = AsyncData([created, ...current]);
  }

  Future<void> setStatus(String tenantId, TenantStatus status) async {
    final current = state.valueOrNull ?? const <Tenant>[];
    // İyimser güncelleme.
    state = AsyncData([
      for (final tenant in current)
        if (tenant.id == tenantId) tenant.copyWith(status: status) else tenant,
    ]);
    await ref.read(superAdminRepositoryProvider).setTenantStatus(tenantId: tenantId, status: status);
  }
}

/// Liste durumundan türeyen birleşik metrikler.
final adminMetricsProvider = Provider<AdminMetrics>((ref) {
  final tenants = ref.watch(tenantsControllerProvider).valueOrNull ?? const <Tenant>[];
  return AdminMetrics.fromTenants(tenants);
});

/// Kiracı arama/filtre metni.
final tenantSearchProvider = StateProvider<String>((ref) => '');

/// Duruma göre filtre (null = tümü).
final tenantStatusFilterProvider = StateProvider<TenantStatus?>((ref) => null);

/// Arama + filtre uygulanmış kiracı listesi.
final filteredTenantsProvider = Provider<List<Tenant>>((ref) {
  final tenants = ref.watch(tenantsControllerProvider).valueOrNull ?? const <Tenant>[];
  final query = ref.watch(tenantSearchProvider).toLowerCase().trim();
  final statusFilter = ref.watch(tenantStatusFilterProvider);

  return tenants.where((tenant) {
    final matchesQuery = query.isEmpty ||
        tenant.name.toLowerCase().contains(query) ||
        tenant.ownerEmail.toLowerCase().contains(query) ||
        tenant.city.toLowerCase().contains(query);
    final matchesStatus = statusFilter == null || tenant.status == statusFilter;
    return matchesQuery && matchesStatus;
  }).toList(growable: false);
});
