import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../shared/app_scaffold.dart';
import '../../shared/widgets.dart';
import '../../state/wellness_controller.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(wellnessControllerProvider).requireValue;
    final controller = ref.read(wellnessControllerProvider.notifier);
    final activities = controller.userActivities(state);
    final logs = controller.userHealthLogs(state);
    final goals = controller.userGoals(state);

    final stepBars = activities.take(7).toList().reversed.toList();
    final weightSpots = logs
        .asMap()
        .entries
        .map((e) => FlSpot(e.key.toDouble(), e.value.weight))
        .toList();
    final completed =
        goals.where((g) => g.status == 'completed').length.toDouble();
    final active = goals.where((g) => g.status == 'active').length.toDouble();

    return AppScaffold(
      title: 'Analytics',
      child: ListView(
        children: [
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Weekly steps',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 16),
                SizedBox(
                  height: 220,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      borderData: FlBorderData(show: false),
                      gridData: const FlGridData(show: false),
                      titlesData: const FlTitlesData(
                          leftTitles: AxisTitles(
                              sideTitles: SideTitles(showTitles: true))),
                      barGroups: List.generate(stepBars.length, (index) {
                        final item = stepBars[index];
                        return BarChartGroupData(x: index, barRods: [
                          BarChartRodData(
                              toY: item.steps.toDouble(),
                              color: AppColors.primary,
                              width: 18,
                              borderRadius: BorderRadius.circular(6))
                        ]);
                      }),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Weight trend',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 16),
                SizedBox(
                  height: 220,
                  child: weightSpots.isEmpty
                      ? const EmptyState(
                          title: 'No weight data',
                          message: 'Add health logs to visualize weight trend.')
                      : LineChart(
                          LineChartData(
                            borderData: FlBorderData(show: false),
                            gridData: const FlGridData(show: false),
                            titlesData: const FlTitlesData(
                                leftTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: true))),
                            lineBarsData: [
                              LineChartBarData(
                                spots: weightSpots,
                                color: AppColors.coral,
                                isCurved: true,
                                barWidth: 3,
                                dotData: const FlDotData(show: true),
                              ),
                            ],
                          ),
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SectionCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Goal status',
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 16),
                SizedBox(
                  height: 220,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: [
                        PieChartSectionData(
                            value: active == 0 && completed == 0 ? 1 : active,
                            color: AppColors.primary,
                            title: 'Active\n${active.toInt()}'),
                        PieChartSectionData(
                            value:
                                active == 0 && completed == 0 ? 0 : completed,
                            color: AppColors.coral,
                            title: 'Done\n${completed.toInt()}'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
