import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import '../services/llm_service.dart';
import '../utils/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _ollamaUrlController = TextEditingController();
  bool _isTestingConnection = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  Future<void> _loadCurrentSettings() async {
    final llmService = context.read<LLMService>();
    if (llmService.currentUrl != null) {
      _ollamaUrlController.text = llmService.currentUrl!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildConnectionSection(),
          const SizedBox(height: 16),
          _buildThemeSection(),
          const SizedBox(height: 16),
          _buildModeSection(),
          const SizedBox(height: 16),
          _buildAboutSection(),
        ],
      ),
    );
  }

  Widget _buildConnectionSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.link),
                const SizedBox(width: 8),
                Text(
                  'Connection Settings',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _ollamaUrlController,
              decoration: const InputDecoration(
                labelText: 'Ollama Server URL',
                hintText: 'http://localhost:11434',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: _testConnection,
                    child: _isTestingConnection
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Test Connection'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _saveConnection,
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Consumer<AppState>(
              builder: (context, appState, child) {
                return Row(
                  children: [
                    Icon(
                      appState.isConnectedToOllama 
                          ? Icons.check_circle 
                          : Icons.error,
                      color: appState.isConnectedToOllama 
                          ? AppTheme.successColor 
                          : AppTheme.errorColor,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      appState.isConnectedToOllama 
                          ? 'Connected to Ollama' 
                          : 'Not connected to Ollama',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: appState.isConnectedToOllama 
                            ? AppTheme.successColor 
                            : AppTheme.errorColor,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.palette),
                const SizedBox(width: 8),
                Text(
                  'Appearance',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Consumer<AppState>(
              builder: (context, appState, child) {
                return Column(
                  children: [
                    RadioListTile<ThemeMode>(
                      title: const Text('System'),
                      subtitle: const Text('Follow system theme'),
                      value: ThemeMode.system,
                      groupValue: appState.themeMode,
                      onChanged: (value) {
                        if (value != null) {
                          appState.setThemeMode(value);
                        }
                      },
                    ),
                    RadioListTile<ThemeMode>(
                      title: const Text('Light'),
                      subtitle: const Text('Always use light theme'),
                      value: ThemeMode.light,
                      groupValue: appState.themeMode,
                      onChanged: (value) {
                        if (value != null) {
                          appState.setThemeMode(value);
                        }
                      },
                    ),
                    RadioListTile<ThemeMode>(
                      title: const Text('Dark'),
                      subtitle: const Text('Always use dark theme'),
                      value: ThemeMode.dark,
                      groupValue: appState.themeMode,
                      onChanged: (value) {
                        if (value != null) {
                          appState.setThemeMode(value);
                        }
                      },
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.work),
                const SizedBox(width: 8),
                Text(
                  'Mode Settings',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Consumer<AppState>(
              builder: (context, appState, child) {
                return Column(
                  children: [
                    ListTile(
                      leading: Icon(
                        Icons.work,
                        color: appState.currentMode == AppMode.work 
                            ? AppTheme.workModeColor 
                            : null,
                      ),
                      title: const Text('Current Mode'),
                      subtitle: Text(
                        appState.currentMode == AppMode.work 
                            ? 'Work Mode' 
                            : 'Personal Mode',
                      ),
                      trailing: Switch(
                        value: appState.currentMode == AppMode.work,
                        onChanged: (value) {
                          appState.switchMode(
                            value ? AppMode.work : AppMode.personal,
                          );
                        },
                      ),
                    ),
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.schedule),
                      title: const Text('Auto Mode Switching'),
                      subtitle: const Text('Switch modes based on work hours'),
                      trailing: IconButton(
                        icon: const Icon(Icons.settings),
                        onPressed: _showWorkHoursDialog,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAboutSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.info),
                const SizedBox(width: 8),
                Text(
                  'About',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.smartphone),
              title: const Text('LocalMind'),
              subtitle: const Text('Privacy-focused AI assistant v1.0.0'),
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip),
              title: const Text('Privacy Policy'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _showPrivacyPolicy,
            ),
            ListTile(
              leading: const Icon(Icons.help),
              title: const Text('Help & Support'),
              trailing: const Icon(Icons.chevron_right),
              onTap: _showHelp,
            ),
            ListTile(
              leading: const Icon(Icons.code),
              title: const Text('Open Source'),
              subtitle: const Text('View source code on GitHub'),
              trailing: const Icon(Icons.open_in_new),
              onTap: _openGitHub,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _testConnection() async {
    if (_isTestingConnection) return;

    setState(() => _isTestingConnection = true);

    try {
      final llmService = context.read<LLMService>();
      await llmService.setOllamaUrl(_ollamaUrlController.text.trim());
      final isConnected = await llmService.checkConnection();
      
      context.read<AppState>().setOllamaConnection(isConnected);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isConnected 
                  ? 'Successfully connected to Ollama!' 
                  : 'Failed to connect to Ollama',
            ),
            backgroundColor: isConnected 
                ? AppTheme.successColor 
                : AppTheme.errorColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection error: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isTestingConnection = false);
      }
    }
  }

  Future<void> _saveConnection() async {
    try {
      final llmService = context.read<LLMService>();
      await llmService.setOllamaUrl(_ollamaUrlController.text.trim());
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Connection settings saved'),
            backgroundColor: AppTheme.successColor,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save settings: ${e.toString()}'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    }
  }

  void _showWorkHoursDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Work Hours'),
        content: const Text(
          'Auto mode switching will automatically change between work and personal modes based on the current time.\n\nWork hours: 9:00 AM - 5:00 PM, Monday-Friday',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: const SingleChildScrollView(
          child: Text(
            'LocalMind Privacy Policy\n\n'
            '1. Data Processing: All data processing happens locally on your device or your personal cloud.\n\n'
            '2. No External Servers: We do not send your data to any external servers or third parties.\n\n'
            '3. Encryption: All stored data is encrypted using industry-standard encryption.\n\n'
            '4. Permissions: You have full control over what data the app can access.\n\n'
            '5. Deletion: You can delete any or all of your data at any time.\n\n'
            '6. Transparency: The Privacy Dashboard shows exactly what data has been accessed.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showHelp() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Help & Support'),
        content: const SingleChildScrollView(
          child: Text(
            'Getting Started:\n\n'
            '1. Set up Ollama on your laptop with Llama 3 model\n'
            '2. Configure the connection URL in settings\n'
            '3. Grant necessary permissions for features you want to use\n'
            '4. Start chatting or use voice input\n\n'
            'Voice Commands:\n'
            '• "Open [app name]" - Opens apps\n'
            '• "Turn on/off [setting]" - Controls system settings\n\n'
            'Mode Switching:\n'
            '• Toggle between work and personal modes\n'
            '• Automatic switching based on time\n\n'
            'Privacy:\n'
            '• Check the Privacy Dashboard for data access logs\n'
            '• Revoke permissions anytime\n'
            '• Delete data selectively or completely',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _openGitHub() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('GitHub repository: yashand/localmindV1'),
      ),
    );
  }

  @override
  void dispose() {
    _ollamaUrlController.dispose();
    super.dispose();
  }
}