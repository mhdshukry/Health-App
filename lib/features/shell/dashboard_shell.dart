import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';

class DashboardShell extends StatelessWidget {
  const DashboardShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    // Determine if we should show the floating nav bar
    return Scaffold(
      extendBody: true, // Allows body to scroll behind the nav bar
      body: navigationShell,
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.only(left: 16, right: 16, bottom: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: AppColors.primary.withOpacity(0.05),
                blurRadius: 30,
                spreadRadius: -5,
              )
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(32),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.card.withOpacity(0.8),
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.08),
                    width: 1,
                  ),
                ),
                child: NavigationBar(
                  height: 65,
                  elevation: 0,
                  backgroundColor: Colors.transparent,
                  surfaceTintColor: Colors.transparent,
                  selectedIndex: navigationShell.currentIndex,
                  indicatorColor: AppColors.primary.withOpacity(0.2),
                  labelBehavior: NavigationDestinationLabelBehavior
                      .alwaysHide, // Modern apps often hide labels or show them only on select, let's hide here for cleaner look, but we'll show on select below.
                  animationDuration: const Duration(milliseconds: 300),
                  onDestinationSelected: (index) => navigationShell.goBranch(
                      index,
                      initialLocation: index == navigationShell.currentIndex),
                  destinations: const [
                    NavigationDestination(
                      icon:
                          Icon(Icons.grid_view_rounded, color: AppColors.muted),
                      selectedIcon: Icon(Icons.grid_view_rounded,
                          color: AppColors.primary),
                      label: 'Home',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.directions_walk_rounded,
                          color: AppColors.muted),
                      selectedIcon: Icon(Icons.directions_walk_rounded,
                          color: AppColors.primary),
                      label: 'Activities',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.flag_rounded, color: AppColors.muted),
                      selectedIcon:
                          Icon(Icons.flag_rounded, color: AppColors.primary),
                      label: 'Goals',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.lightbulb_outline_rounded,
                          color: AppColors.muted),
                      selectedIcon: Icon(Icons.lightbulb_outline_rounded,
                          color: AppColors.primary),
                      label: 'Tips',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.person_outline_rounded,
                          color: AppColors.muted),
                      selectedIcon: Icon(Icons.person_outline_rounded,
                          color: AppColors.primary),
                      label: 'Profile',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
