import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../models/request_log.dart';
import 'sms_service.dart';

typedef OnLogAdded = void Function(RequestLog log);
typedef OnSmsSent = void Function();

enum WebSocketState { disconnected, connecting, connected, error }

class WebSocketService {
  WebSocketService({required SmsService smsService}) : _smsService = smsService;

  final SmsService _smsService;
  WebSocketChannel? _channel;
  StreamSubscription? _subscription;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;
  
  WebSocketState _state = WebSocketState.disconnected;
  String? _lastError;
  OnLogAdded? _onLogAdded;
  OnSmsSent? _onSmsSent;

  WebSocketState get state => _state;
  String? get lastError => _lastError;
  bool get isConnected => _state == WebSocketState.connected;

  /// Connect to remote WebSocket server
  Future<void> connect({
    required String url,
    required String apiKey,
    required OnLogAdded onLogAdded,
    required OnSmsSent onSmsSent,
  }) async {
    if (_state == WebSocketState.connected || _state == WebSocketState.connecting) {
      return;
    }

    _onLogAdded = onLogAdded;
    _onSmsSent = onSmsSent;
    _setState(WebSocketState.connecting);
    _lastError = null;

    try {
      _channel = WebSocketChannel.connect(Uri.parse(url));
      
      // Send authentication message
      _sendMessage({
        'type': 'auth',
        'api_key': apiKey,
        'device_id': 'flutter-mobile-relay',
      });

      // Listen for messages
      _subscription = _channel!.stream.listen(
        _handleMessage,
        onError: (error) {
          _lastError = error.toString();
          _setState(WebSocketState.error);
          _scheduleReconnect(url, apiKey);
        },
        onDone: () {
          _setState(WebSocketState.disconnected);
          _scheduleReconnect(url, apiKey);
        },
        cancelOnError: true,
      );

      _setState(WebSocketState.connected);
      _reconnectAttempts = 0;
    } catch (e) {
      _lastError = e.toString();
      _setState(WebSocketState.error);
      _scheduleReconnect(url, apiKey);
    }
  }

  /// Disconnect from WebSocket server
  Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    await _subscription?.cancel();
    await _channel?.sink.close();
    _subscription = null;
    _channel = null;
    _setState(WebSocketState.disconnected);
    _lastError = null;
    _reconnectAttempts = 0;
  }

  /// Handle incoming WebSocket messages
  void _handleMessage(dynamic data) {
    try {
      final message = jsonDecode(data as String) as Map<String, dynamic>;
      final type = message['type'] as String?;

      switch (type) {
        case 'auth_result':
          final success = message['success'] as bool? ?? false;
          if (!success) {
            _lastError = 'Authentication failed';
            _setState(WebSocketState.error);
            disconnect();
          }
          break;

        case 'send_sms':
          _handleSendSmsRequest(message);
          break;

        case 'ping':
          _sendMessage({'type': 'pong'});
          break;

        default:
          break;
      }
    } catch (e) {
      _lastError = 'Failed to parse message: $e';
    }
  }

  /// Handle SMS send request from server
  Future<void> _handleSendSmsRequest(Map<String, dynamic> message) async {
    final id = message['id'] as String?;
    final phone = message['phone'] as String?;
    final messageText = message['message'] as String?;

    bool success = false;
    String? errorMessage;
    int statusCode = 200;
    LogStatus logStatus = LogStatus.success;

    try {
      if (phone == null || phone.isEmpty) {
        throw FormatException('Phone number is required');
      }
      if (messageText == null || messageText.isEmpty) {
        throw FormatException('Message text is required');
      }

      // Send the SMS
      await _smsService.send(phone: phone, message: messageText);
      success = true;
      
      _onSmsSent?.call();
    } on FormatException catch (e) {
      errorMessage = e.message;
      statusCode = 400;
      logStatus = LogStatus.badRequest;
    } catch (e) {
      errorMessage = e.toString();
      statusCode = 500;
      logStatus = LogStatus.failure;
    }

    // Send result back to server
    _sendMessage({
      'type': 'sms_result',
      'id': id,
      'success': success,
      'error': errorMessage,
      'timestamp': DateTime.now().toIso8601String(),
    });

    // Log the request
    _onLogAdded?.call(RequestLog(
      id: id ?? DateTime.now().microsecondsSinceEpoch.toString(),
      timestamp: DateTime.now(),
      method: 'WEBSOCKET',
      path: '/send-sms',
      phone: phone,
      message: messageText,
      statusCode: statusCode,
      status: logStatus,
      errorMessage: errorMessage,
    ));
  }

  /// Send message to server
  void _sendMessage(Map<String, dynamic> message) {
    try {
      _channel?.sink.add(jsonEncode(message));
    } catch (e) {
      _lastError = 'Failed to send message: $e';
    }
  }

  /// Schedule reconnection with exponential backoff
  void _scheduleReconnect(String url, String apiKey) {
    if (_reconnectTimer != null) return;
    
    _reconnectAttempts++;
    final delay = _calculateBackoff(_reconnectAttempts);
    
    _reconnectTimer = Timer(delay, () {
      _reconnectTimer = null;
      if (_onLogAdded != null && _onSmsSent != null) {
        connect(
          url: url,
          apiKey: apiKey,
          onLogAdded: _onLogAdded!,
          onSmsSent: _onSmsSent!,
        );
      }
    });
  }

  /// Calculate exponential backoff delay
  Duration _calculateBackoff(int attempts) {
    final seconds = 2 << (attempts.clamp(0, 5));
    return Duration(seconds: seconds.clamp(1, 60));
  }

  /// Update state and notify listeners (if needed)
  void _setState(WebSocketState newState) {
    _state = newState;
  }
}
