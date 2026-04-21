import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/config.dart';
import '../core/network/api_service.dart';
import '../models/entities.dart';

final wellnessControllerProvider =
    AsyncNotifierProvider<WellnessController, WellnessState>(
        WellnessController.new);

class WellnessController extends AsyncNotifier<WellnessState> {
  static const _storageKey = 'wellness_hub_state_v1';

  late SharedPreferences _prefs;
  late ApiService _api;

  @override
  Future<WellnessState> build() async {
    _prefs = await SharedPreferences.getInstance();
    _api = ApiService(_prefs);

    final cached = await _loadCachedState();

    // If there is no token, show cached/offline state or initial.
    if (_api.token == null) {
      return cached ?? WellnessState.initial();
    }

    try {
      final remote = await _api.syncState();
      final next = _stateFromPayload(remote,
          onboardingSeen: cached?.onboardingSeen ?? true);
      await _persist(next);
      return next;
    } catch (_) {
      return cached ?? WellnessState.initial();
    }
  }

  Future<WellnessState?> _loadCachedState() async {
    final raw = _prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return null;
    return WellnessState.fromJson(raw);
  }

  Future<void> _persist(WellnessState next) async {
    await _prefs.setString(_storageKey, next.toJson());
    state = AsyncData(next);
  }

  WellnessState _stateFromPayload(Map<String, dynamic> payload,
      {bool onboardingSeen = true}) {
    final userMap = payload['user'] == null
        ? <String, dynamic>{}
        : Map<String, dynamic>.from(payload['user'] as Map);
    final user = userMap.isEmpty ? null : AppUser.fromMap(userMap);

    List<T> convert<T>(String key, T Function(Map<String, dynamic>) fromMap) {
      final list = payload[key];
      if (list is List) {
        return list
            .map((e) => fromMap(Map<String, dynamic>.from(e as Map)))
            .toList();
      }
      return <T>[];
    }

    final seedTips = WellnessState.initial().tips;

    return WellnessState(
      onboardingSeen: onboardingSeen,
      currentUser: user,
      users: user == null ? [] : [user],
      activities: convert('activities', Activity.fromMap),
      healthLogs: convert('healthLogs', HealthLog.fromMap),
      goals: convert('goals', Goal.fromMap),
      reminders: convert('reminders', Reminder.fromMap),
      tips: convert('tips', HealthTip.fromMap).isEmpty
          ? seedTips
          : convert('tips', HealthTip.fromMap),
    );
  }

  Future<void> completeOnboarding() async {
    final current = state.valueOrNull ?? WellnessState.initial();
    await _persist(current.copyWith(onboardingSeen: true));
  }

  Future<String?> login(
      {required String email, required String password}) async {
    try {
      final response = await _api.login(email: email, password: password);
      await _api.setToken(response['token'] as String);
      final next = _stateFromPayload(response, onboardingSeen: true);
      await _persist(next);
      return null;
    } catch (e) {
      return _friendlyError(e);
    }
  }

  Future<String?> register({
    required String name,
    required String email,
    required String password,
    required int age,
    required String gender,
    required double height,
    required double weight,
  }) async {
    try {
      final response = await _api.register(
        name: name,
        email: email,
        password: password,
        age: age,
        gender: gender,
        height: height,
        weight: weight,
      );
      await _api.setToken(response['token'] as String);
      final next = _stateFromPayload(response, onboardingSeen: true);
      await _persist(next);
      return null;
    } catch (e) {
      return _friendlyError(e);
    }
  }

  String _friendlyError(Object e) {
    final raw = e.toString().replaceFirst('Exception: ', '');
    if (raw.contains('SocketException')) {
      return 'Cannot reach server. Make sure the backend is running at $apiBaseUrl and the emulator is online.';
    }
    return raw;
  }

  Future<void> logout() async {
    await _api.clearToken();
    await _prefs.remove(_storageKey);
    state = AsyncData(WellnessState.initial());
  }

  double calculateBmi(double weightKg, double heightCm) {
    final heightM = heightCm / 100;
    return double.parse((weightKg / (heightM * heightM)).toStringAsFixed(2));
  }

