import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_dark.dart';
import '../application/superadmin_controller.dart';
import '../domain/tenant.dart';
import 'admin_widgets.dart';

class AdminDashboardView extends ConsumerWidget {
  const AdminDashboardView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tenantsAsync = ref.watch(tenantsControllerProvider);
    final metrics = ref.watch(adminMetricsProvider);

    return tenantsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Text('Veriler yüklenemedi: $error', style: const TextStyle(color: AppDark.textSecondary)),
      ),
      data: (tenants) {
        final pending = tenants.where((t) => t.status == TenantStatus.pending).toList(growable: false);
        final topByRevenue = [...tenants]..sort((a, b) => b.monthlyRevenue.compareTo(a.monthlyRevenue));

        return ListView(
          padding: const EdgeInsets.all(28),
          children: [
            Text(
              'Genel Bakış',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: AppDark.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tüm kiracıların özet performansı',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppDark.textSecondary),
            ),
            const SizedBox(height: 24),
            ResponsiveGrid(
              minItemWidth: 230,
              children: [
                MetricCard(
                  icon: Icons.storefront_rounded,
                  label: 'Toplam Kiracı',
                  value: '${metrics.totalTenants}',
                  trailing: '${metrics.activeTenants} aktif',
                ),
                MetricCard(
                  icon: Icons.check_circle_rounded,
                  label: 'Aktif İşletme',
                  value: '${metrics.activeTenants}',
                  accent: AppDark.success,
                ),
                MetricCard(
                  icon: Icons.hourglass_bottom_rounded,
                  label: 'Onay Bekleyen',
                  value: '${metrics.pendingTenants}',
                  accent: AppDark.accentBright,
                ),
                MetricCard(
                  icon: Icons.receipt_long_rounded,
                  label: 'Aylık Sipariş',
                  value: '${metrics.totalMonthlyOrders}',
                ),
                MetricCard(
                  icon: Icons.payments_rounded,
                  label: 'Aylık Ciro (toplam)',
                  value: adminFormatTry(metrics.totalMonthlyRevenue),
                  accent: AppDark.success,
                ),
                MetricCard(
                  icon: Icons.block_rounded,
                  label: 'Askıda',
                  value: '${metrics.suspendedTenants}',
                  accent: AppDark.danger,
                ),
              ],
            ),
            const SizedBox(height: 28),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 820;
                final pendingCard = _PendingApprovalsCard(pending: pending);
                final topCard = _TopTenantsCard(tenants: topByRevenue.take(5).toList(growable: false));
                if (wide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: pendingCard),
                      const SizedBox(width: 20),
                      Expanded(child: topCard),
                    ],
                  );
                }
                return Column(children: [pendingCard, const SizedBox(height: 20), topCard]);
              },
            ),
          ],
        );
      },
    );
  }
}

class _PendingApprovalsCard extends ConsumerWidget {
  const _PendingApprovalsCard({required this.pending});

  final List<Tenant> pending;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppDark.surfaceCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.hourglass_bottom_rounded, color: AppDark.accentBright, size: 20),
              const SizedBox(width: 8),
              Text(
                'Onay Bekleyenler',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppDark.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (pending.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text('Bekleyen başvuru yok.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppDark.textSecondary)),
            )
          else
            ...pending.map(
              (tenant) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(tenant.name,
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    color: AppDark.textPrimary,
                                    fontWeight: FontWeight.w700,
                                  )),
                          Text('${tenant.ownerEmail} • ${tenant.city}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppDark.textSecondary)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    FilledButton(
                      onPressed: () =>
                          ref.read(tenantsControllerProvider.notifier).setStatus(tenant.id, TenantStatus.active),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppDark.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      ),
                      child: const Text('Onayla', style: TextStyle(fontWeight: FontWeight.w800)),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _TopTenantsCard extends StatelessWidget {
  const _TopTenantsCard({required this.tenants});

  final List<Tenant> tenants;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: AppDark.surfaceCard(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.trending_up_rounded, color: AppDark.success, size: 20),
              const SizedBox(width: 8),
              Text(
                'Ciroya Göre İlk Sıralar',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppDark.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...tenants.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppDark.surfaceHigh,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text('${entry.key + 1}',
                            style: const TextStyle(color: AppDark.accentBright, fontWeight: FontWeight.w800)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(entry.value.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  color: AppDark.textPrimary,
                                  fontWeight: FontWeight.w700,
                                )),
                      ),
                      Text(adminFormatTry(entry.value.monthlyRevenue),
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                color: AppDark.accentBright,
                                fontWeight: FontWeight.w800,
                              )),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
