import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../models/entities.dart';
import '../../shared/app_scaffold.dart';
import '../../shared/health_metrics.dart';
import '../../shared/health_rings.dart';
import '../../shared/widgets.dart';
import '../../state/automation_controller.dart';
import '../../state/wellness_controller.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(wellnessControllerProvider).requireValue;
    final automation = ref.watch(automationControllerProvider).valueOrNull;
    final controller = ref.read(wellnessControllerProvider.notifier);
    final activities = controller.userActivities(state);
    final logs = controller.userHealthLogs(state);
    final goals = controller.userGoals(state);
    final vitals = controller.userVitals(state);

    final today = dailyHealthSummary(
      activities: activities,
      vitals: vitals,
      day: DateTime.now(),
    );
    final displayedSteps = today.steps + (automation?.stepsToday ?? 0);
    final displayedCalories =
        today.calories + (automation?.estimatedCalories ?? 0);
    final activeGoals = goals.where((goal) => goal.status == 'active').length;
    final completedGoals =
        goals.where((goal) => goal.status == 'completed').length;

    return AppScaffold(
      title: 'Analytics',
      child: ListView(
        children: [
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
          GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 1.28,
            children: [
              StatTile(
                title: 'Active goals',
                value: '$activeGoals',
                subtitle: '$completedGoals completed',
              ),
              StatTile(
                title: 'Avg steps',
                value: averageActiveDaySteps(activities).toStringAsFixed(0),
                subtitle: 'Last 7 active days',
                accent: AppColors.coral,
              ),
              StatTile(
                title: 'Latest BP',
                value: _latestBloodPressure(vitals),
                subtitle: 'Blood pressure',
              ),
              StatTile(
                title: 'Latest mood',
                value: _latestMood(vitals),
                subtitle: 'Wellness check-in',
                accent: const Color(0xFF6EA8FE),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _ChartCard(
            title: 'Steps trend',
            subtitle: 'Last 7 days',
            child: _BarTrend(
              groups: dailyActivityTotals(activities, (item) => item.steps),
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 14),
          _ChartCard(
            title: 'Weight trend',
            subtitle: 'Health log history',
            child: _LineTrend(
              spots: _spotsFromHealthLogs(logs, (item) => item.weight),
              color: AppColors.coral,
              emptyTitle: 'No weight data',
              emptyMessage: 'Add health logs to visualize weight changes.',
            ),
          ),
          const SizedBox(height: 14),
          _ChartCard(
            title: 'Blood pressure',
            subtitle: 'Systolic and diastolic',
            child: _BloodPressureTrend(vitals: vitals),
          ),
          const SizedBox(height: 14),
          _ChartCard(
            title: 'Heart and glucose',
            subtitle: 'Vital readings',
            child: _DualVitalTrend(
              vitals: vitals,
              firstCategory: 'heart_rate',
              firstValue: (item) => item.heartRate,
              firstColor: AppColors.primary,
              secondCategory: 'blood_glucose',
              secondValue: (item) => item.bloodGlucose,
              secondColor: AppColors.coral,
            ),
          ),
          const SizedBox(height: 14),
          _ChartCard(
            title: 'Sleep and hydration',
            subtitle: 'Daily wellness signals',
            child: _DualVitalTrend(
              vitals: vitals,
              firstCategory: 'sleep',
              firstValue: (item) => item.sleepHours,
              firstColor: const Color(0xFF6EA8FE),
              secondCategory: 'hydration',
              secondValue: (item) =>
                  item.waterMl == null ? null : item.waterMl! / 1000,
              secondColor: const Color(0xFF55D6BE),
            ),
          ),
        ],
      ),
    );
  }

  static List<FlSpot> _spotsFromHealthLogs(
    List<HealthLog> logs,
    double Function(HealthLog item) valueOf,
  ) {
    final recent = logs.length > 14 ? logs.sublist(logs.length - 14) : logs;
    return recent
        .asMap()
        .entries
        .map((entry) => FlSpot(entry.key.toDouble(), valueOf(entry.value)))
        .toList();
  }

  static List<FlSpot> _spotsFromVitals(
    List<VitalLog> vitals,
    String category,
    double? Function(VitalLog item) valueOf,
  ) {
    final filtered = vitals
        .where((item) => item.category == category && valueOf(item) != null)
        .toList()
        .reversed
        .take(14)
        .toList()
        .reversed
        .toList();
    return filtered
        .asMap()
        .entries
        .map((entry) => FlSpot(entry.key.toDouble(), valueOf(entry.value)!))
        .toList();
  }

  static String _latestBloodPressure(List<VitalLog> vitals) {
    final item = vitals.cast<VitalLog?>().firstWhere(
          (vital) =>
              vital?.category == 'blood_pressure' &&
              vital?.systolic != null &&
              vital?.diastolic != null,
          orElse: () => null,
        );
    if (item == null) return '--/--';
    return '${item.systolic!.toStringAsFixed(0)}/${item.diastolic!.toStringAsFixed(0)}';
  }

  static String _latestMood(List<VitalLog> vitals) {
    final item = vitals.cast<VitalLog?>().firstWhere(
          (vital) => vital?.category == 'mood' && vital?.mood != null,
          orElse: () => null,
        );
    return item?.mood ?? '-';
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 16),
          SizedBox(height: 220, child: child),
        ],
      ),
    );
  }
}

class _BarTrend extends StatelessWidget {
  const _BarTrend({required this.groups, required this.color});

