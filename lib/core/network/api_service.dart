import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';

class ApiService {
  ApiService(this._prefs) {
    _token = null;
    _refreshToken = null;
  }

  static const _tokenKey = 'auth_token';
  static const _refreshTokenKey = 'refresh_token';
  final SharedPreferences _prefs;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final http.Client _client = http.Client();
  String? _token;
  String? _refreshToken;

  String? get token => _token;
  String? get refreshToken => _refreshToken;

  Future<void> init() async {
    _token = await _secureStorage.read(key: _tokenKey);
    _refreshToken = await _secureStorage.read(key: _refreshTokenKey);

    if (_token == null) {
      final legacy = _prefs.getString(_tokenKey);
      if (legacy != null && legacy.isNotEmpty) {
        _token = legacy;
        await _secureStorage.write(key: _tokenKey, value: legacy);
        await _prefs.remove(_tokenKey);
      }
    }
  }

  Future<void> setAuthTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    _token = accessToken;
    _refreshToken = refreshToken;
    await _secureStorage.write(key: _tokenKey, value: accessToken);
    await _secureStorage.write(key: _refreshTokenKey, value: refreshToken);
  }

  Future<void> clearAuthTokens() async {
    _token = null;
    _refreshToken = null;
    await _secureStorage.delete(key: _tokenKey);
    await _secureStorage.delete(key: _refreshTokenKey);
    await _prefs.remove(_tokenKey);
  }

  Uri _uri(String path) => Uri.parse('$apiBaseUrl$path');

  String _utcIso(DateTime value) => value.toUtc().toIso8601String();

  Future<Map<String, dynamic>> _request(
    String path, {
    String method = 'GET',
    Map<String, dynamic>? body,
    bool retryOnAuth = true,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      if (_token != null) 'Authorization': 'Bearer $_token',
    };

    late http.Response response;
    final uri = _uri(path);
    switch (method) {
      case 'POST':
        response = await _client.post(uri,
            headers: headers, body: body == null ? null : jsonEncode(body));
        break;
      case 'PUT':
        response = await _client.put(uri,
            headers: headers, body: body == null ? null : jsonEncode(body));
        break;
      case 'PATCH':
        response = await _client.patch(uri,
            headers: headers, body: body == null ? null : jsonEncode(body));
        break;
      case 'DELETE':
        response = await _client.delete(uri, headers: headers);
        break;
      default:
        response = await _client.get(uri, headers: headers);
    }

    if (response.body.isEmpty) {
      if (response.statusCode == 401 && retryOnAuth) {
        final refreshed = await _refreshAccessToken();
        if (refreshed) {
          return _request(path, method: method, body: body, retryOnAuth: false);
        }
      }
      if (response.statusCode >= 400) {
        throw Exception('Request failed (${response.statusCode})');
      }
      return {};
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 401 && retryOnAuth) {
      final refreshed = await _refreshAccessToken();
      if (refreshed) {
        return _request(path, method: method, body: body, retryOnAuth: false);
      }
    }
    if (response.statusCode >= 400) {
      throw Exception((decoded['error'] ?? 'Request failed') as String);
    }
    return decoded;
  }

  Future<bool> _refreshAccessToken() async {
    if (_refreshToken == null) return false;
    try {
      final response = await _client.post(
        _uri('/api/auth/refresh'),
        headers: const {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': _refreshToken}),
      );

      if (response.statusCode >= 400) {
        await clearAuthTokens();
        return false;
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final accessToken = decoded['token'] as String?;
      final refreshToken = decoded['refreshToken'] as String?;
      if (accessToken == null || refreshToken == null) {
        await clearAuthTokens();
        return false;
      }

      await setAuthTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
      );
      return true;
    } catch (_) {
      await clearAuthTokens();
      return false;
    }
  }

  Future<Map<String, dynamic>> login(
      {required String email, required String password}) {
    return _request('/api/auth/login', method: 'POST', body: {
      'email': email,
      'password': password,
    });
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    required int age,
    required String gender,
    required double height,
    required double weight,
  }) {
    return _request('/api/auth/register', method: 'POST', body: {
      'name': name,
      'email': email,
      'password': password,
      'age': age,
      'gender': gender,
      'height': height,
      'weight': weight,
    });
  }

  Future<Map<String, dynamic>> requestPasswordReset({required String email}) {
    return _request('/api/auth/password-reset', method: 'POST', body: {
      'email': email,
    });
  }

  Future<Map<String, dynamic>> confirmPasswordReset({
    required String token,
    required String password,
  }) {
    return _request('/api/auth/password-reset/confirm', method: 'POST', body: {
      'token': token,
      'password': password,
    });
  }

  Future<void> logout() async {
    try {
      await _request('/api/auth/logout', method: 'POST', retryOnAuth: false);
    } finally {
      await clearAuthTokens();
    }
  }

  Future<Map<String, dynamic>> syncState() => _request('/api/sync');

  Future<Map<String, dynamic>> updateProfile({
    required String name,
    required int age,
    required String gender,
    required double height,
    required double weight,
  }) {
    return _request('/api/profile', method: 'PUT', body: {
      'name': name,
      'age': age,
      'gender': gender,
      'height': height,
      'weight': weight,
    });
  }

  Future<Map<String, dynamic>> addActivity({
    required String type,
    required int duration,
    required int steps,
    required double distance,
    required int calories,
    required String notes,
    required DateTime date,
  }) {
    return _request('/api/activities', method: 'POST', body: {
      'type': type,
      'duration': duration,
      'steps': steps,
      'distance': distance,
      'calories': calories,
      'notes': notes,
      'date': _utcIso(date),
    });
  }

  Future<void> deleteActivity(String id) =>
      _request('/api/activities/$id', method: 'DELETE');

  Future<Map<String, dynamic>> addHealthLog({
    required double weight,
    required double height,
    required String notes,
    required DateTime date,
  }) {
    return _request('/api/health-logs', method: 'POST', body: {
      'weight': weight,
      'height': height,
      'notes': notes,
      'date': _utcIso(date),
    });
  }

  Future<Map<String, dynamic>> addGoal({
    required String title,
    required String goalType,
    required double targetValue,
    required double currentValue,
    required DateTime targetDate,
  }) {
    return _request('/api/goals', method: 'POST', body: {
      'title': title,
      'goalType': goalType,
      'targetValue': targetValue,
      'currentValue': currentValue,
      'targetDate': _utcIso(targetDate),
    });
  }

  Future<Map<String, dynamic>> updateGoal(String goalId, double currentValue) {
    return _request('/api/goals/$goalId', method: 'PATCH', body: {
      'currentValue': currentValue,
    });
  }

  Future<Map<String, dynamic>> addReminder({
    required String title,
    required String message,
    required String scheduledTime,
    required String repeat,
  }) {
    return _request('/api/reminders', method: 'POST', body: {
      'title': title,
      'message': message,
      'scheduledTime': scheduledTime,
      'repeat': repeat,
    });
  }

  Future<Map<String, dynamic>> toggleReminder(String id) =>
      _request('/api/reminders/$id/toggle', method: 'PATCH');

  Future<Map<String, dynamic>> fetchTips() => _request('/api/tips');

  Future<Map<String, dynamic>> fetchExternalTips() async {
    try {
      return await _request('/api/tips/external');
    } catch (_) {
      if (kIsWeb) {
        return _fallbackTips();
      }
    }

    try {
      return await _fetchMyHealthfinderDirect();
    } catch (_) {
      return _fallbackTips();
    }
  }

  Future<Map<String, dynamic>> _fallbackTips() async {
    try {
      final response = await fetchTips();
      return {
        'tips': response['tips'] ?? const [],
        'sourceFallback': true,
      };
    } catch (_) {
      return {'tips': const [], 'sourceFallback': true};
    }
  }

  Future<Map<String, dynamic>> _fetchMyHealthfinderDirect() async {
    const base = 'https://odphp.health.gov/myhealthfinder/api/v4';
    final listResponse = await _client
        .get(Uri.parse('$base/itemlist.json?Type=topic'))
        .timeout(const Duration(seconds: 15));
    if (listResponse.statusCode >= 400) {
      throw Exception('External health tips API failed');
    }

    final listPayload = jsonDecode(listResponse.body) as Map<String, dynamic>;
    final rawItems = _readPath<List<dynamic>>(
      listPayload,
      const ['Result', 'Items', 'Item'],
    );
    final items = (rawItems ?? const <dynamic>[]).take(8).toList();

    final tips = <Map<String, dynamic>>[];
    for (final item in items) {
      final itemMap = Map<String, dynamic>.from(item as Map);
      final topicId = itemMap['Id']?.toString();
      if (topicId == null || topicId.isEmpty) continue;

      final detailResponse = await _client
          .get(Uri.parse('$base/topicsearch.json?TopicId=$topicId'))
          .timeout(const Duration(seconds: 15));
      if (detailResponse.statusCode >= 400) continue;

      final detailPayload =
          jsonDecode(detailResponse.body) as Map<String, dynamic>;
      final resources = _readPath<dynamic>(
        detailPayload,
        const ['Result', 'Resources', 'Resource'],
      );
      final resource = _firstMap(resources);
      if (resource == null) continue;

      final sections = resource['Sections'];
      final firstSection =
          _firstMap(sections is Map ? sections['section'] : null);
      final content = _cleanHtml(firstSection?['Content']?.toString() ?? '');
      final summary = _firstSentence(content).isEmpty
          ? 'Read evidence-based guidance about ${resource['Title']}.'
          : _firstSentence(content);

      tips.add({
        'id': 'myhealthfinder-${resource['Id']}',
        'title': resource['Title']?.toString() ?? 'Health Tip',
        'category': resource['Categories']?.toString() ?? 'Health',
        'summary': summary,
        'content': _truncate(content.isEmpty ? summary : content, 420),
        'source': 'ODPHP MyHealthfinder External API',
      });
    }

    return {'tips': tips};
  }

  Future<Map<String, dynamic>> addVitalLog({
    required String category,
    double? systolic,
    double? diastolic,
    double? heartRate,
    double? bloodGlucose,
    double? oxygenSaturation,
    double? temperature,
    double? waterMl,
    double? sleepHours,
    String? mood,
    double? painLevel,
    required String notes,
    required DateTime date,
  }) {
    return _request('/api/vitals', method: 'POST', body: {
      'category': category,
      if (systolic != null) 'systolic': systolic,
      if (diastolic != null) 'diastolic': diastolic,
      if (heartRate != null) 'heartRate': heartRate,
      if (bloodGlucose != null) 'bloodGlucose': bloodGlucose,
      if (oxygenSaturation != null) 'oxygenSaturation': oxygenSaturation,
      if (temperature != null) 'temperature': temperature,
      if (waterMl != null) 'waterMl': waterMl,
      if (sleepHours != null) 'sleepHours': sleepHours,
      if (mood != null) 'mood': mood,
      if (painLevel != null) 'painLevel': painLevel,
      'notes': notes,
      'date': _utcIso(date),
    });
  }

  T? _readPath<T>(Map<String, dynamic> map, List<String> path) {
    dynamic current = map;
    for (final key in path) {
      if (current is! Map) return null;
      current = current[key];
    }
    return current is T ? current : null;
  }

  Map<String, dynamic>? _firstMap(dynamic value) {
    if (value is List && value.isNotEmpty) {
      return Map<String, dynamic>.from(value.first as Map);
    }
    if (value is Map) return Map<String, dynamic>.from(value);
    return null;
  }

  String _cleanHtml(String value) {
    return value
        .replaceAll(
            RegExp(r'<script[\s\S]*?</script>', caseSensitive: false), ' ')
        .replaceAll(
            RegExp(r'<style[\s\S]*?</style>', caseSensitive: false), ' ')
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _firstSentence(String value) {
    final match = RegExp(r'^(.{40,220}?[.!?])\s').firstMatch(value);
    return match?.group(1) ?? _truncate(value, 180);
  }

  String _truncate(String value, int maxLength) {
    if (value.length <= maxLength) return value;
    return '${value.substring(0, maxLength - 1).trim()}...';
  }
}
