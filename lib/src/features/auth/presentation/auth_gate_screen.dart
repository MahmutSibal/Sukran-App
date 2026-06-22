import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../customer/presentation/customer_home_shell_screen.dart';
import '../application/auth_controller.dart';
import '../domain/app_user_role.dart';
import 'auth_entry_screen.dart';
import '../../web_panel/presentation/web_admin_portal_screen.dart';

class AuthGateScreen extends ConsumerWidget {
  const AuthGateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    return authState.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (error, stackTrace) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(error.toString(), textAlign: TextAlign.center),
          ),
        ),
      ),
      data: (state) {
        if (!state.isAuthenticated) {
          return const AuthEntryScreen();
        }

        // If backend provided a role, use it. Otherwise default to customer flow.
        switch (state.role) {
          case AppUserRole.superAdmin:
          case AppUserRole.restaurantOwner:
            return kIsWeb ? const WebAdminPortalScreen() : const _RoleUnavailableScreen();
          default:
            return const CustomerHomeShellScreen();
        }
      },
    );
  }
}

class _RoleUnavailableScreen extends ConsumerWidget {
  const _RoleUnavailableScreen();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.web_rounded, size: 56, color: Colors.orange),
                const SizedBox(height: 16),
                const Text(
                  'Bu hesap yalnızca web panelde kullanılabilir.',
                  textAlign: TextAlign.center,
                ),
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
    );
  }
}