import 'dart:io';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:logger/logger.dart';
import 'package:device_info_plus/device_info_plus.dart';

enum DiagnosticStatus { passed, warning, failed, info }

class DiagnosticResult {
  final String title;
  final String description;
  final DiagnosticStatus status;
  final List<String> solutions;
  final String? details;

  DiagnosticResult({
    required this.title,
    required this.description,
    required this.status,
    required this.solutions,
    this.details,
  });
}

class TroubleshootingService {
  final Logger _logger = Logger();

  /// Run all diagnostics and return results
  Future<List<DiagnosticResult>> runAllDiagnostics({
    String? ollamaUrl,
  }) async {
    final results = <DiagnosticResult>[];
    
    // Ollama Connection Diagnostics
    results.addAll(await _diagnoseLlamaConnection(ollamaUrl));
    
    // Voice Recognition Diagnostics
    results.addAll(await _diagnoseVoiceRecognition());
    
    // App Automation Diagnostics
    results.addAll(await _diagnoseAppAutomation());
    
    // System Information
    results.addAll(await _getSystemInformation());
    
    return results;
  }

  /// Diagnose Ollama connection issues
  Future<List<DiagnosticResult>> _diagnoseLlamaConnection(String? ollamaUrl) async {
    final results = <DiagnosticResult>[];
    final url = ollamaUrl ?? 'http://localhost:11434';
    
    _logger.i('Diagnosing Ollama connection to: $url');
    
    // Test basic connectivity
    try {
      final response = await http.get(
        Uri.parse('$url/api/tags'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        results.add(DiagnosticResult(
          title: 'Ollama Connection',
          description: 'Successfully connected to Ollama server',
          status: DiagnosticStatus.passed,
          solutions: [],
          details: 'Response: ${response.statusCode}',
        ));
        
        // Test model availability
        try {
          final modelResponse = await http.post(
            Uri.parse('$url/api/show'),
            headers: {'Content-Type': 'application/json'},
            body: '{"name": "llama3"}',
          ).timeout(const Duration(seconds: 5));
          
          if (modelResponse.statusCode == 200) {
            results.add(DiagnosticResult(
              title: 'Llama3 Model',
              description: 'Llama3 model is available',
              status: DiagnosticStatus.passed,
              solutions: [],
            ));
          } else {
            results.add(DiagnosticResult(
              title: 'Llama3 Model',
              description: 'Llama3 model not found or not loaded',
              status: DiagnosticStatus.warning,
              solutions: [
                'Run: ollama pull llama3',
                'Verify model name is correct',
                'Check available models with: ollama list',
              ],
            ));
          }
        } catch (e) {
          results.add(DiagnosticResult(
            title: 'Llama3 Model',
            description: 'Could not verify model availability',
            status: DiagnosticStatus.warning,
            solutions: [
              'Ensure Llama3 model is pulled: ollama pull llama3',
              'Check model status: ollama list',
            ],
            details: e.toString(),
          ));
        }
      } else {
        results.add(DiagnosticResult(
          title: 'Ollama Connection',
          description: 'Ollama server responded with error: ${response.statusCode}',
          status: DiagnosticStatus.failed,
          solutions: [
            'Verify Ollama is running: ollama serve',
            'Check if port 11434 is available',
            'Restart Ollama service',
          ],
          details: 'HTTP ${response.statusCode}: ${response.body}',
        ));
      }
    } catch (e) {
      if (e.toString().contains('TimeoutException')) {
        results.add(DiagnosticResult(
          title: 'Ollama Connection',
          description: 'Connection timeout - Ollama server not responding',
          status: DiagnosticStatus.failed,
          solutions: [
            'Verify Ollama is running: ollama list',
            'Check firewall settings allow port 11434',
            'For Tailscale: Ensure both devices are connected',
            'Try using IP address instead of localhost',
          ],
          details: 'Timeout after 10 seconds',
        ));
      } else if (e.toString().contains('SocketException')) {
        results.add(DiagnosticResult(
          title: 'Ollama Connection',
          description: 'Cannot connect to Ollama server',
          status: DiagnosticStatus.failed,
          solutions: [
            'Verify Ollama is installed and running',
            'Check the server URL is correct',
            'Ensure port 11434 is not blocked by firewall',
            'For Tailscale: Verify connection with tailscale status',
          ],
          details: e.toString(),
        ));
      } else {
        results.add(DiagnosticResult(
          title: 'Ollama Connection',
          description: 'Failed to connect to Ollama',
          status: DiagnosticStatus.failed,
          solutions: [
            'Verify Ollama is running: ollama serve',
            'Check network connectivity',
            'Verify server URL format',
          ],
          details: e.toString(),
        ));
      }
    }
    
    // Check if using Tailscale
    if (url.contains('100.') || url.contains('tailscale')) {
      results.add(DiagnosticResult(
        title: 'Tailscale Configuration',
        description: 'Using Tailscale for connection',
        status: DiagnosticStatus.info,
        solutions: [
          'Verify both devices are connected to Tailscale',
          'Check Tailscale status with: tailscale status',
          'Ensure Ollama allows connections from other devices',
        ],
      ));
    }
    
    return results;
  }

  /// Diagnose voice recognition issues
  Future<List<DiagnosticResult>> _diagnoseVoiceRecognition() async {
    final results = <DiagnosticResult>[];
    
    _logger.i('Diagnosing voice recognition');
    
    // Check microphone permission
    final micPermission = await Permission.microphone.status;
    if (micPermission.isGranted) {
      results.add(DiagnosticResult(
        title: 'Microphone Permission',
        description: 'Microphone permission granted',
        status: DiagnosticStatus.passed,
        solutions: [],
      ));
    } else {
      results.add(DiagnosticResult(
        title: 'Microphone Permission',
        description: 'Microphone permission not granted',
        status: DiagnosticStatus.failed,
        solutions: [
          'Grant microphone permissions in app settings',
          'Go to Settings > Apps > LocalMind > Permissions',
          'Enable microphone access',
        ],
        details: 'Permission status: ${micPermission.name}',
      ));
    }
    
    // Test speech recognition availability
    try {
      final speechToText = SpeechToText();
      final isAvailable = await speechToText.initialize();
      
      if (isAvailable) {
        results.add(DiagnosticResult(
          title: 'Speech Recognition',
          description: 'Speech recognition service is available',
          status: DiagnosticStatus.passed,
          solutions: [],
        ));
        
        // Check available locales
        final locales = speechToText.locales;
        results.add(DiagnosticResult(
          title: 'Speech Locales',
          description: 'Found ${locales.length} available language locales',
          status: DiagnosticStatus.info,
          solutions: [],
          details: 'Available locales: ${locales.map((l) => l.localeId).take(5).join(', ')}${locales.length > 5 ? '...' : ''}',
        ));
      } else {
        results.add(DiagnosticResult(
          title: 'Speech Recognition',
          description: 'Speech recognition service not available',
          status: DiagnosticStatus.failed,
          solutions: [
            'Restart the app and try again',
            'Check if device microphone works in other apps',
            'Verify speech_to_text package compatibility',
            'Update speech recognition services in device settings',
          ],
        ));
      }
    } catch (e) {
      results.add(DiagnosticResult(
        title: 'Speech Recognition',
        description: 'Error initializing speech recognition',
        status: DiagnosticStatus.failed,
        solutions: [
          'Test device microphone in other apps',
          'Check speech_to_text package compatibility',
          'Restart the app',
          'Clear app cache and data',
        ],
        details: e.toString(),
      ));
    }
    
    return results;
  }

  /// Diagnose app automation issues
  Future<List<DiagnosticResult>> _diagnoseAppAutomation() async {
    final results = <DiagnosticResult>[];
    
    _logger.i('Diagnosing app automation');
    
    if (Platform.isAndroid) {
      // Check accessibility permissions (Android)
      try {
        results.add(DiagnosticResult(
          title: 'Accessibility Service',
          description: 'Accessibility permissions required for app automation',
          status: DiagnosticStatus.info,
          solutions: [
            'Enable Accessibility Service in Android settings',
            'Go to Settings > Accessibility > LocalMind',
            'Toggle on the accessibility service',
            'Grant necessary system permissions',
          ],
        ));
      } catch (e) {
        results.add(DiagnosticResult(
          title: 'Accessibility Service',
          description: 'Cannot check accessibility service status',
          status: DiagnosticStatus.warning,
          solutions: [
            'Manually verify accessibility service is enabled',
            'Go to Settings > Accessibility > LocalMind',
          ],
          details: e.toString(),
        ));
      }
      
      // Check common app installations
      final commonApps = [
        {'package': 'com.spotify.music', 'name': 'Spotify'},
        {'package': 'com.google.android.youtube', 'name': 'YouTube'},
        {'package': 'com.google.android.gm', 'name': 'Gmail'},
        {'package': 'com.google.android.calendar', 'name': 'Calendar'},
      ];
      
      results.add(DiagnosticResult(
        title: 'Target Apps',
        description: 'Common automation target apps should be installed',
        status: DiagnosticStatus.info,
        solutions: [
          'Install target apps from Google Play Store',
          'Verify app package names are correct',
          'Ensure apps are up to date',
        ],
        details: 'Common apps: ${commonApps.map((app) => app['name']).join(', ')}',
      ));
      
    } else if (Platform.isIOS) {
      results.add(DiagnosticResult(
        title: 'iOS Shortcuts',
        description: 'iOS automation uses Shortcuts app integration',
        status: DiagnosticStatus.info,
        solutions: [
          'Ensure Shortcuts app is available',
          'Grant necessary permissions when prompted',
          'Configure shortcuts for frequently used apps',
        ],
      ));
    }
    
    return results;
  }

  /// Get system information for diagnostics
  Future<List<DiagnosticResult>> _getSystemInformation() async {
    final results = <DiagnosticResult>[];
    
    try {
      final deviceInfo = DeviceInfoPlugin();
      
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        results.add(DiagnosticResult(
          title: 'System Information',
          description: 'Android device information',
          status: DiagnosticStatus.info,
          solutions: [],
          details: 'Android ${androidInfo.version.release} (API ${androidInfo.version.sdkInt}) '
                  'on ${androidInfo.manufacturer} ${androidInfo.model}',
        ));
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        results.add(DiagnosticResult(
          title: 'System Information',
          description: 'iOS device information',
          status: DiagnosticStatus.info,
          solutions: [],
          details: 'iOS ${iosInfo.systemVersion} on ${iosInfo.model}',
        ));
      }
    } catch (e) {
      results.add(DiagnosticResult(
        title: 'System Information',
        description: 'Could not retrieve device information',
        status: DiagnosticStatus.warning,
        solutions: [],
        details: e.toString(),
      ));
    }
    
    return results;
  }

