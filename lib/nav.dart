import 'package:go_router/go_router.dart';
import 'screens/calculator_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/main_shell.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: AppRoutes.calculator,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainShell(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.calculator,
                name: 'calculator',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: CalculatorScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.settings,
                name: 'settings',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: SettingsScreen(),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

class AppRoutes {
  static const String calculator = '/';
  static const String settings = '/settings';
}
