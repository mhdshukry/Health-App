import 'package:flutter/material.dart';

import '../core/theme/app_theme.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.title,
    required this.child,
    this.floatingActionButton,
  });

  final String title;
  final Widget child;
  final Widget? floatingActionButton;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      backgroundColor: AppColors.background,
      floatingActionButton: floatingActionButton != null
          ? Padding(
              padding: const EdgeInsets.only(
                  bottom: 72.0), // Lift above floating nav bar
              child: floatingActionButton,
            )
          : null,
      body: SafeArea(
        bottom:
            false, // Don't restrict bottom safe area here, as we extend body in shell
        child: Padding(
          // Ensure enough padding at the bottom so content isn't blocked by the floating nav bar
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
          child: child,
        ),
      ),
    );
  }
}
