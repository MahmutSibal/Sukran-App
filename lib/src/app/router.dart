import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/presentation/auth_gate_screen.dart';
import '../features/customer/presentation/customer_home_shell_screen.dart';
import '../features/customer/presentation/customer_menu_screen.dart';
import '../features/customer/presentation/customer_order_status_screen.dart';
import '../features/customer/presentation/customer_qr_session_screen.dart';
import '../features/discover/presentation/customer_discover_screen.dart';
import '../features/superadmin/presentation/superadmin_shell.dart';
import '../features/web_panel/presentation/web_admin_portal_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(path: '/', builder: (context, state) => const AuthGateScreen()),
      GoRoute(path: '/customer', builder: (context, state) => const CustomerHomeShellScreen()),
      GoRoute(path: '/customer/qr', builder: (context, state) => const CustomerQrSessionScreen()),
      GoRoute(path: '/customer/discover', builder: (context, state) => const CustomerDiscoverScreen()),
      GoRoute(path: '/customer/menu', builder: (context, state) => const CustomerMenuScreen()),
      GoRoute(path: '/customer/orders', builder: (context, state) => const CustomerOrderStatusScreen()),
      GoRoute(path: '/admin', builder: (context, state) => const WebAdminPortalScreen()),
    ],
  );
});