  Future<String?> updateProfile(
      {required String name,
      required int age,
      required String gender,
      required double height,
      required double weight}) async {
    try {
      final response = await _api.updateProfile(
          name: name, age: age, gender: gender, height: height, weight: weight);
      final updatedUser =
          AppUser.fromMap(Map<String, dynamic>.from(response['user'] as Map));
      final current = state.requireValue;
      await _persist(
          current.copyWith(currentUser: updatedUser, users: [updatedUser]));
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  Future<String?> addActivity(
      {required String type,
      required int duration,
      required int steps,
      required double distance,
      required int calories,
      required String notes,
      required DateTime date}) async {
    try {
      final response = await _api.addActivity(
        type: type,
        duration: duration,
        steps: steps,
        distance: distance,
        calories: calories,
        notes: notes,
        date: date,
      );
      final activity = Activity.fromMap(
          Map<String, dynamic>.from(response['activity'] as Map));
      final current = state.requireValue;
      await _persist(
          current.copyWith(activities: [...current.activities, activity]));
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  Future<String?> deleteActivity(String id) async {
    try {
      await _api.deleteActivity(id);
      final current = state.requireValue;
      await _persist(current.copyWith(
          activities: current.activities.where((e) => e.id != id).toList()));
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  Future<String?> addHealthLog(
      {required double weight,
      required double height,
      required String notes,
      required DateTime date}) async {
    try {
      final response = await _api.addHealthLog(
          weight: weight, height: height, notes: notes, date: date);
      final log = HealthLog.fromMap(
          Map<String, dynamic>.from(response['healthLog'] as Map));
      final user =
          AppUser.fromMap(Map<String, dynamic>.from(response['user'] as Map));
      final current = state.requireValue;
      await _persist(current.copyWith(
        currentUser: user,
        users: [user],
        healthLogs: [...current.healthLogs, log],
      ));
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  Future<String?> addGoal(
      {required String title,
      required String goalType,
      required double targetValue,
      required double currentValue,
      required DateTime targetDate}) async {
    try {
      final response = await _api.addGoal(
        title: title,
        goalType: goalType,
        targetValue: targetValue,
        currentValue: currentValue,
        targetDate: targetDate,
      );
      final goal =
          Goal.fromMap(Map<String, dynamic>.from(response['goal'] as Map));
      final current = state.requireValue;
      await _persist(current.copyWith(goals: [...current.goals, goal]));
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  Future<String?> updateGoalProgress(String goalId, double currentValue) async {
    try {
      final response = await _api.updateGoal(goalId, currentValue);
      final updatedGoal =
          Goal.fromMap(Map<String, dynamic>.from(response['goal'] as Map));
      final current = state.requireValue;
      final goals = current.goals
          .map((g) => g.id == updatedGoal.id ? updatedGoal : g)
          .toList();
      await _persist(current.copyWith(goals: goals));
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  Future<String?> addReminder(
      {required String title,
      required String message,
      required String scheduledTime,
      required String repeat}) async {
    try {
      final response = await _api.addReminder(
          title: title,
          message: message,
          scheduledTime: scheduledTime,
          repeat: repeat);
      final reminder = Reminder.fromMap(
          Map<String, dynamic>.from(response['reminder'] as Map));
      final current = state.requireValue;
      await _persist(
          current.copyWith(reminders: [...current.reminders, reminder]));
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  Future<String?> toggleReminder(String id) async {
    try {
      final response = await _api.toggleReminder(id);
      final updated = Reminder.fromMap(
          Map<String, dynamic>.from(response['reminder'] as Map));
      final current = state.requireValue;
      final reminders = current.reminders
          .map((r) => r.id == updated.id ? updated : r)
          .toList();
      await _persist(current.copyWith(reminders: reminders));
      return null;
    } catch (e) {
      return e.toString().replaceFirst('Exception: ', '');
    }
  }

  List<Activity> userActivities(WellnessState state) =>
      state.currentUser == null
          ? []
          : state.activities
              .where((e) => e.userId == state.currentUser!.id)
              .toList()
        ..sort((a, b) => b.date.compareTo(a.date));

  List<HealthLog> userHealthLogs(WellnessState state) =>
      state.currentUser == null
          ? []
          : state.healthLogs
              .where((e) => e.userId == state.currentUser!.id)
              .toList()
        ..sort((a, b) => a.date.compareTo(b.date));

  List<Goal> userGoals(WellnessState state) => state.currentUser == null
      ? []
      : state.goals.where((e) => e.userId == state.currentUser!.id).toList();

  List<Reminder> userReminders(WellnessState state) => state.currentUser == null
      ? []
      : state.reminders
          .where((e) => e.userId == state.currentUser!.id)
          .toList();
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
