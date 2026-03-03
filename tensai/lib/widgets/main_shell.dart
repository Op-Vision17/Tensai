import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/app_colors.dart';
import 'logo_widget.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({
    super.key,
    required this.navigationShell,
  });

  final StatefulNavigationShell navigationShell;

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  static const _tabs = [
    (path: '/ask', label: 'Ask', icon: Icons.auto_awesome),
    (path: '/sources', label: 'Sources', icon: Icons.folder_open),
    (path: '/history', label: 'History', icon: Icons.history),
  ];

  int _indexForPath(String path) {
    final i = _tabs.indexWhere((t) => t.path == path);
    return i >= 0 ? i : 0;
  }

  @override
  Widget build(BuildContext context) {
    final loc = GoRouterState.of(context).matchedLocation;
    final currentIndex = _indexForPath(loc);

    return Scaffold(
      appBar: AppBar(
        leading: const Padding(
          padding: EdgeInsets.all(8),
          child: LogoWidget(width: 32),
        ),
        title: Text(
          _tabs[currentIndex].path == '/ask' ? 'Tensai' : _tabs[currentIndex].label,
          style: GoogleFonts.spaceGrotesk(color: AppColors.subtitle),
        ),
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.subtitle,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: widget.navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: currentIndex,
        onTap: (index) => widget.navigationShell.goBranch(index),
        items: _tabs
            .map(
              (t) => BottomNavigationBarItem(
                icon: Icon(t.icon),
                label: t.label,
              ),
            )
            .toList(),
      ),
    );
  }
}
