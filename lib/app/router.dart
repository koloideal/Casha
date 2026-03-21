import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/l10n/locale_provider.dart';
import '../features/dashboard/screen.dart';
import '../features/add_transaction/screen.dart';
import '../features/categories/screen.dart';
import '../features/settings/screen.dart';
import '../features/splash/screen.dart';
import '../shared/models/transaction.dart';

final _shellKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      builder: (context, state) => const SplashScreen(),
    ),
    ShellRoute(
      navigatorKey: _shellKey,
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        GoRoute(
          path: '/dashboard',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: DashboardScreen(),
          ),
        ),
        GoRoute(
          path: '/categories',
          pageBuilder: (context, state) => const NoTransitionPage(
            child: CategoriesScreen(),
          ),
        ),
        GoRoute(
          path: '/settings',
          pageBuilder: (context, state) => NoTransitionPage(
            child: SettingsScreen(),
          ),
        ),
      ],
    ),
    GoRoute(
      path: '/add',
      builder: (context, state) {
        final transaction = state.extra as Transaction?;
        return AddTransactionScreen(initial: transaction);
      },
    ),
  ],
);

class AppShell extends ConsumerWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  int _locationToIndex(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/categories')) return 1;
    if (location.startsWith('/settings')) return 2;
    return 0;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(stringsProvider);
    final idx = _locationToIndex(context);
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: idx,
        onDestinationSelected: (i) {
          if (i == 0) context.go('/dashboard');
          if (i == 1) context.go('/categories');
          if (i == 2) context.go('/settings');
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.dashboard_outlined),
            selectedIcon: const Icon(Icons.dashboard_rounded),
            label: s.navDashboard,
          ),
          NavigationDestination(
            icon: const Icon(Icons.pie_chart_outline_rounded),
            selectedIcon: const Icon(Icons.pie_chart_rounded),
            label: s.navCategories,
          ),
          NavigationDestination(
            icon: const Icon(Icons.settings_outlined),
            selectedIcon: const Icon(Icons.settings_rounded),
            label: s.navSettings,
          ),
        ],
      ),
    );
  }
}
