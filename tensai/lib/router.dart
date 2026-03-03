import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'providers/auth_provider.dart';
import 'screens/ask_screen.dart';
import 'screens/history_screen.dart';
import 'screens/send_otp_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/sources_screen.dart';
import 'screens/verify_otp_screen.dart';
import 'widgets/main_shell.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

class _RouterRefreshNotifier extends ChangeNotifier {
  void refresh() => notifyListeners();
}

final _routerRefreshProvider = Provider<_RouterRefreshNotifier>((ref) => _RouterRefreshNotifier());

final goRouterProvider = Provider<GoRouter>((ref) {
  final refresh = ref.watch(_routerRefreshProvider);
  ref.listen<AsyncValue<AuthState>>(authNotifierProvider, (_, __) {
    refresh.refresh();
  });

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final loc = state.matchedLocation;
      final isShellRoute = loc == '/ask' || loc == '/sources' || loc == '/history';
      if (!isShellRoute) return null;

      final container = ProviderScope.containerOf(context);
      final auth = container.read(authNotifierProvider);
      if (isShellRoute) {
        return auth.when(
          data: (a) => a.isLoggedIn ? null : '/send-otp',
          loading: () => null,
          error: (_, __) => '/send-otp',
        );
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        redirect: (context, _) {
          final container = ProviderScope.containerOf(context);
          final auth = container.read(authNotifierProvider);
          return auth.when(
            data: (a) => a.isLoggedIn ? '/ask' : '/send-otp',
            loading: () => null,
            error: (_, __) => '/send-otp',
          );
        },
        builder: (_, __) => const SizedBox.shrink(),
      ),
      GoRoute(
        path: '/send-otp',
        builder: (_, __) => const SendOtpScreen(),
      ),
      GoRoute(
        path: '/verify-otp',
        builder: (context, state) {
          final email = state.extra as String?;
          return VerifyOtpScreen(email: email);
        },
      ),
      GoRoute(
        path: '/settings',
        builder: (_, __) => const SettingsScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            MainShell(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/ask',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: AskScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/sources',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: SourcesScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/history',
                pageBuilder: (context, state) => const NoTransitionPage(
                  child: HistoryScreen(),
                ),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
