import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:permission_handler/permission_handler.dart';

import '../constants/app_constants.dart';
import '../models/app_settings.dart';
import '../models/request_log.dart';
import '../services/network_service.dart';
import '../services/server_service.dart';
import '../services/sms_service.dart';
import '../services/websocket_service.dart';

enum ServerState { stopped, starting, running, stopping }

class AppProvider extends ChangeNotifier {
  AppProvider()
      : _smsService = SmsService(),
        _networkService = NetworkService() {
    _serverService = ServerService(smsService: _smsService);
    _websocketService = WebSocketService(smsService: _smsService);
    _loadSettings();
  }

  final SmsService _smsService;
  final NetworkService _networkService;
  late final ServerService _serverService;
  late final WebSocketService _websocketService;

  // ── State ──────────────────────────────────────────────────────────────────
  ServerState _serverState = ServerState.stopped;
  AppSettings _settings = AppSettings.defaults(defaultApiKey: AppConstants.apiKey);
  String? _ipAddress;
  int _smsSentCount = 0;
  final List<RequestLog> _logs = [];
  String? _lastError;
  bool _smsPermissionGranted = false;

  // ── Getters ────────────────────────────────────────────────────────────────
  ServerState get serverState => _serverState;
  bool get isRunning => _serverState == ServerState.running;
  bool get isBusy =>
      _serverState == ServerState.starting ||
      _serverState == ServerState.stopping;

  ServerMode get currentMode => _settings.mode;
  AppSettings get settings => _settings;
  
  String get ipAddress => _ipAddress ?? '...';
  int get port => AppConstants.serverPort;
  String get apiUrl {
    if (_settings.mode == ServerMode.remote) {
      // For remote mode, use the HTTP server URL from .env (not the WebSocket URL)
      final serverUrl = dotenv.env['SERVER_URL'];
      if (serverUrl == null || serverUrl.isEmpty) {
        return 'Not configured';
      }
      
      return '$serverUrl${AppConstants.sendSmsPath}';
    }
    return 'http://${_ipAddress ?? '<IP>'}:${AppConstants.serverPort}${AppConstants.sendSmsPath}';
  }

  int get smsSentCount => _smsSentCount;
  List<RequestLog> get logs => List.unmodifiable(_logs);
  String? get lastError => _lastError;
  bool get smsPermissionGranted => _smsPermissionGranted;

  // ── Public actions ─────────────────────────────────────────────────────────

  /// Load settings from storage
  Future<void> _loadSettings() async {
    _settings = await AppSettings.load(defaultApiKey: AppConstants.apiKey);
    
    // ALWAYS override API key with the one from .env to ensure it's current
    _settings = _settings.copyWith(apiKey: AppConstants.apiKey);
    
    print('📱 Settings loaded - Mode: ${_settings.mode}, API Key: ${_settings.apiKey}');
    notifyListeners();
  }

  /// Switch server mode
  Future<void> switchMode(ServerMode mode) async {
    if (_serverState == ServerState.running) {
      await stopServer();
    }
    
    _settings = _settings.copyWith(mode: mode);
    await _settings.save();
    notifyListeners();
  }

  /// Update settings
  Future<void> updateSettings(AppSettings newSettings) async {
    if (_serverState == ServerState.running) {
      await stopServer();
    }
    
    _settings = newSettings;
    await _settings.save();
    notifyListeners();
  }

  /// Requests SEND_SMS runtime permission. Returns true if granted.
  Future<bool> requestSmsPermission() async {
    final status = await Permission.sms.request();
    _smsPermissionGranted = status.isGranted;
    notifyListeners();
    return _smsPermissionGranted;
  }

  /// Checks current permission state without prompting.
  Future<void> checkPermissions() async {
    _smsPermissionGranted = await Permission.sms.isGranted;
    notifyListeners();
  }

  Future<void> startServer() async {
    if (_serverState != ServerState.stopped) return;
    _lastError = null;
    _setServerState(ServerState.starting);

    try {
      if (_settings.mode == ServerMode.local) {
        // Local HTTP server mode
        _ipAddress = await _networkService.getLocalIpAddress();

        await _serverService.start(
          onLogAdded: _onLogAdded,
          onSmsSent: _onSmsSent,
        );
      } else {
        // Remote WebSocket mode
        final remoteUrl = _settings.remoteServerUrl ?? dotenv.env['REMOTE_SERVER_URL'];
        
        if (remoteUrl == null || remoteUrl.isEmpty) {
          throw Exception('Remote server URL not configured');
        }

        print('🌐 Starting remote mode with API key: ${_settings.apiKey}');
        await _websocketService.connect(
          url: remoteUrl,
          apiKey: _settings.apiKey,
          onLogAdded: _onLogAdded,
          onSmsSent: _onSmsSent,
        );
        
        _ipAddress = remoteUrl;
      }

      _setServerState(ServerState.running);
    } catch (e) {
      _lastError = e.toString();
      _setServerState(ServerState.stopped);
    }
  }

  Future<void> stopServer() async {
    if (_serverState != ServerState.running) return;
    _setServerState(ServerState.stopping);

    try {
      if (_settings.mode == ServerMode.local) {
        await _serverService.stop();
      } else {
        await _websocketService.disconnect();
      }
    } catch (_) {}

    _setServerState(ServerState.stopped);
  }

  void clearLogs() {
    _logs.clear();
    notifyListeners();
  }

  // ── Private helpers ────────────────────────────────────────────────────────

  void _onLogAdded(RequestLog log) {
    _logs.insert(0, log);
    // Keep at most 200 log entries to avoid unbounded memory growth
    if (_logs.length > 200) _logs.removeLast();
    notifyListeners();
  }

  void _onSmsSent() {
    _smsSentCount++;
    notifyListeners();
  }

  void _setServerState(ServerState state) {
    _serverState = state;
    notifyListeners();
  }
}
