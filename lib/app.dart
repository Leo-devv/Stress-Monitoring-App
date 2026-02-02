import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'features/dashboard/presentation/pages/dashboard_page.dart';
import 'features/history/presentation/pages/history_page.dart';
import 'features/device/presentation/pages/device_connection_page.dart';
import 'features/settings/presentation/pages/settings_page.dart';
import 'features/breathing/presentation/pages/breathing_exercise_page.dart';
import 'features/simulation/presentation/pages/simulation_panel_page.dart';
import 'core/constants/app_constants.dart';
import 'core/theme/app_theme.dart';

// Router configuration with 4 tabs + overlay routes
final _router = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(
          path: '/',
          name: 'dashboard',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const DashboardPage(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        ),
        GoRoute(
          path: '/history',
          name: 'history',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const HistoryPage(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        ),
        GoRoute(
          path: '/device',
          name: 'device',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const DeviceConnectionPage(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        ),
        GoRoute(
          path: '/settings',
          name: 'settings',
          pageBuilder: (context, state) => CustomTransitionPage(
            key: state.pageKey,
            child: const SettingsPage(),
            transitionsBuilder:
                (context, animation, secondaryAnimation, child) {
              return FadeTransition(opacity: animation, child: child);
            },
          ),
        ),
      ],
    ),

    // Full-screen routes outside the shell (no bottom nav)
    GoRoute(
      path: '/breathing',
      name: 'breathing',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const BreathingExercisePage(),
        transitionsBuilder:
            (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          );
        },
      ),
    ),
    GoRoute(
      path: '/simulation',
      name: 'simulation',
      pageBuilder: (context, state) => CustomTransitionPage(
        key: state.pageKey,
        child: const SimulationPanelPage(),
        transitionsBuilder:
            (context, animation, secondaryAnimation, child) {
          return SlideTransition(
            position: Tween(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          );
        },
      ),
    ),
  ],
);

class StressMonitorApp extends ConsumerWidget {
  const StressMonitorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      themeMode: ThemeMode.light,
      routerConfig: _router,
    );
  }
}

// Main shell with bottom navigation (4 tabs)
class MainShell extends StatelessWidget {
  final Widget child;

  const MainShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(12),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _calculateSelectedIndex(context),
          onDestinationSelected: (index) => _onItemTapped(index, context),
          backgroundColor: AppColors.surface,
          indicatorColor: AppColors.accent.withAlpha(50),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          height: 70,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard, color: AppColors.accent),
              label: 'Dashboard',
            ),
            NavigationDestination(
              icon: Icon(Icons.history_outlined),
              selectedIcon: Icon(Icons.history, color: AppColors.accent),
              label: 'History',
            ),
            NavigationDestination(
              icon: Icon(Icons.bluetooth_outlined),
              selectedIcon:
                  Icon(Icons.bluetooth_connected, color: AppColors.accent),
              label: 'Device',
            ),
            NavigationDestination(
              icon: Icon(Icons.settings_outlined),
              selectedIcon: Icon(Icons.settings, color: AppColors.accent),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }

  int _calculateSelectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;
    if (location == '/') return 0;
    if (location.startsWith('/history')) return 1;
    if (location.startsWith('/device')) return 2;
    if (location.startsWith('/settings')) return 3;
    return 0;
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.goNamed('dashboard');
        break;
      case 1:
        context.goNamed('history');
        break;
      case 2:
        context.goNamed('device');
        break;
      case 3:
        context.goNamed('settings');
        break;
    }
  }
}