  final List<double> groups;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final maxValue = groups.isEmpty ? 1.0 : groups.reduce(math.max);
    return BarChart(
      BarChartData(
        maxY: math.max(maxValue * 1.2, 1),
        alignment: BarChartAlignment.spaceAround,
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => const FlLine(
            color: AppColors.border,
            strokeWidth: 1,
          ),
        ),
        titlesData: const FlTitlesData(
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 42),
          ),
        ),
        barGroups: List.generate(groups.length, (index) {
          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: groups[index],
                color: color,
                width: 18,
                borderRadius: BorderRadius.circular(8),
                backDrawRodData: BackgroundBarChartRodData(
                  show: true,
                  toY: math.max(maxValue * 1.2, 1),
                  color: AppColors.cardAlt,
                ),
              ),
            ],
          );
        }),
      ),
    );
  }
}

class _LineTrend extends StatelessWidget {
  const _LineTrend({
    required this.spots,
    required this.color,
    required this.emptyTitle,
    required this.emptyMessage,
  });

  final List<FlSpot> spots;
  final Color color;
  final String emptyTitle;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (spots.isEmpty) {
      return EmptyState(title: emptyTitle, message: emptyMessage);
    }
    final values = spots.map((spot) => spot.y).toList();
    final minY = values.reduce(math.min);
    final maxY = values.reduce(math.max);
    final padding = math.max((maxY - minY) * 0.2, 1);
    return LineChart(
      LineChartData(
        minY: minY - padding,
        maxY: maxY + padding,
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => const FlLine(
            color: AppColors.border,
            strokeWidth: 1,
          ),
        ),
        titlesData: const FlTitlesData(
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 42),
          ),
        ),
        lineTouchData: const LineTouchData(enabled: true),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            color: color,
            isCurved: true,
            barWidth: 4,
            isStrokeCapRound: true,
            belowBarData: BarAreaData(
              show: true,
              color: color.withOpacity(0.14),
            ),
            dotData: FlDotData(
              getDotPainter: (spot, percent, barData, index) =>
                  FlDotCirclePainter(
                radius: 4,
                color: color,
                strokeWidth: 2,
                strokeColor: AppColors.background,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BloodPressureTrend extends StatelessWidget {
  const _BloodPressureTrend({required this.vitals});

  final List<VitalLog> vitals;

  @override
  Widget build(BuildContext context) {
    final systolic = AnalyticsScreen._spotsFromVitals(
      vitals,
      'blood_pressure',
      (item) => item.systolic,
    );
    final diastolic = AnalyticsScreen._spotsFromVitals(
      vitals,
      'blood_pressure',
      (item) => item.diastolic,
    );
    if (systolic.isEmpty && diastolic.isEmpty) {
      return const EmptyState(
        title: 'No blood pressure data',
        message: 'Add blood pressure readings from Vitals & Wellness.',
      );
    }
    return _MultiLineChart(
      series: [
        _Series(spots: systolic, color: AppColors.coral),
        _Series(spots: diastolic, color: AppColors.primary),
      ],
    );
  }
}

class _DualVitalTrend extends StatelessWidget {
  const _DualVitalTrend({
    required this.vitals,
    required this.firstCategory,
    required this.firstValue,
    required this.firstColor,
    required this.secondCategory,
    required this.secondValue,
    required this.secondColor,
  });

  final List<VitalLog> vitals;
  final String firstCategory;
  final double? Function(VitalLog item) firstValue;
  final Color firstColor;
  final String secondCategory;
  final double? Function(VitalLog item) secondValue;
  final Color secondColor;

  @override
  Widget build(BuildContext context) {
    final first =
        AnalyticsScreen._spotsFromVitals(vitals, firstCategory, firstValue);
    final second =
        AnalyticsScreen._spotsFromVitals(vitals, secondCategory, secondValue);
    if (first.isEmpty && second.isEmpty) {
      return EmptyState(
        title: 'No ${firstCategory.replaceAll('_', ' ')} data',
        message: 'Add readings from Vitals & Wellness to unlock this chart.',
      );
    }
    return _MultiLineChart(
      series: [
        _Series(spots: first, color: firstColor),
        _Series(spots: second, color: secondColor),
      ],
    );
  }
}

class _MultiLineChart extends StatelessWidget {
  const _MultiLineChart({required this.series});

  final List<_Series> series;

  @override
  Widget build(BuildContext context) {
    final allSpots = series.expand((item) => item.spots).toList();
    if (allSpots.isEmpty) return const SizedBox.shrink();
    final values = allSpots.map((spot) => spot.y).toList();
    final minY = values.reduce(math.min);
    final maxY = values.reduce(math.max);
    final padding = math.max((maxY - minY) * 0.2, 1);
    return LineChart(
      LineChartData(
        minY: minY - padding,
        maxY: maxY + padding,
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => const FlLine(
            color: AppColors.border,
            strokeWidth: 1,
          ),
        ),
        titlesData: const FlTitlesData(
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(showTitles: true, reservedSize: 42),
          ),
        ),
        lineBarsData: series
            .where((item) => item.spots.isNotEmpty)
            .map(
              (item) => LineChartBarData(
                spots: item.spots,
                color: item.color,
                isCurved: true,
                barWidth: 4,
                isStrokeCapRound: true,
                dotData: const FlDotData(show: false),
                belowBarData: BarAreaData(
                  show: true,
                  color: item.color.withOpacity(0.08),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _Series {
  const _Series({required this.spots, required this.color});

  final List<FlSpot> spots;
  final Color color;
}
