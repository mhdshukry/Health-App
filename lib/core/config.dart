import 'package:flutter/foundation.dart';

const String _configuredApiBaseUrl = String.fromEnvironment('API_BASE_URL');

/// Backend base URL.
///
/// Override with:
/// flutter run --dart-define=API_BASE_URL=http://your-host:4000
final String apiBaseUrl =
    _configuredApiBaseUrl.isNotEmpty ? _configuredApiBaseUrl : _defaultApiBaseUrl;

String get _defaultApiBaseUrl {
  if (kIsWeb) return 'http://localhost:4000';
  if (defaultTargetPlatform == TargetPlatform.android) {
    return 'http://10.0.2.2:4000';
  }
  return 'http://localhost:4000';
}
