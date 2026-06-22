import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_dark.dart';
import '../application/superadmin_controller.dart';
import '../domain/tenant.dart';
import 'admin_widgets.dart';

class AdminTenantsView extends ConsumerWidget {
  const AdminTenantsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tenantsAsync = ref.watch(tenantsControllerProvider);
    final filtered = ref.watch(filteredTenantsProvider);
    final statusFilter = ref.watch(tenantStatusFilterProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 28, 28, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Kiracılar',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: AppDark.textPrimary,
                              fontWeight: FontWeight.w900,
                            )),
                    Text('Sistemdeki tüm işletmeleri yönetin',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppDark.textSecondary)),
                  ],
                ),
              ),
              _NewTenantButton(onPressed: () => _openCreateDialog(context, ref)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  style: const TextStyle(color: AppDark.textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'İsim, e-posta veya şehir ara…',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                  onChanged: (value) => ref.read(tenantSearchProvider.notifier).state = value,
                ),
              ),
              const SizedBox(width: 12),
              _StatusFilterChips(
                selected: statusFilter,
                onChanged: (value) => ref.read(tenantStatusFilterProvider.notifier).state = value,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: tenantsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => Center(
              child: Text('Kiracılar yüklenemedi: $error', style: const TextStyle(color: AppDark.textSecondary)),
            ),
            data: (_) {
              if (filtered.isEmpty) {
                return Center(
                  child: Text('Eşleşen kiracı yok.',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppDark.textSecondary)),
                );
              }
              return _TenantsTable(tenants: filtered);
            },
          ),
        ),
      ],
    );
  }

  Future<void> _openCreateDialog(BuildContext context, WidgetRef ref) async {
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (_) => const _CreateTenantDialog(),
    );
  }
}

class _NewTenantButton extends StatelessWidget {
  const _NewTenantButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppDark.accentGradient,
        borderRadius: BorderRadius.circular(AppDark.radiusControl),
      ),
      child: FilledButton.icon(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: const Color(0xFF120D04),
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
        icon: const Icon(Icons.add_business_rounded, size: 18),
        label: const Text('Yeni Kiracı', style: TextStyle(fontWeight: FontWeight.w900)),
      ),
    );
  }
}

class _StatusFilterChips extends StatelessWidget {
  const _StatusFilterChips({required this.selected, required this.onChanged});

  final TenantStatus? selected;
  final ValueChanged<TenantStatus?> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget chip(String label, TenantStatus? value) {
      final isSelected = selected == value;
      return Padding(
        padding: const EdgeInsets.only(left: 8),
        child: GestureDetector(
          onTap: () => onChanged(value),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? AppDark.accent : AppDark.surfaceHigh,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: isSelected ? Colors.transparent : AppDark.hairline),
            ),
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: isSelected ? const Color(0xFF1A1206) : AppDark.textSecondary,
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        chip('Tümü', null),
        chip('Aktif', TenantStatus.active),
        chip('Bekleyen', TenantStatus.pending),
        chip('Askıda', TenantStatus.suspended),
      ],
    );
  }
}

class _TenantsTable extends StatelessWidget {
  const _TenantsTable({required this.tenants});

  final List<Tenant> tenants;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 760;
        return ListView(
          padding: const EdgeInsets.fromLTRB(28, 0, 28, 28),
          children: [
            Container(
              decoration: AppDark.surfaceCard(),
              clipBehavior: Clip.antiAlias,
              child: Column(
                children: [
                  if (wide) const _TableHeader(),
                  for (var i = 0; i < tenants.length; i++)
                    _TenantRow(tenant: tenants[i], wide: wide, isLast: i == tenants.length - 1),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelMedium?.copyWith(
          color: AppDark.textSecondary,
          fontWeight: FontWeight.w800,
        );
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppDark.hairline)),
      ),
      child: Row(
        children: [
          Expanded(flex: 3, child: Text('İŞLETME', style: style)),
          Expanded(flex: 2, child: Text('ŞEHİR', style: style)),
          Expanded(flex: 2, child: Text('PLAN', style: style)),
          Expanded(flex: 2, child: Text('SİPARİŞ/AY', style: style)),
          Expanded(flex: 2, child: Text('CİRO/AY', style: style)),
          Expanded(flex: 2, child: Text('DURUM', style: style)),
          const SizedBox(width: 44),
        ],
      ),
    );
  }
}

class _TenantRow extends ConsumerWidget {
  const _TenantRow({required this.tenant, required this.wide, required this.isLast});

  final Tenant tenant;
  final bool wide;
  final bool isLast;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final border = isLast ? null : const Border(bottom: BorderSide(color: AppDark.hairline));

    if (!wide) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(border: border),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: _TenantIdentity(tenant: tenant)),
                _RowActions(tenant: tenant),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                AdminStatusBadge(status: tenant.status),
                AdminPlanBadge(plan: tenant.plan),
                _MiniStat(icon: Icons.location_city_rounded, text: tenant.city),
                _MiniStat(icon: Icons.receipt_long_rounded, text: '${tenant.monthlyOrders}/ay'),
                _MiniStat(icon: Icons.payments_rounded, text: adminFormatTry(tenant.monthlyRevenue)),
              ],
            ),
          ],
        ),
      );
    }

    final cellStyle = Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppDark.textPrimary);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(border: border),
      child: Row(
        children: [
          Expanded(flex: 3, child: _TenantIdentity(tenant: tenant)),
          Expanded(flex: 2, child: Text(tenant.city, style: cellStyle)),
          Expanded(flex: 2, child: Align(alignment: Alignment.centerLeft, child: AdminPlanBadge(plan: tenant.plan))),
          Expanded(flex: 2, child: Text('${tenant.monthlyOrders}', style: cellStyle)),
          Expanded(
            flex: 2,
            child: Text(adminFormatTry(tenant.monthlyRevenue),
                style: cellStyle?.copyWith(fontWeight: FontWeight.w700)),
          ),
          Expanded(flex: 2, child: Align(alignment: Alignment.centerLeft, child: AdminStatusBadge(status: tenant.status))),
          SizedBox(width: 44, child: _RowActions(tenant: tenant)),
        ],
      ),
    );
  }
}

