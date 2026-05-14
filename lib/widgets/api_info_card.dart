import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../constants/app_constants.dart';
import '../models/app_settings.dart';

class ApiInfoCard extends StatelessWidget {
  const ApiInfoCard({
    super.key,
    required this.ipAddress,
    required this.port,
    required this.apiUrl,
    required this.isRunning,
    required this.serverMode,
  });

  final String ipAddress;
  final int port;
  final String apiUrl;
  final bool isRunning;
  final ServerMode serverMode;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF404040)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'API ENDPOINT',
            style: TextStyle(
              color: Color(0xFF808080),
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 12),
          if (isRunning) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFF404040)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      apiUrl,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: apiUrl));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('URL copied', style: TextStyle(color: Colors.white)),
                          duration: Duration(seconds: 2),
                          backgroundColor: Color(0xFF1A1A1A),
                        ),
                      );
                    },
                    child: const Icon(
                      Icons.copy,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _InfoRow('Mode', serverMode == ServerMode.local ? 'Local Hotspot' : 'Remote Server'),
            if (serverMode == ServerMode.local) ...[
              const SizedBox(height: 8),
              _InfoRow('IP', ipAddress),
              const SizedBox(height: 8),
              _InfoRow('Port', port.toString()),
            ],
            const SizedBox(height: 8),
            _InfoRow('Method', 'POST'),
            const SizedBox(height: 8),
            _InfoRow('Path', AppConstants.sendSmsPath),
          ] else ...[
            const Text(
              'Server not running',
              style: TextStyle(
                color: Color(0xFF808080),
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 60,
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF808080),
              fontSize: 12,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontFamily: 'monospace',
            ),
          ),
        ),
      ],
    );
  }
}
