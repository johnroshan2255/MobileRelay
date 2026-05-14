import 'dart:convert';

class ApiResponse {
  final bool success;
  final String? error;
  final String? id;
  final String? status;
  final int? duration;
  final String? timestamp;

  const ApiResponse({
    required this.success,
    this.error,
    this.id,
    this.status,
    this.duration,
    this.timestamp,
  });

  const ApiResponse.ok({
    this.id,
    this.status,
    this.duration,
    this.timestamp,
  }) : success = true,
       error = null;

  const ApiResponse.fail(String message)
      : success = false,
        error = message,
        id = null,
        status = null,
        duration = null,
        timestamp = null;

  String toJson() => jsonEncode({
        'success': success,
        if (error != null) 'error': error,
        if (id != null) 'id': id,
        if (status != null) 'status': status,
        if (duration != null) 'duration': duration,
        if (timestamp != null) 'timestamp': timestamp,
      });
}