class _TenantIdentity extends StatelessWidget {
  const _TenantIdentity({required this.tenant});

  final Tenant tenant;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppDark.surfaceHigh,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppDark.hairline),
          ),
          child: const Icon(Icons.storefront_rounded, color: AppDark.accent, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(tenant.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: AppDark.textPrimary,
                        fontWeight: FontWeight.w800,
                      )),
              Text(tenant.ownerEmail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppDark.textSecondary)),
            ],
          ),
        ),
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(color: AppDark.surfaceHigh, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppDark.textSecondary),
          const SizedBox(width: 5),
          Text(text, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: AppDark.textSecondary)),
        ],
      ),
    );
  }
}

class _RowActions extends ConsumerWidget {
  const _RowActions({required this.tenant});

  final Tenant tenant;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<TenantStatus>(
      icon: const Icon(Icons.more_vert_rounded, color: AppDark.textSecondary),
      color: AppDark.surfaceHigh,
      onSelected: (status) => ref.read(tenantsControllerProvider.notifier).setStatus(tenant.id, status),
      itemBuilder: (context) => [
        if (tenant.status != TenantStatus.active)
          const PopupMenuItem(
            value: TenantStatus.active,
            child: Text('Aktifleştir', style: TextStyle(color: AppDark.success, fontWeight: FontWeight.w700)),
          ),
        if (tenant.status != TenantStatus.suspended)
          const PopupMenuItem(
            value: TenantStatus.suspended,
            child: Text('Askıya Al', style: TextStyle(color: AppDark.danger, fontWeight: FontWeight.w700)),
          ),
        if (tenant.status != TenantStatus.pending)
          const PopupMenuItem(
            value: TenantStatus.pending,
            child: Text('Onaya Geri Al', style: TextStyle(color: AppDark.textPrimary)),
          ),
      ],
    );
  }
}

class _CreateTenantDialog extends ConsumerStatefulWidget {
  const _CreateTenantDialog();

  @override
  ConsumerState<_CreateTenantDialog> createState() => _CreateTenantDialogState();
}

class _CreateTenantDialogState extends ConsumerState<_CreateTenantDialog> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _ownerName = TextEditingController();
  final _ownerEmail = TextEditingController();
  final _city = TextEditingController();
  final _tables = TextEditingController(text: '10');
  TenantPlan _plan = TenantPlan.pro;
  bool _saving = false;

  @override
  void dispose() {
    _name.dispose();
    _ownerName.dispose();
    _ownerEmail.dispose();
    _city.dispose();
    _tables.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _saving = true);
    await ref.read(tenantsControllerProvider.notifier).createTenant(
          name: _name.text.trim(),
          ownerName: _ownerName.text.trim(),
          ownerEmail: _ownerEmail.text.trim(),
          city: _city.text.trim(),
          plan: _plan,
          tableCount: int.tryParse(_tables.text.trim()) ?? 0,
        );
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kiracı oluşturuldu (onay bekliyor).')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppDark.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDark.radiusModuleLg)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.add_business_rounded, color: AppDark.accent),
                    const SizedBox(width: 10),
                    Text('Yeni Kiracı',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: AppDark.textPrimary,
                              fontWeight: FontWeight.w900,
                            )),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded, color: AppDark.textSecondary),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _field(_name, 'İşletme adı', Icons.storefront_rounded),
                const SizedBox(height: 14),
                _field(_ownerName, 'Sahip adı', Icons.person_outline_rounded),
                const SizedBox(height: 14),
                _field(_ownerEmail, 'Sahip e-posta', Icons.alternate_email_rounded,
                    keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: _field(_city, 'Şehir', Icons.location_city_rounded)),
                    const SizedBox(width: 14),
                    SizedBox(
                      width: 120,
                      child: _field(_tables, 'Masa', Icons.table_bar_rounded,
                          keyboardType: TextInputType.number),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<TenantPlan>(
                  initialValue: _plan,
                  dropdownColor: AppDark.surfaceHigh,
                  style: const TextStyle(color: AppDark.textPrimary),
                  decoration: const InputDecoration(
                    labelText: 'Plan',
                    prefixIcon: Icon(Icons.workspace_premium_rounded),
                  ),
                  items: TenantPlan.values
                      .map((plan) => DropdownMenuItem(value: plan, child: Text(plan.label)))
                      .toList(growable: false),
                  onChanged: (value) => setState(() => _plan = value ?? TenantPlan.pro),
                ),
                const SizedBox(height: 24),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: AppDark.accentGradient,
                    borderRadius: BorderRadius.circular(AppDark.radiusControl),
                  ),
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      foregroundColor: const Color(0xFF120D04),
                      shadowColor: Colors.transparent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF1A1206)),
                          )
                        : const Text('Oluştur', style: TextStyle(fontWeight: FontWeight.w900)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController controller, String label, IconData icon, {TextInputType? keyboardType}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: AppDark.textPrimary),
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
      validator: (value) => value == null || value.trim().isEmpty ? 'Zorunlu alan' : null,
    );
  }
}
