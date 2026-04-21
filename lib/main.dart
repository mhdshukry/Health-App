import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'core/theme/app_theme.dart';
import 'core/notifications/notification_service.dart';
import 'features/activities/activities_screen.dart';
import 'features/analytics/analytics_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/auth/password_reset_screen.dart';
import 'features/auth/register_screen.dart';
import 'features/dashboard/dashboard_screen.dart';
import 'features/goals/goals_screen.dart';
import 'features/health_logs/health_logs_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/profile/profile_screen.dart';
import 'features/reminders/reminders_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/shell/dashboard_shell.dart';
import 'features/splash/splash_screen.dart';
import 'features/tips/tips_screen.dart';
import 'state/wellness_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init();
  runApp(const ProviderScope(child: WellnessHubApp()));
}

class WellnessHubApp extends ConsumerWidget {
  const WellnessHubApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stateAsync = ref.watch(wellnessControllerProvider);

    return stateAsync.when(
      loading: () => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: const SplashLoadingView(),
      ),
      error: (error, _) => MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        home: Scaffold(
          backgroundColor: AppTheme.scaffoldColor,
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Failed to initialize app:\n$error',
                  textAlign: TextAlign.center),
            ),
          ),
        ),
      ),
      data: (state) {
        final router = GoRouter(
          initialLocation: '/splash',
          routes: [
            GoRoute(
              path: '/splash',
              builder: (context, _) => const SplashScreen(),
            ),
            GoRoute(
              path: '/onboarding',
              builder: (context, _) => const OnboardingScreen(),
            ),
            GoRoute(
              path: '/login',
              builder: (context, _) => const LoginScreen(),
            ),
            GoRoute(
              path: '/password-reset',
              builder: (context, state) => PasswordResetScreen(
                initialToken: state.uri.queryParameters['token'],
              ),
            ),
            GoRoute(
              path: '/register',
              builder: (context, _) => const RegisterScreen(),
            ),
            StatefulShellRoute.indexedStack(
              builder: (context, state, navigationShell) => DashboardShell(
                navigationShell: navigationShell,
              ),
              branches: [
                StatefulShellBranch(routes: [
                  GoRoute(
                      path: '/home',
                      builder: (_, __) => const DashboardScreen()),
                ]),
                StatefulShellBranch(routes: [
                  GoRoute(
                      path: '/activities',
                      builder: (_, __) => const ActivitiesScreen()),
                ]),
                StatefulShellBranch(routes: [
                  GoRoute(
                      path: '/goals', builder: (_, __) => const GoalsScreen()),
                ]),
                StatefulShellBranch(routes: [
                  GoRoute(
                      path: '/tips', builder: (_, __) => const TipsScreen()),
                ]),
                StatefulShellBranch(routes: [
                  GoRoute(
                      path: '/profile',
                      builder: (_, __) => const ProfileScreen()),
                ]),
              ],
            ),
            GoRoute(
                path: '/health-logs',
                builder: (_, __) => const HealthLogsScreen()),
            GoRoute(
                path: '/analytics',
                builder: (_, __) => const AnalyticsScreen()),
            GoRoute(
                path: '/reminders',
                builder: (_, __) => const RemindersScreen()),
            GoRoute(
                path: '/settings', builder: (_, __) => const SettingsScreen()),
          ],
          redirect: (context, routeState) {
            final location = routeState.uri.path;
            final isPublic = {
              '/splash',
              '/onboarding',
              '/login',
              '/password-reset',
              '/register',
            }.contains(location);

            if (!state.onboardingSeen &&
                location != '/splash' &&
                location != '/onboarding') {
              return '/onboarding';
            }

            if (state.currentUser == null && !isPublic) {
              return '/login';
            }

            if (state.currentUser != null &&
                (location == '/login' || location == '/register')) {
              return '/home';
            }

            return null;
          },
        );

        return MaterialApp.router(
          debugShowCheckedModeBanner: false,
          title: 'Wellness Hub',
          theme: AppTheme.darkTheme,
          routerConfig: router,
        );
      },
    );
  }
}
