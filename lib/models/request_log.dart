enum LogStatus { success, failure, unauthorized, badRequest }

class RequestLog {
  final String id;
  final DateTime timestamp;
  final String method;
  final String path;
  final String? phone;
  final String? message;
  final int statusCode;
  final LogStatus status;
  final String? errorMessage;

  const RequestLog({
    required this.id,
    required this.timestamp,
    required this.method,
    required this.path,
    required this.statusCode,
    required this.status,
    this.phone,
    this.message,
    this.errorMessage,
  });

  bool get isSuccess => status == LogStatus.success;

  String get statusLabel {
    switch (status) {
      case LogStatus.success:
        return 'SMS SENT';
      case LogStatus.unauthorized:
        return 'UNAUTHORIZED';
      case LogStatus.badRequest:
        return 'BAD REQUEST';
      case LogStatus.failure:
        return 'FAILED';
    }
  }
}
