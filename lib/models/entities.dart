import 'dart:convert';

class AppUser {
  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.password,
    required this.age,
    required this.gender,
    required this.height,
    required this.weight,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String email;
  final String password;
  final int age;
  final String gender;
  final double height;
  final double weight;
  final String createdAt;

  AppUser copyWith({
    String? name,
    String? email,
    String? password,
    int? age,
    String? gender,
    double? height,
    double? weight,
  }) =>
      AppUser(
        id: id,
        name: name ?? this.name,
        email: email ?? this.email,
        password: password ?? this.password,
        age: age ?? this.age,
        gender: gender ?? this.gender,
        height: height ?? this.height,
        weight: weight ?? this.weight,
        createdAt: createdAt,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'email': email,
        'password': password,
        'age': age,
        'gender': gender,
        'height': height,
        'weight': weight,
        'createdAt': createdAt,
      };

  factory AppUser.fromMap(Map<String, dynamic> map) => AppUser(
        id: map['id'],
        name: map['name'],
        email: map['email'],
        password: map['password'] ?? '',
        age: (map['age'] as num).toInt(),
        gender: map['gender'],
        height: (map['height'] as num).toDouble(),
        weight: (map['weight'] as num).toDouble(),
        createdAt: map['createdAt'],
      );
}

class Activity {
  Activity({
    required this.id,
    required this.userId,
    required this.type,
    required this.duration,
    required this.steps,
    required this.distance,
    required this.calories,
    required this.notes,
    required this.date,
  });

  final String id;
  final String userId;
  final String type;
  final int duration;
  final int steps;
  final double distance;
  final int calories;
  final String notes;
  final String date;

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'type': type,
        'duration': duration,
        'steps': steps,
        'distance': distance,
        'calories': calories,
        'notes': notes,
        'date': date,
      };

  factory Activity.fromMap(Map<String, dynamic> map) => Activity(
        id: map['id'],
        userId: map['userId'],
        type: map['type'],
        duration: (map['duration'] as num).toInt(),
        steps: (map['steps'] as num).toInt(),
        distance: (map['distance'] as num).toDouble(),
        calories: (map['calories'] as num).toInt(),
        notes: map['notes'] ?? '',
        date: map['date'],
      );
}

class HealthLog {
  HealthLog({
    required this.id,
    required this.userId,
    required this.weight,
    required this.height,
    required this.bmi,
    required this.notes,
    required this.date,
  });

  final String id;
  final String userId;
  final double weight;
  final double height;
  final double bmi;
  final String notes;
  final String date;

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'weight': weight,
        'height': height,
        'bmi': bmi,
        'notes': notes,
        'date': date,
      };

  factory HealthLog.fromMap(Map<String, dynamic> map) => HealthLog(
        id: map['id'],
        userId: map['userId'],
        weight: (map['weight'] as num).toDouble(),
        height: (map['height'] as num).toDouble(),
        bmi: (map['bmi'] as num).toDouble(),
        notes: map['notes'] ?? '',
        date: map['date'],
      );
}

class Goal {
  Goal({
    required this.id,
    required this.userId,
    required this.title,
    required this.goalType,
    required this.targetValue,
    required this.currentValue,
    required this.startDate,
    required this.targetDate,
    required this.status,
  });

  final String id;
  final String userId;
  final String title;
  final String goalType;
  final double targetValue;
  final double currentValue;
  final String startDate;
  final String targetDate;
  final String status;

  double get progress => targetValue == 0
      ? 0
      : (currentValue / targetValue).clamp(0, 1).toDouble();

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'title': title,
        'goalType': goalType,
        'targetValue': targetValue,
        'currentValue': currentValue,
        'startDate': startDate,
        'targetDate': targetDate,
        'status': status,
      };

  factory Goal.fromMap(Map<String, dynamic> map) => Goal(
        id: map['id'],
        userId: map['userId'],
        title: map['title'],
        goalType: map['goalType'],
        targetValue: (map['targetValue'] as num).toDouble(),
        currentValue: (map['currentValue'] as num).toDouble(),
        startDate: map['startDate'],
        targetDate: map['targetDate'],
        status: map['status'],
      );
}

class Reminder {
  Reminder({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    required this.scheduledTime,
    required this.repeat,
    required this.isActive,
  });

  final String id;
  final String userId;
  final String title;
  final String message;
  final String scheduledTime;
  final String repeat;
  final bool isActive;

  Reminder copyWith({bool? isActive}) => Reminder(
        id: id,
        userId: userId,
        title: title,
        message: message,
        scheduledTime: scheduledTime,
        repeat: repeat,
        isActive: isActive ?? this.isActive,
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'title': title,
        'message': message,
        'scheduledTime': scheduledTime,
        'repeat': repeat,
        'isActive': isActive,
      };

  factory Reminder.fromMap(Map<String, dynamic> map) => Reminder(
        id: map['id'],
        userId: map['userId'],
        title: map['title'],
        message: map['message'],
        scheduledTime: map['scheduledTime'],
        repeat: map['repeat'],
        isActive: map['isActive'] as bool,
      );
}

