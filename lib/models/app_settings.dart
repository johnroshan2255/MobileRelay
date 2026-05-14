import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Server operation mode
enum ServerMode {
  local,  // HTTP server on local hotspot
  remote, // WebSocket client connected to remote server
}

/// Application settings persisted across app restarts
class AppSettings {
  final ServerMode mode;
  final String? remoteServerUrl;
  final String apiKey;

  const AppSettings({
    required this.mode,
    this.remoteServerUrl,
    required this.apiKey,
  });

  /// Default settings
  factory AppSettings.defaults({required String defaultApiKey}) => AppSettings(
        mode: ServerMode.local,
        remoteServerUrl: null,
        apiKey: defaultApiKey,
      );

  /// Load settings from SharedPreferences
  static Future<AppSettings> load({required String defaultApiKey}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString('app_settings');
      
      if (json == null) {
        return AppSettings.defaults(defaultApiKey: defaultApiKey);
      }

      final map = jsonDecode(json) as Map<String, dynamic>;
      return AppSettings(
        mode: ServerMode.values.firstWhere(
          (e) => e.name == map['mode'],
          orElse: () => ServerMode.local,
        ),
        remoteServerUrl: map['remote_server_url'] as String?,
        apiKey: map['api_key'] as String? ?? defaultApiKey,
      );
    } catch (_) {
      return AppSettings.defaults(defaultApiKey: defaultApiKey);
    }
  }

  /// Save settings to SharedPreferences
  Future<void> save() async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode({
      'mode': mode.name,
      'remote_server_url': remoteServerUrl,
      'api_key': apiKey,
    });
    await prefs.setString('app_settings', json);
  }

  /// Copy with new values
  AppSettings copyWith({
    ServerMode? mode,
    String? remoteServerUrl,
    String? apiKey,
  }) =>
      AppSettings(
        mode: mode ?? this.mode,
        remoteServerUrl: remoteServerUrl ?? this.remoteServerUrl,
        apiKey: apiKey ?? this.apiKey,
      );

  @override
  String toString() =>
      'AppSettings(mode: $mode, remoteServerUrl: $remoteServerUrl, apiKey: ${apiKey.substring(0, 4)}***)';
}
