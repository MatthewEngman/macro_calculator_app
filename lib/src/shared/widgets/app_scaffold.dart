import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppScaffold extends StatelessWidget {
  final Widget child;
  final String currentPath;

  const AppScaffold({
    super.key,
    required this.child,
    required this.currentPath,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _calculateSelectedIndex(currentPath),
        onDestinationSelected: (index) => _onItemTapped(index, context),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.calculate),
            label: 'Calculator',
          ),
          NavigationDestination(
            icon: Icon(Icons.restaurant_menu),
            label: 'Meal Plans',
          ),
          NavigationDestination(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  int _calculateSelectedIndex(String currentPath) {
    if (currentPath == '/' || currentPath.isEmpty) return 0;
    if (currentPath.startsWith('/calculator')) return 1;
    if (currentPath.startsWith('/meal-plans')) return 2;
    if (currentPath.startsWith('/profile')) return 3;
    if (currentPath.startsWith('/progress')) {
      return 0; // Show dashboard tab as active for progress
    }
    return 0; // Default to dashboard
  }

  void _onItemTapped(int index, BuildContext context) {
    switch (index) {
      case 0:
        context.go('/'); // Dashboard
        break;
      case 1:
        context.go('/calculator');
        break;
      case 2:
        context.go('/meal-plans');
        break;
      case 3:
        context.go('/profile');
        break;
    }
  }
}
