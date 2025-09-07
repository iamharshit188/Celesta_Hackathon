import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:wpfactcheck/core/navigation/app_router.dart';

class BottomNavScaffold extends StatelessWidget {
  final Widget child;

  const BottomNavScaffold({
    super.key,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _getSelectedIndex(location),
        onDestinationSelected: (index) => _onDestinationSelected(context, index),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.explore_outlined),
            selectedIcon: Icon(Icons.explore),
            label: 'Explore',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  int _getSelectedIndex(String location) {
    switch (location) {
      case AppRouter.home:
        return 0;
      case AppRouter.explore:
        return 1;
      case AppRouter.profile:
        return 2;
      default:
        return 0;
    }
  }

  void _onDestinationSelected(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppRouter.home);
        break;
      case 1:
        context.go(AppRouter.explore);
        break;
      case 2:
        context.go(AppRouter.profile);
        break;
    }
  }
}
