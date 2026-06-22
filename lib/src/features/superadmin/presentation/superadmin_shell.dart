import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_dark.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/domain/app_user_role.dart';
import 'admin_dashboard_view.dart';
import 'admin_tenants_view.dart';
import 'superadmin_login_screen.dart';

/// Web giriş noktası: oturum/rol durumuna göre giriş, yetkisiz uyarısı veya
/// yönetim kabuğunu gösterir.
class SuperAdminPanel extends ConsumerWidget {
  const SuperAdminPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    return authState.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
        body: AppDark.scaffoldBackground(
          child: Center(child: Text('$error', style: const TextStyle(color: AppDark.textSecondary))),
        ),
      ),
      data: (state) {
        if (!state.isAuthenticated) {
          return const SuperAdminLoginScreen();
        }
        if (state.role != AppUserRole.superAdmin) {
          return const _UnauthorizedScreen();
        }
        return const SuperAdminShell();
      },
    );
  }
}

class _UnauthorizedScreen extends ConsumerWidget {
  const _UnauthorizedScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: AppDark.scaffoldBackground(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(28),
              decoration: AppDark.surfaceCard(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.gpp_bad_rounded, color: AppDark.danger, size: 48),
                  const SizedBox(height: 16),
                  Text('Yetkisiz erişim',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            color: AppDark.textPrimary,
                            fontWeight: FontWeight.w900,
                          )),
                  const SizedBox(height: 8),
                  Text('Bu hesap süper admin değil. Lütfen yetkili bir hesapla giriş yapın.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppDark.textSecondary)),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: () => ref.read(authControllerProvider.notifier).logout(),
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Çıkış Yap'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _AdminSection { dashboard, tenants }

class SuperAdminShell extends ConsumerStatefulWidget {
  const SuperAdminShell({super.key});

  @override
  ConsumerState<SuperAdminShell> createState() => _SuperAdminShellState();
}

class _SuperAdminShellState extends ConsumerState<SuperAdminShell> {
  _AdminSection _section = _AdminSection.dashboard;

  Widget get _content => switch (_section) {
        _AdminSection.dashboard => const AdminDashboardView(),
        _AdminSection.tenants => const AdminTenantsView(),
      };

  @override
  Widget build(BuildContext context) {
    final isWide = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      drawer: isWide
          ? null
          : Drawer(
              backgroundColor: AppDark.surface,
              child: _Sidebar(
                section: _section,
                onSelect: (section) {
                  setState(() => _section = section);
                  Navigator.of(context).pop();
                },
              ),
            ),
      appBar: isWide
          ? null
          : AppBar(
              backgroundColor: AppDark.surface,
              title: const Text('Süper Admin', style: TextStyle(fontWeight: FontWeight.w900)),
            ),
      body: AppDark.scaffoldBackground(
        child: SafeArea(
          child: Row(
            children: [
              if (isWide)
                SizedBox(
                  width: 252,
                  child: _Sidebar(section: _section, onSelect: (section) => setState(() => _section = section)),
                ),
              if (isWide) const VerticalDivider(width: 1, color: AppDark.hairline),
              Expanded(child: _content),
            ],
          ),
        ),
      ),
    );
  }
}

class _Sidebar extends ConsumerWidget {
  const _Sidebar({required this.section, required this.onSelect});

  final _AdminSection section;
  final ValueChanged<_AdminSection> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  gradient: AppDark.accentGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.shield_moon_rounded, color: Color(0xFF1A1206)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('AppSukran',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppDark.textPrimary,
                              fontWeight: FontWeight.w900,
                            )),
                    Text('Süper Admin',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppDark.textSecondary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          _NavItem(
            icon: Icons.dashboard_rounded,
            label: 'Pano',
            selected: section == _AdminSection.dashboard,
            onTap: () => onSelect(_AdminSection.dashboard),
          ),
          const SizedBox(height: 8),
          _NavItem(
            icon: Icons.storefront_rounded,
            label: 'Kiracılar',
            selected: section == _AdminSection.tenants,
            onTap: () => onSelect(_AdminSection.tenants),
          ),
          const Spacer(),
          const Divider(color: AppDark.hairline),
          const SizedBox(height: 8),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const CircleAvatar(
              backgroundColor: AppDark.surfaceHigh,
              child: Icon(Icons.person_rounded, color: AppDark.accent),
            ),
            title: const Text('Süper Admin',
                style: TextStyle(color: AppDark.textPrimary, fontWeight: FontWeight.w700)),
            subtitle: const Text('superadmin@appsukran.local',
                maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: AppDark.textSecondary, fontSize: 11)),
            trailing: IconButton(
              tooltip: 'Çıkış',
              onPressed: () => ref.read(authControllerProvider.notifier).logout(),
              icon: const Icon(Icons.logout_rounded, color: AppDark.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({required this.icon, required this.label, required this.selected, required this.onTap});

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppDark.accent.withValues(alpha: 0.16) : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 20, color: selected ? AppDark.accent : AppDark.textSecondary),
              const SizedBox(width: 12),
              Text(
                label,
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: selected ? AppDark.textPrimary : AppDark.textSecondary,
                      fontWeight: FontWeight.w800,
                    ),
              ),
              if (selected) ...[
                const Spacer(),
                Container(width: 6, height: 6, decoration: const BoxDecoration(color: AppDark.accent, shape: BoxShape.circle)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
