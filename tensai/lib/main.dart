import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme.dart';
import 'providers/auth_provider.dart';
import 'router.dart';
import 'screens/splash_screen.dart';

void main() {
  runApp(const ProviderScope(child: TensaiApp()));
}

class TensaiApp extends ConsumerWidget {
  const TensaiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authNotifierProvider);
    final splashMinElapsed = ref.watch(splashMinTimeElapsedProvider);
    final router = ref.watch(goRouterProvider);

    final showSplash = authAsync.isLoading || !splashMinElapsed;

    if (showSplash) {
      return MaterialApp(
        title: 'Tensai',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        debugShowCheckedModeBanner: false,
        home: const SplashScreen(),
      );
    }

    return MaterialApp.router(
      title: 'Tensai',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.dark,
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    );
  }
}
