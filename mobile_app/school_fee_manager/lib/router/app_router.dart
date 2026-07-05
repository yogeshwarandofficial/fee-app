import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:school_fee_manager/core/theme/app_theme.dart';
import 'package:school_fee_manager/features/auth/auth_provider.dart';
import 'package:school_fee_manager/features/auth/login_screen.dart';
import 'package:school_fee_manager/features/dashboard/dashboard_screen.dart';
import 'package:school_fee_manager/features/master_config/master_config_screen.dart';
import 'package:school_fee_manager/features/students/students_list_screen.dart';
import 'package:school_fee_manager/features/fee_allocation/fee_allocation_screen.dart';

// ── Router provider ────────────────────────────────────────────────────────────

/// Creates the GoRouter once and caches it for the app lifetime.
///
/// [AuthNotifier] is passed as [refreshListenable] so the router re-evaluates
/// its [redirect] function whenever [notifyListeners()] is called (login,
/// logout, initial token check).
///
/// [ref.read] is used intentionally here (not watch) because we only need to
/// get the notifier instance once — the notifier itself notifies the router.
final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.read(authProvider.notifier);

  return GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: false,
    refreshListenable: notifier,

    // ── Auth guard ──────────────────────────────────────────────────────────
    redirect: (BuildContext context, GoRouterState state) {
      // Read current auth state via the Riverpod container (public API).
      final auth = ref.read(authProvider);
      final loc  = state.matchedLocation;

      // While we're still checking secure storage, stay on splash (no redirect).
      if (auth.status == AuthStatus.checking) return null;

      final isAuthenticated = auth.isAuthenticated;

      // Unauthenticated user trying to reach any route other than /login → /login
      if (!isAuthenticated && loc != '/login') return '/login';

      // Authenticated user trying to visit /login or splash → /home
      if (isAuthenticated && (loc == '/login' || loc == '/')) return '/home';

      return null; // no redirect needed
    },

    routes: [
      // ── Splash (shown during AuthStatus.checking) ────────────────────────
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, _) => const _SplashScreen(),
      ),

      // ── Login ────────────────────────────────────────────────────────────
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, _) => const LoginScreen(),
      ),

      // ── Home (protected) ─────────────────────────────────────────────────
      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, _) => const DashboardScreen(),
      ),

      // ── Master Config ────────────────────────────────────────────────────
      GoRoute(
        path: '/master-config',
        name: 'master_config',
        builder: (context, _) => const MasterConfigScreen(),
      ),

      // ── Students ──────────────────────────────────────────────────────────────────
      GoRoute(
        path: '/students',
        name: 'students',
        builder: (context, _) => const StudentsListScreen(),
      ),

      // ── Fee Allocation ────────────────────────────────────────────────────────────
      GoRoute(
        path: '/allocations',
        name: 'allocations',
        builder: (context, _) => const FeeAllocationScreen(),
      ),

      // Additional feature routes will be added in Parts 7–13.
    ],
  );
});

// ── Splash screen ──────────────────────────────────────────────────────────────

/// Shown briefly while [AuthNotifier._init()] checks secure storage.
/// The router redirects away from this screen as soon as auth status is known.
class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.account_balance_rounded,
              size: 72,
              color: Colors.white,
            ),
            const SizedBox(height: 24),
            const Text(
              'MJR School',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Fee Manager',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w400,
                color: Colors.white.withAlpha(180),
              ),
            ),
            const SizedBox(height: 48),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
