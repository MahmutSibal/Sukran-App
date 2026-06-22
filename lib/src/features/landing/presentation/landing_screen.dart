import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';

class LandingScreen extends StatelessWidget {
  const LandingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFFF7F2), Color(0xFFFDF8F5), Color(0xFFF6ECE5)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 560),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const _BrandMark(),
                    const SizedBox(height: 28),
                    Text('AppSukran', style: Theme.of(context).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.w800, color: AppColors.dark)),
                    const SizedBox(height: 12),
                    Text(
                      'Siparis, masa ve hesap akisini tek ekrandan yoneten sicak tonlu restoran deneyimi.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppColors.muted, height: 1.5),
                    ),
                    const SizedBox(height: 32),
                    _LaunchCard(
                      title: 'Musteri Akisi',
                      description: 'QR giris, menu, sepet ve canli siparis takibi.',
                      icon: Icons.qr_code_scanner_rounded,
                      color: AppColors.primary,
                      onTap: () => context.go('/customer/qr'),
                    ),
                    if (kIsWeb) ...[
                      const SizedBox(height: 16),
                      _LaunchCard(
                        title: 'Yönetim Paneli',
                        description: 'Süper admin ve işletme sahibi hesapları için web panel.',
                        icon: Icons.shield_moon_rounded,
                        color: AppColors.dark,
                        onTap: () => context.go('/admin'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 112,
      height: 112,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [BoxShadow(color: AppColors.primary.withAlpha((255 * 0.13).round()), blurRadius: 28, offset: const Offset(0, 20))],
      ),
      child: const Icon(Icons.restaurant_menu_rounded, size: 54, color: AppColors.primary),
    );
  }
}

class _LaunchCard extends StatelessWidget {
  const _LaunchCard({required this.title, required this.description, required this.icon, required this.color, required this.onTap});

  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withAlpha((255 * 0.86).round()),
      borderRadius: BorderRadius.circular(28),
      child: InkWell(
        borderRadius: BorderRadius.circular(28),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(22),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(color: color.withAlpha((255 * 0.12).round()), borderRadius: BorderRadius.circular(20)),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 6),
                    Text(description, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.muted, height: 1.4)),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Icon(Icons.arrow_forward_rounded, color: AppColors.muted),
            ],
          ),
        ),
      ),
    );
  }
}