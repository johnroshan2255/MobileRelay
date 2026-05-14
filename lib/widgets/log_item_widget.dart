import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/request_log.dart';

class LogItemWidget extends StatelessWidget {
  const LogItemWidget({super.key, required this.log});

  final RequestLog log;

  static final _timeFmt = DateFormat('HH:mm:ss');
  static final _dateFmt = DateFormat('MMM d');

  @override
  Widget build(BuildContext context) {
    final (badgeColor, badgeBg) = _colors(log.status);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A2E),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: badgeColor.withAlpha(60),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Status badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  log.statusLabel,
                  style: TextStyle(
                    color: badgeColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              // HTTP status code
              Text(
                '${log.statusCode}',
                style: TextStyle(
                  color: badgeColor,
                  fontSize: 12,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              // Timestamp
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _timeFmt.format(log.timestamp),
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                  Text(
                    _dateFmt.format(log.timestamp),
                    style: const TextStyle(color: Colors.white38, fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
          if (log.phone != null) ...[
            const SizedBox(height: 6),
            _detail(Icons.phone, 'To: ${log.phone}'),
          ],
          if (log.message != null) ...[
            const SizedBox(height: 3),
            _detail(
              Icons.message,
              log.message!.length > 60
                  ? '${log.message!.substring(0, 60)}…'
                  : log.message!,
            ),
          ],
          if (log.errorMessage != null && !log.isSuccess) ...[
            const SizedBox(height: 3),
            _detail(Icons.error_outline, log.errorMessage!, color: const Color(0xFFFF5252)),
          ],
        ],
      ),
    );
  }

  Widget _detail(IconData icon, String text, {Color? color}) => Row(
        children: [
          Icon(icon, size: 13, color: color ?? Colors.white38),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: color ?? Colors.white60,
                fontSize: 12,
                fontFamily: 'monospace',
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );

  (Color, Color) _colors(LogStatus status) {
    return switch (status) {
      LogStatus.success      => (const Color(0xFF00E676), const Color(0x2000E676)),
      LogStatus.unauthorized => (const Color(0xFFFFD740), const Color(0x20FFD740)),
      LogStatus.badRequest   => (const Color(0xFFFF9100), const Color(0x20FF9100)),
      LogStatus.failure      => (const Color(0xFFFF5252), const Color(0x20FF5252)),
    };
  }
}
