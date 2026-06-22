/// Çok kiracılı (multi-tenant) sistemde bir kiracı = bir restoran/işletme.
enum TenantStatus { active, pending, suspended }

enum TenantPlan { free, pro, enterprise }

extension TenantStatusX on TenantStatus {
  String get label => switch (this) {
        TenantStatus.active => 'Aktif',
        TenantStatus.pending => 'Onay Bekliyor',
        TenantStatus.suspended => 'Askıda',
      };
}

extension TenantPlanX on TenantPlan {
  String get label => switch (this) {
        TenantPlan.free => 'Başlangıç',
        TenantPlan.pro => 'Pro',
        TenantPlan.enterprise => 'Kurumsal',
      };

  int get apiValue => switch (this) {
        TenantPlan.free => 0,
        TenantPlan.pro => 1,
        TenantPlan.enterprise => 2,
      };
}

TenantStatus parseTenantStatus(dynamic value) {
  if (value is int) {
    return switch (value) {
      1 => TenantStatus.active,
      2 => TenantStatus.suspended,
      _ => TenantStatus.pending,
    };
  }
  return switch (value?.toString().toLowerCase().trim()) {
    'active' => TenantStatus.active,
    'suspended' => TenantStatus.suspended,
    _ => TenantStatus.pending,
  };
}

TenantPlan parseTenantPlan(dynamic value) {
  if (value is int) {
    return switch (value) {
      1 => TenantPlan.pro,
      2 => TenantPlan.enterprise,
      _ => TenantPlan.free,
    };
  }
  return switch (value?.toString().toLowerCase().trim()) {
    'pro' => TenantPlan.pro,
    'enterprise' => TenantPlan.enterprise,
    _ => TenantPlan.free,
  };
}

class Tenant {
  const Tenant({
    required this.id,
    required this.name,
    required this.slug,
    required this.ownerName,
    required this.ownerEmail,
    required this.city,
    required this.plan,
    required this.status,
    required this.tableCount,
    required this.monthlyOrders,
    required this.monthlyRevenue,
    required this.createdAt,
  });

  factory Tenant.fromJson(Map<String, dynamic> json) {
    return Tenant(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      ownerName: json['ownerName']?.toString() ?? '',
      ownerEmail: json['ownerEmail']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      plan: parseTenantPlan(json['plan']),
      status: parseTenantStatus(json['status']),
      tableCount: (json['tableCount'] as num?)?.toInt() ?? 0,
      monthlyOrders: (json['monthlyOrders'] as num?)?.toInt() ?? 0,
      monthlyRevenue: (json['monthlyRevenue'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  final String id;
  final String name;
  final String slug;
  final String ownerName;
  final String ownerEmail;
  final String city;
  final TenantPlan plan;
  final TenantStatus status;
  final int tableCount;
  final int monthlyOrders;

  /// Aylık ciro — kuruş cinsinden (long).
  final int monthlyRevenue;
  final DateTime createdAt;

  Tenant copyWith({TenantStatus? status, TenantPlan? plan}) {
    return Tenant(
      id: id,
      name: name,
      slug: slug,
      ownerName: ownerName,
      ownerEmail: ownerEmail,
      city: city,
      plan: plan ?? this.plan,
      status: status ?? this.status,
      tableCount: tableCount,
      monthlyOrders: monthlyOrders,
      monthlyRevenue: monthlyRevenue,
      createdAt: createdAt,
    );
  }
}

/// Panodaki birleşik metrikler.
class AdminMetrics {
  const AdminMetrics({
    required this.totalTenants,
    required this.activeTenants,
    required this.pendingTenants,
    required this.suspendedTenants,
    required this.totalMonthlyOrders,
    required this.totalMonthlyRevenue,
  });

  factory AdminMetrics.fromTenants(List<Tenant> tenants) {
    return AdminMetrics(
      totalTenants: tenants.length,
      activeTenants: tenants.where((t) => t.status == TenantStatus.active).length,
      pendingTenants: tenants.where((t) => t.status == TenantStatus.pending).length,
      suspendedTenants: tenants.where((t) => t.status == TenantStatus.suspended).length,
      totalMonthlyOrders: tenants.fold(0, (sum, t) => sum + t.monthlyOrders),
      totalMonthlyRevenue: tenants.fold(0, (sum, t) => sum + t.monthlyRevenue),
    );
  }

  final int totalTenants;
  final int activeTenants;
  final int pendingTenants;
  final int suspendedTenants;
  final int totalMonthlyOrders;
  final int totalMonthlyRevenue;
}
