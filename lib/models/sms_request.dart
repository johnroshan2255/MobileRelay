class SmsRequest {
  final String phone;
  final String message;

  const SmsRequest({required this.phone, required this.message});

  factory SmsRequest.fromJson(Map<String, dynamic> json) {
    final phone = json['phone'];
    final message = json['message'];

    if (phone == null || phone is! String || phone.trim().isEmpty) {
      throw FormatException('Missing or invalid field: phone');
    }
    if (message == null || message is! String || message.trim().isEmpty) {
      throw FormatException('Missing or invalid field: message');
    }

    return SmsRequest(phone: phone.trim(), message: message.trim());
  }
}
