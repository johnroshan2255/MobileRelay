import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_provider.dart';
import '../widgets/log_item_widget.dart';

class LogsScreen extends StatelessWidget {
  const LogsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF13131F),
        title: const Text(
          'Request Logs',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Consumer<AppProvider>(
            builder: (context, provider, child) => TextButton.icon(
              onPressed: provider.logs.isEmpty
                  ? null
                  : () {
                      provider.clearLogs();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Logs cleared'),
                          duration: Duration(seconds: 2),
                          backgroundColor: Color(0xFF7C83FD),
                        ),
                      );
                    },
              icon: const Icon(Icons.delete_sweep, size: 18),
              label: const Text('Clear'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFFFF5252),
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Consumer<AppProvider>(
        builder: (context, provider, child) {
          final logs = provider.logs;

          if (logs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.receipt_long, color: Colors.white24, size: 64),
                  SizedBox(height: 16),
                  Text(
                    'No requests yet',
                    style: TextStyle(color: Colors.white38, fontSize: 16),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Start the server and send a request',
                    style: TextStyle(color: Colors.white24, fontSize: 13),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: logs.length,
            itemBuilder: (_, index) => LogItemWidget(log: logs[index]),
          );
        },
      ),
    );
  }
}
