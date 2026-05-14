import 'package:flutter/services.dart';
import '../constants/app_constants.dart';

class SmsException implements Exception {
  final String message;
  const SmsException(this.message);
  @override
  String toString() => 'SmsException: $message';
}

class SmsService {
  static const _channel = MethodChannel(AppConstants.smsChannel);

  /// Sends an SMS via the native Android SmsManager.
  /// Throws [SmsException] on failure.
  Future<void> send({required String phone, required String message}) async {
    try {
      final result = await _channel.invokeMethod<bool>('sendSms', {
        'phone': phone,
        'message': message,
      });

      if (result != true) {
        throw const SmsException('Native layer returned false');
      }
    } on PlatformException catch (e) {
      throw SmsException(e.message ?? 'Unknown platform error');
    }
  }
}
