import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/app_scaffold.dart';
import '../../shared/widgets.dart';
import '../../state/wellness_controller.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(wellnessControllerProvider).requireValue;
    final controller = ref.read(wellnessControllerProvider.notifier);
    final user = state.currentUser!;
    final activities = controller.userActivities(state);
    final logs = controller.userHealthLogs(state);
    final goals = controller.userGoals(state);
    final reminders = controller.userReminders(state);
    final latestBmi = logs.isEmpty ? controller.calculateBmi(user.weight, user.height) : logs.last.bmi;
    final stepsToday = activities.where((a) => DateTime.parse(a.date).day == DateTime.now().day && DateTime.parse(a.date).month == DateTime.now().month && DateTime.parse(a.date).year == DateTime.now().year).fold<int>(0, (sum, item) => sum + item.steps);

    return AppScaffold(
      title: 'Wellness Dashboard',
      child: ListView(
        children: [
          Text('Hi ${user.name.split(' ').first},', style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 6),
          Text('Your health snapshot looks good today.', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 18),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.25,
            children: [
              StatTile(title: 'Steps today', value: '$stepsToday', subtitle: 'Keep moving'),
              StatTile(title: 'Current weight', value: '${user.weight.toStringAsFixed(1)} kg', subtitle: 'Latest profile value'),
              StatTile(title: 'BMI', value: latestBmi.toStringAsFixed(2), subtitle: _bmiLabel(latestBmi), accent: AppColors.coral),
              StatTile(title: 'Active goals', value: '${goals.where((g) => g.status == 'active').length}', subtitle: '${reminders.where((r) => r.isActive).length} reminders active'),
            ],
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _QuickAction(label: 'Add activity', icon: Icons.add_circle_outline, onTap: () => context.go('/activities')),
              _QuickAction(label: 'Log health', icon: Icons.monitor_heart_outlined, onTap: () => context.go('/health-logs')),
              _QuickAction(label: 'View analytics', icon: Icons.analytics_outlined, onTap: () => context.go('/analytics')),
              _QuickAction(label: 'Reminders', icon: Icons.notifications_outlined, onTap: () => context.go('/reminders')),
            ],
          ),
          const SizedBox(height: 18),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Recent activities', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 14),
                if (activities.isEmpty)
                  const EmptyState(title: 'No activities yet', message: 'Start with a walk, run, workout, or yoga session.')
                else
                  ...activities.take(3).map(
                    (activity) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(backgroundColor: AppColors.primary, child: Icon(_activityIcon(activity.type), color: Colors.black)),
                      title: Text(activity.type[0].toUpperCase() + activity.type.substring(1)),
                      subtitle: Text('${activity.duration} min · ${activity.steps} steps'),
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
                Text('Tip of the day', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 10),
                Text(state.tips.first.title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontSize: 18)),
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

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.label, required this.icon, required this.onTap});
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
