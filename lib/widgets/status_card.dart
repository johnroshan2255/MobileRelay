import 'package:flutter/material.dart';

import '../models/app_settings.dart';
import '../providers/app_provider.dart';

class StatusCard extends StatelessWidget {
  const StatusCard({
    super.key,
    required this.serverState,
    required this.serverMode,
  });

  final ServerState serverState;
  final ServerMode serverMode;

  @override
  Widget build(BuildContext context) {
    final isRunning = serverState == ServerState.running;
    final label = switch (serverState) {
      ServerState.running => 'RUNNING',
      ServerState.starting => 'STARTING...',
      ServerState.stopping => 'STOPPING...',
      ServerState.stopped => 'OFFLINE',
    };

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
          Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: isRunning ? Colors.white : const Color(0xFF404040),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF404040)),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      serverMode == ServerMode.local ? Icons.router : Icons.cloud,
                      color: Colors.white,
                      size: 12,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      serverMode == ServerMode.local ? 'Local' : 'Remote',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
