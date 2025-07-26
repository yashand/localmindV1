import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/app_state.dart';
import '../services/troubleshooting_service.dart';
import '../services/llm_service.dart';
import '../utils/app_theme.dart';

class TroubleshootingScreen extends StatefulWidget {
  const TroubleshootingScreen({Key? key}) : super(key: key);

  @override
  State<TroubleshootingScreen> createState() => _TroubleshootingScreenState();
}

class _TroubleshootingScreenState extends State<TroubleshootingScreen> {
  final TroubleshootingService _troubleshootingService = TroubleshootingService();
  List<DiagnosticResult>? _diagnosticResults;
  bool _isRunningDiagnostics = false;

  @override
  void initState() {
    super.initState();
    _runDiagnostics();
  }

  Future<void> _runDiagnostics() async {
    if (_isRunningDiagnostics) return;

    setState(() {
      _isRunningDiagnostics = true;
      _diagnosticResults = null;
    });

    try {
      final llmService = context.read<LLMService>();
      final results = await _troubleshootingService.runAllDiagnostics(
        ollamaUrl: llmService.currentUrl,
      );
      
      setState(() {
        _diagnosticResults = results;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error running diagnostics: $e'),
            backgroundColor: AppTheme.errorColor,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isRunningDiagnostics = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Troubleshooting'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isRunningDiagnostics ? null : _runDiagnostics,
            tooltip: 'Run diagnostics again',
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'export',
                child: Row(
                  children: [
                    Icon(Icons.file_download),
                    SizedBox(width: 8),
                    Text('Export Report'),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 'help',
                child: Row(
                  children: [
                    Icon(Icons.help),
                    SizedBox(width: 8),
                    Text('Common Issues'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _runDiagnostics,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isRunningDiagnostics) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Running diagnostics...'),
            SizedBox(height: 8),
            Text(
              'This may take a few seconds',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    if (_diagnosticResults == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning, size: 64, color: Colors.orange),
            SizedBox(height: 16),
            Text('No diagnostic results available'),
            SizedBox(height: 8),
            Text('Pull down to refresh or tap the refresh button'),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSummaryCard(),
        const SizedBox(height: 16),
        ..._buildDiagnosticSections(),
      ],
    );
  }

  Widget _buildSummaryCard() {
    if (_diagnosticResults == null) return const SizedBox.shrink();

    final passed = _diagnosticResults!.where((r) => r.status == DiagnosticStatus.passed).length;
    final warnings = _diagnosticResults!.where((r) => r.status == DiagnosticStatus.warning).length;
    final failed = _diagnosticResults!.where((r) => r.status == DiagnosticStatus.failed).length;
    final total = _diagnosticResults!.where((r) => r.status != DiagnosticStatus.info).length;

    final overallHealth = failed == 0 
        ? (warnings == 0 ? 'Excellent' : 'Good') 
        : 'Needs Attention';
    
    final healthColor = failed == 0 
        ? (warnings == 0 ? AppTheme.successColor : Colors.orange) 
        : AppTheme.errorColor;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  failed == 0 ? Icons.check_circle : Icons.warning,
                  color: healthColor,
                ),
                const SizedBox(width: 8),
                Text(
                  'System Health: $overallHealth',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: healthColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatusIndicator('Passed', passed, AppTheme.successColor),
                ),
                Expanded(
                  child: _buildStatusIndicator('Warnings', warnings, Colors.orange),
                ),
                Expanded(
                  child: _buildStatusIndicator('Failed', failed, AppTheme.errorColor),
                ),
              ],
            ),
            if (failed > 0 || warnings > 0) ...[
              const SizedBox(height: 16),
              Text(
                failed > 0 
                    ? 'Some features may not work properly. Check the failed items below.'
                    : 'Minor issues detected. Review warnings for optimal performance.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: failed > 0 ? AppTheme.errorColor : Colors.orange,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusIndicator(String label, int count, Color color) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: color,
          ),
        ),
      ],
    );
  }

  List<Widget> _buildDiagnosticSections() {
    if (_diagnosticResults == null) return [];

    final sections = {
      'Ollama Connection': _diagnosticResults!.where((r) => 
          r.title.contains('Ollama') || 
          r.title.contains('Llama') || 
          r.title.contains('Tailscale')).toList(),
      'Voice Recognition': _diagnosticResults!.where((r) => 
          r.title.contains('Microphone') || 
          r.title.contains('Speech')).toList(),
      'App Automation': _diagnosticResults!.where((r) => 
          r.title.contains('Accessibility') || 
          r.title.contains('Target Apps') || 
          r.title.contains('iOS Shortcuts')).toList(),
      'System Information': _diagnosticResults!.where((r) => 
          r.title.contains('System Information')).toList(),
    };

    final widgets = <Widget>[];
    
    for (final section in sections.entries) {
      if (section.value.isNotEmpty) {
        widgets.add(_buildSection(section.key, section.value));
        widgets.add(const SizedBox(height: 16));
      }
    }

    return widgets;
  }

  Widget _buildSection(String title, List<DiagnosticResult> results) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _getSectionIcon(title),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ],
            ),
          ),
          ...results.map((result) => _buildDiagnosticTile(result)),
        ],
      ),
    );
  }

  Widget _getSectionIcon(String title) {
    switch (title) {
      case 'Ollama Connection':
        return const Icon(Icons.cloud_outlined);
      case 'Voice Recognition':
        return const Icon(Icons.mic);
      case 'App Automation':
        return const Icon(Icons.smartphone);
      case 'System Information':
        return const Icon(Icons.info_outline);
      default:
        return const Icon(Icons.check_circle_outline);
    }
  }

  Widget _buildDiagnosticTile(DiagnosticResult result) {
    return ExpansionTile(
      leading: _getStatusIcon(result.status),
      title: Text(result.title),
      subtitle: Text(result.description),
      children: [
        if (result.details != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                result.details!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                ),
              ),
            ),
          ),
        if (result.solutions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Solutions:',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                ...result.solutions.map((solution) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('• '),
                      Expanded(child: Text(solution)),
                    ],
                  ),
                )),
              ],
            ),
          ),
      ],
    );
  }

  Widget _getStatusIcon(DiagnosticStatus status) {
    switch (status) {
      case DiagnosticStatus.passed:
        return Icon(Icons.check_circle, color: AppTheme.successColor);
      case DiagnosticStatus.warning:
        return const Icon(Icons.warning, color: Colors.orange);
      case DiagnosticStatus.failed:
        return Icon(Icons.error, color: AppTheme.errorColor);
      case DiagnosticStatus.info:
        return const Icon(Icons.info, color: Colors.blue);
    }
  }

  void _handleMenuAction(String action) {
    switch (action) {
      case 'export':
        _exportReport();
        break;
      case 'help':
        _showCommonIssuesDialog();
        break;
    }
  }

  void _exportReport() {
    if (_diagnosticResults == null) return;

    final report = _troubleshootingService.generateReport(_diagnosticResults!);
    Clipboard.setData(ClipboardData(text: report));
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Diagnostic report copied to clipboard'),
        backgroundColor: AppTheme.successColor,
      ),
    );
  }

  void _showCommonIssuesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Common Issues'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '🔧 Ollama Connection Failed',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('• Verify Ollama is running: ollama list'),
              Text('• Check firewall settings allow port 11434'),
              Text('• For Tailscale: Ensure both devices are connected'),
              SizedBox(height: 16),
              Text(
                '🎤 Voice Recognition Not Working',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('• Grant microphone permissions'),
              Text('• Test device microphone in other apps'),
              Text('• Check speech_to_text package compatibility'),
              SizedBox(height: 16),
              Text(
                '📱 App Automation Failing',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('• Enable Accessibility Service (Android)'),
              Text('• Grant necessary system permissions'),
              Text('• Verify target apps are installed'),
            ],
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
}