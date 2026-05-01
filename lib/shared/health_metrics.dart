import '../models/entities.dart';

class DailyHealthSummary {
  const DailyHealthSummary({
    required this.steps,
    required this.calories,
    required this.sleepHours,
    required this.waterMl,
  });

  final int steps;
  final int calories;
  final double sleepHours;
  final double waterMl;
}

bool isSameLocalDay(String iso, DateTime day) {
  final value = DateTime.parse(iso).toLocal();
  return value.year == day.year &&
      value.month == day.month &&
      value.day == day.day;
}

DailyHealthSummary dailyHealthSummary({
  required List<Activity> activities,
  required List<VitalLog> vitals,
  required DateTime day,
}) {
  final dayActivities =
      activities.where((item) => isSameLocalDay(item.date, day));
  final dayVitals = vitals.where((item) => isSameLocalDay(item.date, day));

  return DailyHealthSummary(
    steps: dayActivities.fold<int>(0, (sum, item) => sum + item.steps),
    calories: dayActivities.fold<int>(0, (sum, item) => sum + item.calories),
    sleepHours: _vitalTotal(dayVitals, 'sleep', (item) => item.sleepHours),
    waterMl: _vitalTotal(dayVitals, 'hydration', (item) => item.waterMl),
  );
}

List<double> dailyActivityTotals(
  List<Activity> activities,
  int Function(Activity item) valueOf, {
  int days = 7,
  DateTime? endingOn,
}) {
  final today = endingOn ?? DateTime.now();
  return List.generate(days, (index) {
    final day = DateTime(today.year, today.month, today.day)
        .subtract(Duration(days: days - 1 - index));
    return activities
        .where((item) => isSameLocalDay(item.date, day))
        .fold<double>(0, (sum, item) => sum + valueOf(item));
  });
}

double averageActiveDaySteps(List<Activity> activities) {
  final totals = dailyActivityTotals(activities, (item) => item.steps);
  final activeDays = totals.where((value) => value > 0).toList();
  if (activeDays.isEmpty) return 0;
  return activeDays.reduce((a, b) => a + b) / activeDays.length;
}

double _vitalTotal(
  Iterable<VitalLog> vitals,
  String category,
  double? Function(VitalLog item) valueOf,
) {
  return vitals
      .where((item) => item.category == category)
      .fold<double>(0, (sum, item) => sum + (valueOf(item) ?? 0));
}
