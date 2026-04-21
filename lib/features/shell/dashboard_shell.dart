import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';

class DashboardShell extends StatelessWidget {
  const DashboardShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
        color: AppColors.background,
        child: NavigationBar(
          height: 72,
          surfaceTintColor: Colors.transparent,
          shadowColor: Colors.black12,
          selectedIndex: navigationShell.currentIndex,
          backgroundColor: AppColors.card.withOpacity(0.92),
          indicatorColor: AppColors.primary.withOpacity(0.15),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          onDestinationSelected: (index) => navigationShell.goBranch(index,
              initialLocation: index == navigationShell.currentIndex),
          destinations: const [
            NavigationDestination(
                icon: Icon(Icons.grid_view_rounded),
                selectedIcon:
                    Icon(Icons.grid_view_rounded, color: AppColors.primary),
                label: 'Home'),
            NavigationDestination(
                icon: Icon(Icons.directions_walk_rounded),
                selectedIcon: Icon(Icons.directions_walk_rounded,
                    color: AppColors.primary),
                label: 'Activities'),
            NavigationDestination(
                icon: Icon(Icons.flag_rounded),
                selectedIcon:
                    Icon(Icons.flag_rounded, color: AppColors.primary),
                label: 'Goals'),
            NavigationDestination(
                icon: Icon(Icons.lightbulb_outline_rounded),
                selectedIcon: Icon(Icons.lightbulb_outline_rounded,
                    color: AppColors.primary),
                label: 'Tips'),
            NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_outline_rounded,
                    color: AppColors.primary),
                label: 'Profile'),
          ],
        ),
      ),
    );
  }
}
