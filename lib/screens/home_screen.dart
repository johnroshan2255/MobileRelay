import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../constants/app_constants.dart';
import '../providers/app_provider.dart';
import '../widgets/api_info_card.dart';
import '../widgets/log_item_widget.dart';
import '../widgets/server_controls.dart';
import '../widgets/stats_card.dart';
import '../widgets/status_card.dart';
import 'logs_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Check permissions on launch without prompting
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AppProvider>().checkPermissions();
    });
  }

  Future<void> _handleStart() async {
    final provider = context.read<AppProvider>();

    // Ensure SMS permission before starting
    if (!provider.smsPermissionGranted) {
      final granted = await provider.requestSmsPermission();
      if (!mounted) return;
      if (!granted) {
        _showSnack('SMS permission denied. Cannot send messages.', isError: true);
        return;
      }
    }

    await provider.startServer();
    if (!mounted) return;

    if (provider.lastError != null) {
      _showSnack('Failed to start server: ${provider.lastError}', isError: true);
    } else {
      _showSnack('Server started on port ${AppConstants.serverPort}');
    }
  }

  Future<void> _handleStop() async {
    await context.read<AppProvider>().stopServer();
    if (!mounted) return;
    _showSnack('Server stopped');
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF1A1A1A),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Consumer<AppProvider>(
        builder: (context, provider, child) => CustomScrollView(
          slivers: [
            _buildAppBar(),
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  if (!provider.smsPermissionGranted) ...[
                    _permissionBanner(),
                    const SizedBox(height: 12),
                  ],
                  StatusCard(
                    serverState: provider.serverState,
                    serverMode: provider.currentMode,
                  ),
                  const SizedBox(height: 12),
                  ServerControls(
                    serverState: provider.serverState,
                    onStart: _handleStart,
                    onStop: _handleStop,
                  ),
                  const SizedBox(height: 12),
                  ApiInfoCard(
                    ipAddress: provider.ipAddress,
                    port: provider.port,
                    apiUrl: provider.apiUrl,
                    isRunning: provider.isRunning,
                    serverMode: provider.currentMode,
                  ),
                  const SizedBox(height: 12),
                  StatsCard(
                    smsSentCount: provider.smsSentCount,
                    totalRequests: provider.logs.length,
                    failedRequests: provider.logs.where((l) => !l.isSuccess).length,
                  ),
                  if (provider.logs.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _logsHeader(context, provider),
                    const SizedBox(height: 8),
                    ...provider.logs.take(3).map((log) => LogItemWidget(log: log)),
                    if (provider.logs.length > 3) ...[
                      const SizedBox(height: 8),
                      _viewAllButton(context, provider.logs.length),
                    ],
                  ],
                  const SizedBox(height: 16),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppBar() => SliverAppBar(
        backgroundColor: Colors.black,
        surfaceTintColor: Colors.transparent,
        pinned: true,
        expandedHeight: 100,
        flexibleSpace: FlexibleSpaceBar(
          title: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.sms, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                AppConstants.appName,
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 20,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          centerTitle: false,
          titlePadding: const EdgeInsets.only(left: 16, bottom: 16),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white, size: 22),
            tooltip: 'Settings',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.list_alt, color: Colors.white, size: 22),
            tooltip: 'Logs',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const LogsScreen()),
            ),
          ),
          const SizedBox(width: 8),
        ],
      );

  Widget _permissionBanner() => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFF404040)),
        ),
        child: const Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.white, size: 20),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'SMS permission required',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );

  Widget _logsHeader(BuildContext context, AppProvider provider) => Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Row(
          children: [
            const Text(
              'RECENT ACTIVITY',
              style: TextStyle(
                color: Color(0xFF808080),
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () {
                provider.clearLogs();
                _showSnack('Logs cleared');
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  border: Border.all(color: const Color(0xFF404040)),
                  borderRadius: BorderRadius.circular(2),
                ),
                child: const Text(
                  'Clear',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _viewAllButton(BuildContext context, int totalLogs) => GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LogsScreen()),
        ),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: const Color(0xFF404040)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'View all $totalLogs logs',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.arrow_forward,
                color: Colors.white,
                size: 16,
              ),
            ],
          ),
        ),
      );
}
