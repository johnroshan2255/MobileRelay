import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:uuid/uuid.dart';

import '../constants/app_constants.dart';
import '../models/api_response.dart';
import '../models/request_log.dart';
import '../models/sms_request.dart';
import 'sms_service.dart';

typedef OnLogAdded = void Function(RequestLog log);
typedef OnSmsSent = void Function();

class ServerService {
  ServerService({required SmsService smsService}) : _smsService = smsService;

  final SmsService _smsService;

  HttpServer? _server;
  StreamSubscription<HttpRequest>? _subscription;

  bool get isRunning => _server != null;

  /// Starts the HTTP server. Throws if already running.
  Future<void> start({
    required OnLogAdded onLogAdded,
    required OnSmsSent onSmsSent,
  }) async {
    if (_server != null) return;

    _server = await HttpServer.bind(
      InternetAddress.anyIPv4,
      AppConstants.serverPort,
      shared: false,
    );

    _subscription = _server!.listen(
      (request) => _handleRequest(
        request,
        onLogAdded: onLogAdded,
        onSmsSent: onSmsSent,
      ),
      onError: (_) {},
      cancelOnError: false,
    );
  }

  /// Stops the HTTP server gracefully.
  Future<void> stop() async {
    await _subscription?.cancel();
    await _server?.close(force: true);
    _subscription = null;
    _server = null;
  }

  // ---------------------------------------------------------------------------
  // Request handling
  // ---------------------------------------------------------------------------

  Future<void> _handleRequest(
    HttpRequest request, {
    required OnLogAdded onLogAdded,
    required OnSmsSent onSmsSent,
  }) async {
    final response = request.response
      ..headers.contentType = ContentType.json
      ..headers.add('Access-Control-Allow-Origin', '*');

    // Generate unique request ID
    final requestId = const Uuid().v4();
    final startTime = DateTime.now();

    String? phone;
    String? messageText;
    int statusCode = 200;
    LogStatus logStatus = LogStatus.success;
    String errorDetail = '';

    try {
      // Only accept POST /api/sms/send
      if (request.uri.path != AppConstants.sendSmsPath ||
          request.method.toUpperCase() != 'POST') {
        statusCode = 404;
        logStatus = LogStatus.failure;
        errorDetail = 'Endpoint not found';
        _respond(response, statusCode, ApiResponse.fail(errorDetail));
        return;
      }

      // Validate API key
      final providedKey = request.headers.value(AppConstants.apiKeyHeader);
      if (providedKey != AppConstants.apiKey) {
        statusCode = 401;
        logStatus = LogStatus.unauthorized;
        errorDetail = 'Invalid or missing API key';
        _respond(response, statusCode, ApiResponse.fail(errorDetail));
        return;
      }

      // Parse JSON body
      final bodyBytes = await request.fold<List<int>>(
        [],
        (acc, chunk) => [...acc, ...chunk],
      );
      final bodyString = utf8.decode(bodyBytes);
      Map<String, dynamic> json;
      try {
        json = jsonDecode(bodyString) as Map<String, dynamic>;
      } catch (_) {
        statusCode = 400;
        logStatus = LogStatus.badRequest;
        errorDetail = 'Invalid JSON body';
        _respond(response, statusCode, ApiResponse.fail(errorDetail));
        return;
      }

      // Validate required fields
      SmsRequest smsRequest;
      try {
        smsRequest = SmsRequest.fromJson(json);
      } on FormatException catch (e) {
        statusCode = 400;
        logStatus = LogStatus.badRequest;
        errorDetail = e.message;
        _respond(response, statusCode, ApiResponse.fail(errorDetail));
        return;
      }

      phone = smsRequest.phone;
      messageText = smsRequest.message;

      // Send the SMS
      await _smsService.send(phone: phone, message: messageText);

      // Calculate duration
      final duration = DateTime.now().difference(startTime).inMilliseconds;
      final timestamp = DateTime.now().toIso8601String();

      onSmsSent();
      _respond(
        response,
        200,
        ApiResponse.ok(
          id: requestId,
          status: 'delivered',
          duration: duration,
          timestamp: timestamp,
        ),
      );
    } catch (e) {
      statusCode = 500;
      logStatus = LogStatus.failure;
      errorDetail = e.toString();
      _respond(response, statusCode, ApiResponse.fail('Internal server error'));
    } finally {
      onLogAdded(RequestLog(
        id: requestId,
        timestamp: DateTime.now(),
        method: request.method,
        path: request.uri.path,
        phone: phone,
        message: messageText,
        statusCode: statusCode,
        status: logStatus,
        errorMessage: errorDetail.isEmpty ? null : errorDetail,
      ));
    }
  }

  void _respond(HttpResponse response, int statusCode, ApiResponse body) {
    response.statusCode = statusCode;
    response.write(body.toJson());
    response.close();
  }
}
