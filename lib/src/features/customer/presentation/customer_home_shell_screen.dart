import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/demo/demo_mode.dart';
import '../../../core/theme/app_dark.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/domain/app_user_role.dart';
import '../../discover/presentation/customer_discover_screen.dart';
import '../../profile/data/profile_repository.dart';
import '../../reviews/presentation/my_reviews_screen.dart';
import 'customer_menu_screen.dart';
import 'customer_qr_session_screen.dart';

class CustomerHomeShellScreen extends ConsumerStatefulWidget {
  const CustomerHomeShellScreen({super.key});

  @override
  ConsumerState<CustomerHomeShellScreen> createState() => _CustomerHomeShellScreenState();
}

class _CustomerHomeShellScreenState extends ConsumerState<CustomerHomeShellScreen> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const _DemoModeBanner(),
          Expanded(
            child: IndexedStack(
              index: _index,
              children: const [
                CustomerQrSessionScreen(),
                CustomerDiscoverScreen(),
                CustomerProfileScreen(),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: AppDark.surface,
        indicatorColor: AppDark.accent.withValues(alpha: 0.22),
        selectedIndex: _index,
        onDestinationSelected: (index) => setState(() => _index = index),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.qr_code_scanner_outlined), selectedIcon: Icon(Icons.qr_code_scanner_rounded, color: AppDark.accent), label: 'Tara'),
          NavigationDestination(icon: Icon(Icons.explore_outlined), selectedIcon: Icon(Icons.explore_rounded, color: AppDark.accent), label: 'Keşfet'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person_rounded, color: AppDark.accent), label: 'Profil'),
        ],
      ),
    );
  }
}

class CustomerProfileScreen extends ConsumerWidget {
  const CustomerProfileScreen({super.key});

  Future<void> _editName(BuildContext context, WidgetRef ref, String current) async {
    final controller = TextEditingController(text: current);
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Adı düzenle'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(labelText: 'Ad Soyad'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Vazgeç')),
          FilledButton(onPressed: () => Navigator.pop(context, controller.text.trim()), child: const Text('Kaydet')),
        ],
      ),
    );
    if (newName == null || newName.length < 2) return;
    try {
      await ref.read(profileRepositoryProvider).updateName(newName);
      ref.invalidate(myProfileProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil güncellendi.')));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profil güncellenemedi.')));
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider).valueOrNull;
    final sessionAsync = ref.watch(customerSessionProvider);
    final profile = ref.watch(myProfileProvider).valueOrNull;

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: sessionAsync.when(
        data: (session) {
          final title = profile?.name.isNotEmpty == true ? profile!.name : (authState?.role?.label ?? 'Müşteri');
          final subtitle = profile?.email.isNotEmpty == true
              ? profile!.email
              : (authState?.isAuthenticated == true ? 'Oturum açık' : 'Oturum yok');

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _ProfileHeader(
                title: title,
                subtitle: subtitle,
                icon: Icons.account_circle_outlined,
                onEdit: profile != null ? () => _editName(context, ref, profile.name) : null,
              ),
              const SizedBox(height: 16),
              if (session != null)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Aktif masa', style: TextStyle(fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        Text('${session.restaurantId} • Masa ${session.tableNo}'),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.rate_review_outlined),
                  title: const Text('Yorumlarım'),
                  subtitle: const Text('Yaptığın değerlendirmeleri gör ve yönet'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const MyReviewsScreen()),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const CustomerSettingsSection(),
              const SizedBox(height: 16),
              FilledButton.tonalIcon(
                onPressed: () async {
                  await ref.read(authControllerProvider.notifier).logout();
                },
                icon: const Icon(Icons.logout),
                label: const Text('Çıkış Yap'),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(child: Text('Profil yüklenemedi: $error')),
      ),
    );
  }
}

/// Çevrimdışı demo verisi sunulduğunda üstte beliren uyarı şeridi.
class _DemoModeBanner extends StatelessWidget {
  const _DemoModeBanner();

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: demoModeActive,
      builder: (context, active, _) {
        if (!active) return const SizedBox.shrink();
        return Material(
          color: AppDark.accent.withValues(alpha: 0.16),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  const Icon(Icons.cloud_off_rounded, size: 16, color: AppDark.accent),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Demo modu — sunucuya ulaşılamadı, örnek veriler gösteriliyor.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppDark.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class CustomerSettingsSection extends StatefulWidget {
  const CustomerSettingsSection({super.key});

  @override
  State<CustomerSettingsSection> createState() => _CustomerSettingsSectionState();
}

class _CustomerSettingsSectionState extends State<CustomerSettingsSection> {
  bool _notifications = true;
  bool _emailUpdates = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ayarlar', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        Card(
          child: Column(
            children: [
              SwitchListTile(
                value: _notifications,
                onChanged: (value) => setState(() => _notifications = value),
                secondary: const Icon(Icons.notifications_outlined),
                title: const Text('Bildirimler'),
                subtitle: const Text('Sipariş ve kampanya bildirimleri'),
              ),
              const Divider(height: 1),
              SwitchListTile(
                value: _emailUpdates,
                onChanged: (value) => setState(() => _emailUpdates = value),
                secondary: const Icon(Icons.mail_outline),
                title: const Text('E-posta güncellemeleri'),
                subtitle: const Text('Yeniliklerden haberdar ol'),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.language_outlined),
                title: const Text('Dil'),
                trailing: const Text('Türkçe', style: TextStyle(color: AppDark.textSecondary)),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Dil seçimi yakında.')),
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.lock_outline),
                title: const Text('Gizlilik ve güvenlik'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Gizlilik ayarları yakında.')),
                  );
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('Hakkında'),
                trailing: const Text('v1.0.0', style: TextStyle(color: AppDark.textSecondary)),
                onTap: () {
                  showAboutDialog(
                    context: context,
                    applicationName: 'Şükran',
                    applicationVersion: '1.0.0',
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({required this.title, required this.subtitle, required this.icon, this.onEdit});

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              child: Icon(icon, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            if (onEdit != null)
              IconButton(
                onPressed: onEdit,
                tooltip: 'Adı düzenle',
                icon: const Icon(Icons.edit_outlined),
              ),
          ],
        ),
      ),
    );
  }
}