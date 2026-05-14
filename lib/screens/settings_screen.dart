import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../models/app_settings.dart';
import '../providers/app_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late ServerMode _selectedMode;
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    final provider = context.read<AppProvider>();
    _selectedMode = provider.currentMode;
  }

  Future<void> _saveSettings() async {
    final provider = context.read<AppProvider>();
    
    final newSettings = provider.settings.copyWith(
      mode: _selectedMode,
    );

    await provider.updateSettings(newSettings);
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved', style: TextStyle(color: Colors.white)),
          backgroundColor: Color(0xFF1A1A1A),
          duration: Duration(seconds: 2),
        ),
      );
      setState(() => _hasChanges = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Settings',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 20,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSection(
              'SERVER MODE',
              _buildModeSelector(),
            ),
            const SizedBox(height: 16),
            _buildSection(
              'API KEY',
              _buildApiKeyDisplay(provider.settings.apiKey),
            ),
            const SizedBox(height: 24),
            if (_hasChanges || _selectedMode != provider.currentMode)
              _buildSaveButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF808080),
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildModeSelector() {
    return Column(
      children: [
        _buildModeOption(
          mode: ServerMode.local,
          icon: Icons.router,
          title: 'Local Hotspot',
          description: 'Run server on this device',
        ),
        const SizedBox(height: 12),
        _buildModeOption(
          mode: ServerMode.remote,
          icon: Icons.cloud,
          title: 'Remote Server',
          description: 'Connect via WebSocket',
        ),
      ],
    );
  }

  Widget _buildModeOption({
    required ServerMode mode,
    required IconData icon,
    required String title,
    required String description,
  }) {
    final isSelected = _selectedMode == mode;
    
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedMode = mode;
          _hasChanges = true;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : const Color(0xFF1A1A1A),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: const Color(0xFF404040)),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.black : Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: isSelected ? Colors.black : Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      color: isSelected ? Colors.black54 : const Color(0xFF808080),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check,
                color: Colors.black,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildApiKeyDisplay(String apiKey) {
    String displayKey = apiKey;
    if (apiKey.length > 12) {
      displayKey = '${apiKey.substring(0, 8)}...${apiKey.substring(apiKey.length - 4)}';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFF404040)),
      ),
      child: Row(
        children: [
          const Icon(Icons.key, color: Colors.white, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              displayKey,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontFamily: 'monospace',
              ),
            ),
          ),
          const Icon(Icons.lock, color: Color(0xFF808080), size: 16),
        ],
      ),
    );
  }

  Widget _buildSaveButton() {
    return GestureDetector(
      onTap: _saveSettings,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(4),
        ),
        child: const Center(
          child: Text(
            'SAVE SETTINGS',
            style: TextStyle(
              color: Colors.black,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 1,
            ),
          ),
        ),
      ),
    );
  }
}
