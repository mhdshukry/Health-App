import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/app_scaffold.dart';
import '../../shared/health_metrics.dart';
import '../../shared/health_rings.dart';
import '../../shared/widgets.dart';
import '../../state/automation_controller.dart';
import '../../state/wellness_controller.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(wellnessControllerProvider).requireValue;
    final automationAsync = ref.watch(automationControllerProvider);
    final automation = automationAsync.valueOrNull;
    final controller = ref.read(wellnessControllerProvider.notifier);
    final user = state.currentUser!;
    final activities = controller.userActivities(state);
    final logs = controller.userHealthLogs(state);
    final goals = controller.userGoals(state);
    final reminders = controller.userReminders(state);
    final vitals = controller.userVitals(state);
    final today = dailyHealthSummary(
      activities: activities,
      vitals: vitals,
      day: DateTime.now(),
    );
    final autoSteps = automation?.stepsToday ?? 0;
    final autoCalories = automation?.estimatedCalories ?? 0;
    final displayedSteps = today.steps + autoSteps;
    final displayedCalories = today.calories + autoCalories;
    final latestBmi = logs.isEmpty
        ? controller.calculateBmi(user.weight, user.height)
        : logs.last.bmi;

    return AppScaffold(
      title: 'Wellness Dashboard',
      child: ListView(
        children: [
          Text('Hi ${user.name.split(' ').first},',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 6),
          Text('Your health snapshot looks good today.',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 18),
          HealthRingsCard(
            title: 'Today',
            rings: [
              HealthRingData(
                label: 'Move',
                value: displayedCalories.toDouble(),
                target: 500,
                unit: 'kcal',
                color: AppColors.coral,
                icon: Icons.local_fire_department_outlined,
              ),
              HealthRingData(
                label: 'Steps',
                value: displayedSteps.toDouble(),
                target: 8000,
                unit: 'steps',
                color: AppColors.primary,
                icon: Icons.directions_walk_outlined,
              ),
              HealthRingData(
                label: 'Sleep',
                value: today.sleepHours,
                target: 8,
                unit: 'h',
                color: const Color(0xFF6EA8FE),
                icon: Icons.bedtime_outlined,
              ),
              HealthRingData(
                label: 'Water',
                value: today.waterMl,
                target: 2000,
                unit: 'ml',
                color: const Color(0xFF55D6BE),
                icon: Icons.local_drink_outlined,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _AutomationCard(
            automation: automation,
            isLoading: automationAsync.isLoading,
            onAddWater: (amount) async {
              final error = await ref
                  .read(automationControllerProvider.notifier)
                  .addWater(amount);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(error ?? 'Added $amount ml water.'),
                  ),
                );
              }
            },
            onToggleSleep: () async {
              final wasSleeping = ref
                      .read(automationControllerProvider)
                      .valueOrNull
                      ?.isSleeping ??
                  false;
              final error = await ref
                  .read(automationControllerProvider.notifier)
                  .toggleSleep();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(error ??
                        (wasSleeping
                            ? 'Sleep saved automatically.'
                            : 'Sleep timer started.')),
                  ),
                );
              }
            },
          ),
          const SizedBox(height: 18),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.25,
            children: [
              StatTile(
                  title: 'Current weight',
                  value: '${user.weight.toStringAsFixed(1)} kg',
                  subtitle: 'Latest profile value'),
              StatTile(
                  title: 'BMI',
                  value: latestBmi.toStringAsFixed(2),
                  subtitle: _bmiLabel(latestBmi),
                  accent: AppColors.coral),
              StatTile(
                  title: 'Active goals',
                  value: '${goals.where((g) => g.status == 'active').length}',
                  subtitle:
                      '${reminders.where((r) => r.isActive).length} reminders active'),
              StatTile(
                  title: 'Wellness logs',
                  value: '${vitals.length}',
                  subtitle: 'Vitals, sleep, mood'),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _QuickAction(
                  label: 'Add activity',
                  icon: Icons.add_circle_outline,
                  onTap: () => context.go('/activities')),
              _QuickAction(
                  label: 'Log health',
                  icon: Icons.monitor_heart_outlined,
                  onTap: () => context.go('/health-logs')),
              _QuickAction(
                  label: 'Vitals',
                  icon: Icons.favorite_border,
                  onTap: () => context.go('/vitals')),
              _QuickAction(
                  label: 'View analytics',
                  icon: Icons.analytics_outlined,
                  onTap: () => context.go('/analytics')),
              _QuickAction(
                  label: 'Reminders',
                  icon: Icons.notifications_outlined,
                  onTap: () => context.go('/reminders')),
            ],
          ),
          const SizedBox(height: 18),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Recent activities',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 14),
                if (activities.isEmpty)
                  const EmptyState(
                      title: 'No activities yet',
                      message:
                          'Start with a walk, run, workout, or yoga session.')
                else
                  ...activities.take(3).map(
                        (activity) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: CircleAvatar(
                              backgroundColor: AppColors.primary,
                              child: Icon(_activityIcon(activity.type),
                                  color: Colors.black)),
                          title: Text(activity.type[0].toUpperCase() +
                              activity.type.substring(1)),
                          subtitle: Text(
                              '${activity.duration} min · ${activity.steps} steps'),
                          trailing: Text('${activity.calories} kcal'),
                        ),
                      ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tip of the day',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                Text(state.tips.first.title,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontSize: 18)),
                const SizedBox(height: 8),
                Text(state.tips.first.summary),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _bmiLabel(double bmi) {
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  static IconData _activityIcon(String type) {
    switch (type) {
      case 'running':
        return Icons.directions_run;
      case 'cycling':
        return Icons.pedal_bike;
      case 'workout':
        return Icons.fitness_center;
      case 'yoga':
        return Icons.self_improvement;
      case 'stretching':
        return Icons.accessibility_new;
      default:
        return Icons.directions_walk;
    }
  }
}

