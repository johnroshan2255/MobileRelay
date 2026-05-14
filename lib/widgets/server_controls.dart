import 'package:flutter/material.dart';

import '../providers/app_provider.dart';

class ServerControls extends StatelessWidget {
  const ServerControls({
    super.key,
    required this.serverState,
    required this.onStart,
    required this.onStop,
  });

  final ServerState serverState;
  final VoidCallback onStart;
  final VoidCallback onStop;

  @override
  Widget build(BuildContext context) {
    final isBusy = serverState == ServerState.starting ||
        serverState == ServerState.stopping;
    final isRunning = serverState == ServerState.running;

    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: (!isBusy && !isRunning) ? onStart : null,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: (!isBusy && !isRunning) ? Colors.white : const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFF404040)),
              ),
              child: Center(
                child: Text(
                  'START',
                  style: TextStyle(
                    color: (!isBusy && !isRunning) ? Colors.black : const Color(0xFF404040),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: GestureDetector(
            onTap: (!isBusy && isRunning) ? onStop : null,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: const Color(0xFF404040)),
              ),
              child: Center(
                child: Text(
                  'STOP',
                  style: TextStyle(
                    color: (!isBusy && isRunning) ? Colors.white : const Color(0xFF404040),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
