import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/sensors/device_step_counter.dart';
import 'wellness_controller.dart';

final automationControllerProvider =
    AsyncNotifierProvider<AutomationController, AutomationState>(
  AutomationController.new,
);

class AutomationState {
  const AutomationState({
    required this.sensorSupported,
    required this.stepsToday,
    required this.movementStatus,
    required this.sleepStartedAt,
    this.stepError,
  });

  factory AutomationState.initial({required bool sensorSupported}) =>
      AutomationState(
        sensorSupported: sensorSupported,
        stepsToday: 0,
        movementStatus: sensorSupported ? 'starting' : 'unavailable',
        sleepStartedAt: null,
      );

  final bool sensorSupported;
  final int stepsToday;
  final String movementStatus;
  final DateTime? sleepStartedAt;
  final String? stepError;

  bool get isSleeping => sleepStartedAt != null;
  int get estimatedCalories => (stepsToday * 0.04).round();

  double sleepHoursUntil(DateTime now) {
    final startedAt = sleepStartedAt;
    if (startedAt == null) return 0;
    return now.difference(startedAt).inMinutes / 60;
  }

  AutomationState copyWith({
    bool? sensorSupported,
    int? stepsToday,
    String? movementStatus,
    DateTime? sleepStartedAt,
    bool clearSleepStartedAt = false,
    String? stepError,
    bool clearStepError = false,
  }) {
    return AutomationState(
      sensorSupported: sensorSupported ?? this.sensorSupported,
      stepsToday: stepsToday ?? this.stepsToday,
      movementStatus: movementStatus ?? this.movementStatus,
      sleepStartedAt:
          clearSleepStartedAt ? null : sleepStartedAt ?? this.sleepStartedAt,
      stepError: clearStepError ? null : stepError ?? this.stepError,
    );
  }
}

class AutomationController extends AsyncNotifier<AutomationState> {
  static const _sleepStartKey = 'automation_sleep_started_at';
  static const _stepBaseDateKey = 'automation_step_base_date';
  static const _stepBaseCountKey = 'automation_step_base_count';
  static const _stepsTodayKey = 'automation_steps_today';

  late SharedPreferences _prefs;
  final _stepCounter = DeviceStepCounter();
  StreamSubscription<int>? _stepSubscription;

  @override
  Future<AutomationState> build() async {
    _prefs = await SharedPreferences.getInstance();
    ref.onDispose(() {
      _stepSubscription?.cancel();
    });

    final sleepStartRaw = _prefs.getString(_sleepStartKey);
    final sleepStartedAt =
        sleepStartRaw == null ? null : DateTime.tryParse(sleepStartRaw);
    final current = AutomationState.initial(
      sensorSupported: _stepCounter.isSupported,
    ).copyWith(
      stepsToday: _prefs.getInt(_stepsTodayKey) ?? 0,
      sleepStartedAt: sleepStartedAt,
    );

    if (_stepCounter.isSupported) {
      unawaited(_startStepStreams());
    }

    return current;
  }

  Future<String?> addWater(int milliliters) async {
    final error =
        await ref.read(wellnessControllerProvider.notifier).addVitalLog(
              category: 'hydration',
              waterMl: milliliters.toDouble(),
              notes: 'Quick water log',
              date: DateTime.now(),
            );
    return error;
  }

  Future<String?> toggleSleep() async {
    final current = state.valueOrNull;
    if (current == null) return 'Automation is still starting.';

    if (!current.isSleeping) {
      final startedAt = DateTime.now();
      await _prefs.setString(_sleepStartKey, startedAt.toIso8601String());
      state = AsyncData(current.copyWith(sleepStartedAt: startedAt));
      return null;
    }

    final startedAt = current.sleepStartedAt!;
    final endedAt = DateTime.now();
    final elapsed = endedAt.difference(startedAt);
    final hours = elapsed.inSeconds <= 0 ? 0.01 : elapsed.inSeconds / 3600;

    final error =
        await ref.read(wellnessControllerProvider.notifier).addVitalLog(
              category: 'sleep',
              sleepHours: double.parse(hours.toStringAsFixed(2)),
              notes: 'Sleep tracked from button',
              date: endedAt,
            );
    if (error != null) return error;

    await _prefs.remove(_sleepStartKey);
    state = AsyncData(current.copyWith(clearSleepStartedAt: true));
    return null;
  }

  Future<void> _startStepStreams() async {
    try {
      final stepStream = await _stepCounter.stepCountStream();
      _stepSubscription = stepStream.listen(
        _handleSensorSteps,
        onError: (Object error) => _setStepError(error.toString()),
      );
    } catch (error) {
      _setStepError(error.toString());
    }
  }

  Future<void> _handleSensorSteps(int totalSinceBoot) async {
    final todayKey = _todayKey();
    final baseDate = _prefs.getString(_stepBaseDateKey);
    var baseCount = _prefs.getInt(_stepBaseCountKey);

    if (baseDate != todayKey ||
        baseCount == null ||
        totalSinceBoot < baseCount) {
      baseCount = totalSinceBoot;
      await _prefs.setString(_stepBaseDateKey, todayKey);
      await _prefs.setInt(_stepBaseCountKey, baseCount);
    }

    final stepsToday = (totalSinceBoot - baseCount).clamp(0, 100000).toInt();
    await _prefs.setInt(_stepsTodayKey, stepsToday);
    final current = state.valueOrNull;
    if (current != null) {
      state = AsyncData(
        current.copyWith(
          stepsToday: stepsToday,
          movementStatus: current.movementStatus == 'starting' ? 'ready' : null,
          clearStepError: true,
        ),
      );
    }
  }

  void _setStepError(String message) {
    final current = state.valueOrNull;
    if (current != null) {
      state = AsyncData(
        current.copyWith(movementStatus: 'unavailable', stepError: message),
      );
    }
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }
}
