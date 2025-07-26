import 'package:flutter_test/flutter_test.dart';
import 'package:localmind/services/troubleshooting_service.dart';

void main() {
  group('TroubleshootingService Tests', () {
    late TroubleshootingService troubleshootingService;

    setUp(() {
      troubleshootingService = TroubleshootingService();
    });

    test('should create diagnostic result correctly', () {
      final result = DiagnosticResult(
        title: 'Test Diagnostic',
        description: 'Test description',
        status: DiagnosticStatus.passed,
        solutions: ['Solution 1', 'Solution 2'],
        details: 'Test details',
      );

      expect(result.title, 'Test Diagnostic');
      expect(result.description, 'Test description');
      expect(result.status, DiagnosticStatus.passed);
      expect(result.solutions.length, 2);
      expect(result.details, 'Test details');
    });

    test('should generate report from diagnostic results', () {
      final results = [
        DiagnosticResult(
          title: 'Ollama Connection',
          description: 'Connection test',
          status: DiagnosticStatus.passed,
          solutions: [],
        ),
        DiagnosticResult(
          title: 'Microphone Permission',
          description: 'Permission test',
          status: DiagnosticStatus.failed,
          solutions: ['Grant permission'],
        ),
      ];

      final report = troubleshootingService.generateReport(results);
      
      expect(report.contains('LocalMind Troubleshooting Report'), isTrue);
      expect(report.contains('Ollama Connection'), isTrue);
      expect(report.contains('Microphone Permission'), isTrue);
      expect(report.contains('Grant permission'), isTrue);
    });

    test('should handle empty diagnostic results', () {
      final report = troubleshootingService.generateReport([]);
      
      expect(report.contains('LocalMind Troubleshooting Report'), isTrue);
      expect(report.isNotEmpty, isTrue);
    });

    test('should categorize results correctly in report', () {
      final results = [
        DiagnosticResult(
          title: 'Ollama Connection',
          description: 'Test',
          status: DiagnosticStatus.passed,
          solutions: [],
        ),
        DiagnosticResult(
          title: 'Speech Recognition',
          description: 'Test',
          status: DiagnosticStatus.warning,
          solutions: [],
        ),
        DiagnosticResult(
          title: 'System Information',
          description: 'Test',
          status: DiagnosticStatus.info,
          solutions: [],
        ),
      ];

      final report = troubleshootingService.generateReport(results);
      
      expect(report.contains('## Ollama Connection'), isTrue);
      expect(report.contains('## Voice Recognition'), isTrue);
      expect(report.contains('## System Information'), isTrue);
    });

    test('diagnostic status enum should have correct values', () {
      expect(DiagnosticStatus.passed.name, 'passed');
      expect(DiagnosticStatus.warning.name, 'warning');
      expect(DiagnosticStatus.failed.name, 'failed');
      expect(DiagnosticStatus.info.name, 'info');
    });
  });
}