class _AutomationCard extends StatelessWidget {
  const _AutomationCard({
    required this.automation,
    required this.isLoading,
    required this.onAddWater,
    required this.onToggleSleep,
  });

  final AutomationState? automation;
  final bool isLoading;
  final ValueChanged<int> onAddWater;
  final VoidCallback onToggleSleep;

  @override
  Widget build(BuildContext context) {
    final state = automation;
    final isSleeping = state?.isSleeping ?? false;
    final sleepHours = state?.sleepHoursUntil(DateTime.now()) ?? 0;

    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Quick tracking',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.cardAlt,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.directions_walk_outlined,
                  color: state?.sensorSupported == true
                      ? AppColors.primary
                      : AppColors.muted,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${state?.stepsToday ?? 0} auto steps',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _stepStatusText(state, isLoading),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                Text('${state?.estimatedCalories ?? 0} kcal'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                onPressed: () => onAddWater(250),
                icon: const Icon(Icons.local_drink_outlined),
                label: const Text('+250 ml'),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                ),
                onPressed: () => onAddWater(500),
                icon: const Icon(Icons.water_drop_outlined),
                label: const Text('+500 ml'),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 44),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  backgroundColor:
                      isSleeping ? AppColors.coral : AppColors.primary,
                ),
                onPressed: onToggleSleep,
                icon: Icon(isSleeping
                    ? Icons.wb_sunny_outlined
                    : Icons.bedtime_outlined),
                label: Text(
                  isSleeping
                      ? 'Wake up (${sleepHours.toStringAsFixed(1)}h)'
                      : 'Sleep',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _stepStatusText(AutomationState? state, bool isLoading) {
    if (isLoading) return 'Starting step sensor...';
    if (state == null) return 'Starting automation...';
    if (state.stepError != null) {
      return 'Step sensor unavailable. You can still log activity manually.';
    }
    if (!state.sensorSupported) {
      return 'Auto steps work on Android/iOS. Web needs manual activity logs.';
    }
    return 'Movement status: ${state.movementStatus}';
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction(
      {required this.label, required this.icon, required this.onTap});
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(label),
          ],
        ),
      ),
    );
  }
}
