import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_dark.dart';
import '../../auth/application/auth_controller.dart';
import '../../auth/domain/app_user_role.dart';
import '../../auth/presentation/auth_entry_screen.dart';
import '../../superadmin/presentation/superadmin_shell.dart';
import 'restaurant_owner_shell.dart';

class WebAdminPortalScreen extends ConsumerWidget {
  const WebAdminPortalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    return authState.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, _) => Scaffold(
        body: AppDark.scaffoldBackground(
          child: Center(
            child: Text('Giriş durumu okunamadı: $error', style: const TextStyle(color: AppDark.textSecondary)),
          ),
        ),
      ),
      data: (state) {
        if (!state.isAuthenticated) {
          return const AuthEntryScreen();
        }

        switch (state.role) {
          case AppUserRole.superAdmin:
            return const SuperAdminShell();
          case AppUserRole.restaurantOwner:
            return RestaurantOwnerShell(accessToken: state.accessToken);
          default:
            return const _WebOnlyWarning();
        }
      },
    );
  }
}

class _WebOnlyWarning extends StatelessWidget {
  const _WebOnlyWarning();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppDark.scaffoldBackground(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Container(
              margin: const EdgeInsets.all(24),
              padding: const EdgeInsets.all(28),
              decoration: AppDark.surfaceCard(),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.public_off_rounded, color: AppDark.danger, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    'Bu rol web panel için tanımlı değil',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppDark.textPrimary,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Süper admin ve işletme sahibi hesapları web panelde açılır. Mobil uygulama yalnızca müşteri akışını gösterir.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppDark.textSecondary),
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
