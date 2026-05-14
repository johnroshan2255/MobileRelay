import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Central configuration for MobileRelay.
/// API key is loaded from .env file (API_KEY variable).
class AppConstants {
  AppConstants._();

  static const String appName = 'MobileRelay';
  static const String appVersion = '1.0.0';

  // HTTP server
  static const int serverPort = 8080;
  static const String sendSmsPath = '/api/sms/send';

  // Security — loaded from .env file
  static String get apiKey => dotenv.env['API_KEY'] ?? 'MY_SECRET_KEY';
  static const String apiKeyHeader = 'x-api-key';

  // Platform channel name (must match MainActivity.kt)
  static const String smsChannel = 'com.mobilerelay.app/sms';
}