  /// Generate a troubleshooting report
  String generateReport(List<DiagnosticResult> results) {
    final buffer = StringBuffer();
    buffer.writeln('LocalMind Troubleshooting Report');
    buffer.writeln('Generated: ${DateTime.now().toLocal()}');
    buffer.writeln('=' * 50);
    buffer.writeln();
    
    final categories = {
      'Ollama Connection': results.where((r) => r.title.contains('Ollama') || r.title.contains('Llama') || r.title.contains('Tailscale')),
      'Voice Recognition': results.where((r) => r.title.contains('Microphone') || r.title.contains('Speech')),
      'App Automation': results.where((r) => r.title.contains('Accessibility') || r.title.contains('Target Apps') || r.title.contains('iOS Shortcuts')),
      'System Information': results.where((r) => r.title.contains('System Information')),
    };
    
    for (final category in categories.entries) {
      if (category.value.isNotEmpty) {
        buffer.writeln('## ${category.key}');
        buffer.writeln();
        
        for (final result in category.value) {
          buffer.writeln('### ${result.title}');
          buffer.writeln('Status: ${result.status.name.toUpperCase()}');
          buffer.writeln('Description: ${result.description}');
          
          if (result.details != null) {
            buffer.writeln('Details: ${result.details}');
          }
          
          if (result.solutions.isNotEmpty) {
            buffer.writeln('Solutions:');
            for (final solution in result.solutions) {
              buffer.writeln('- $solution');
            }
          }
          buffer.writeln();
        }
      }
    }
    
    return buffer.toString();
  }
}