class HealthTip {
  HealthTip({
    required this.id,
    required this.title,
    required this.category,
    required this.summary,
    required this.content,
    required this.source,
  });

  final String id;
  final String title;
  final String category;
  final String summary;
  final String content;
  final String source;

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'category': category,
        'summary': summary,
        'content': content,
        'source': source,
      };

  factory HealthTip.fromMap(Map<String, dynamic> map) => HealthTip(
        id: map['id'],
        title: map['title'],
        category: map['category'],
        summary: map['summary'],
        content: map['content'],
        source: map['source'],
      );
}

class WellnessState {
  WellnessState({
    required this.onboardingSeen,
    required this.currentUser,
    required this.users,
    required this.activities,
    required this.healthLogs,
    required this.goals,
    required this.reminders,
    required this.tips,
  });

  final bool onboardingSeen;
  final AppUser? currentUser;
  final List<AppUser> users;
  final List<Activity> activities;
  final List<HealthLog> healthLogs;
  final List<Goal> goals;
  final List<Reminder> reminders;
  final List<HealthTip> tips;

  factory WellnessState.initial() => WellnessState(
        onboardingSeen: false,
        currentUser: null,
        users: [],
        activities: [],
        healthLogs: [],
        goals: [],
        reminders: [],
        tips: _seedTips,
      );

  WellnessState copyWith({
    bool? onboardingSeen,
    AppUser? currentUser,
    bool clearUser = false,
    List<AppUser>? users,
    List<Activity>? activities,
    List<HealthLog>? healthLogs,
    List<Goal>? goals,
    List<Reminder>? reminders,
    List<HealthTip>? tips,
  }) =>
      WellnessState(
        onboardingSeen: onboardingSeen ?? this.onboardingSeen,
        currentUser: clearUser ? null : currentUser ?? this.currentUser,
        users: users ?? this.users,
        activities: activities ?? this.activities,
        healthLogs: healthLogs ?? this.healthLogs,
        goals: goals ?? this.goals,
        reminders: reminders ?? this.reminders,
        tips: tips ?? this.tips,
      );

  Map<String, dynamic> toMap() => {
        'onboardingSeen': onboardingSeen,
        'currentUserId': currentUser?.id,
        'users': users.map((e) => e.toMap()).toList(),
        'activities': activities.map((e) => e.toMap()).toList(),
        'healthLogs': healthLogs.map((e) => e.toMap()).toList(),
        'goals': goals.map((e) => e.toMap()).toList(),
        'reminders': reminders.map((e) => e.toMap()).toList(),
        'tips': tips.map((e) => e.toMap()).toList(),
      };

  String toJson() => jsonEncode(toMap());

  factory WellnessState.fromJson(String source) {
    final map = jsonDecode(source) as Map<String, dynamic>;
    final users = ((map['users'] ?? []) as List)
        .map((e) => AppUser.fromMap(Map<String, dynamic>.from(e)))
        .toList();
    final currentUserId = map['currentUserId'];
    return WellnessState(
      onboardingSeen: map['onboardingSeen'] ?? false,
      currentUser: users
          .where((u) => u.id == currentUserId)
          .cast<AppUser?>()
          .firstOrNull,
      users: users,
      activities: ((map['activities'] ?? []) as List)
          .map((e) => Activity.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      healthLogs: ((map['healthLogs'] ?? []) as List)
          .map((e) => HealthLog.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      goals: ((map['goals'] ?? []) as List)
          .map((e) => Goal.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      reminders: ((map['reminders'] ?? []) as List)
          .map((e) => Reminder.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
      tips: ((map['tips'] ?? []) as List)
          .map((e) => HealthTip.fromMap(Map<String, dynamic>.from(e)))
          .toList(),
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}

final List<HealthTip> _seedTips = [
  HealthTip(
    id: 'tip-1',
    title: 'Stay Hydrated',
    category: 'Hydration',
    summary: 'Aim for regular water intake throughout the day.',
    content:
        'Hydration supports circulation, temperature regulation, and exercise performance. Start the day with water and keep a bottle nearby.',
    source: 'Wellness Hub Editorial',
  ),
  HealthTip(
    id: 'tip-2',
    title: 'Build Small Daily Movement',
    category: 'Fitness',
    summary: 'Short walks and stretching sessions improve consistency.',
    content:
        'Instead of waiting for a perfect workout, stack 10 to 15 minute movement blocks. Consistency drives better long-term health outcomes.',
    source: 'Wellness Hub Editorial',
  ),
  HealthTip(
    id: 'tip-3',
    title: 'Protect Your Sleep Window',
    category: 'Sleep',
    summary: 'Sleep quality directly affects recovery and appetite control.',
    content:
        'Try a consistent wind-down routine, reduce late caffeine, and keep screens lower before sleep to improve recovery and mood.',
    source: 'Wellness Hub Editorial',
  ),
  HealthTip(
    id: 'tip-4',
    title: 'Use Goals You Can Measure',
    category: 'Productivity',
    summary: 'Specific, measurable goals improve adherence.',
    content:
        'Choose goals like 8,000 steps per day or 4 workouts this week instead of vague goals. Measuring progress keeps motivation visible.',
    source: 'Wellness Hub Editorial',
  ),
];
