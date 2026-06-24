import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/strings_es.dart';
import '../../core/router/app_router.dart';

/// Shell de navegación — contiene el BottomNavigationBar.
/// Las pantallas se renderizan en [child] (via ShellRoute en go_router).
class HomeScreen extends StatelessWidget {
  final Widget child;
  const HomeScreen({super.key, required this.child});

  static const _tabs = [
    AppRoutes.evaluate,
    AppRoutes.tracker,
    AppRoutes.jobSearch,
    AppRoutes.profile,
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    for (int i = 0; i < _tabs.length; i++) {
      if (location.startsWith(_tabs[i])) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final index = _currentIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (i) => context.go(_tabs[i]),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: StringsEs.navEvaluar,
          ),
          NavigationDestination(
            icon: Icon(Icons.list_alt_outlined),
            selectedIcon: Icon(Icons.list_alt),
            label: StringsEs.navPostulaciones,
          ),
          NavigationDestination(
            icon: Icon(Icons.travel_explore_outlined),
            selectedIcon: Icon(Icons.travel_explore),
            label: 'Buscar empleo',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: StringsEs.navPerfil,
          ),
        ],
      ),
    );
  }
}
