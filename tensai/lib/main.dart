import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme.dart';
import 'providers/auth_provider.dart';
import 'router.dart';

void main() {
  runApp(const ProviderScope(child: TensaiApp()));
}

class TensaiApp extends ConsumerWidget {
  const TensaiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authAsync = ref.watch(authNotifierProvider);
    final router = ref.watch(goRouterProvider);

    return authAsync.when(
      loading: () => MaterialApp(
        title: 'Tensai',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        home: const Scaffold(
          body: Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366f1)),
            ),
          ),
        ),
      ),
      data: (_) => MaterialApp.router(
        title: 'Tensai',
        theme: AppTheme.light,
        debugShowCheckedModeBanner: false,
        darkTheme: AppTheme.dark,
        routerConfig: router,
      ),
      error: (_, __) => MaterialApp.router(
        title: 'Tensai',
        theme: AppTheme.light,
        debugShowCheckedModeBanner: false,
        darkTheme: AppTheme.dark,
        routerConfig: router,
      ),
    );
  }
}
