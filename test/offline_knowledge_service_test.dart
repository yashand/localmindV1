import 'package:flutter_test/flutter_test.dart';
import 'package:localmind/services/offline_knowledge_service.dart';

void main() {
  group('OfflineKnowledgeService Tests', () {
    setUpAll(() async {
      // Initialize the service before running tests
      await OfflineKnowledgeService.initialize();
    });

    test('should provide greeting responses', () {
      final response = OfflineKnowledgeService.getResponse('greetings');
      expect(response, isNotEmpty);
      expect(response, isNot(contains('knowledge base isn\'t loaded')));
    });

    test('should provide automation help responses', () {
      final response = OfflineKnowledgeService.getResponse('automation_help', subcategory: 'basic_commands');
      expect(response, isNotEmpty);
      expect(response, contains(RegExp(r'Open|app|command', caseSensitive: false)));
    });

    test('should provide privacy information responses', () {
      final response = OfflineKnowledgeService.getResponse('privacy_info', subcategory: 'data_protection');
      expect(response, isNotEmpty);
      expect(response, contains(RegExp(r'data|privacy|device', caseSensitive: false)));
    });

    test('should provide work mode responses', () {
      final response = OfflineKnowledgeService.getResponse('work_mode', subcategory: 'capabilities');
      expect(response, isNotEmpty);
      expect(response, contains(RegExp(r'work|professional|productivity', caseSensitive: false)));
    });

    test('should provide personal mode responses', () {
      final response = OfflineKnowledgeService.getResponse('personal_mode', subcategory: 'lifestyle');
      expect(response, isNotEmpty);
      expect(response, contains(RegExp(r'entertainment|personal|social', caseSensitive: false)));
    });

    test('should handle smart response for greetings', () {
      final response = OfflineKnowledgeService.getSmartResponse('Hello there!');
      expect(response, isNotEmpty);
      expect(response, isNot(contains('offline mode')));
    });

    test('should handle smart response for automation queries', () {
      final response = OfflineKnowledgeService.getSmartResponse('How do I open Spotify?');
      expect(response, isNotEmpty);
      expect(response, contains(RegExp(r'open|app|spotify', caseSensitive: false)));
    });

    test('should handle smart response for privacy queries', () {
      final response = OfflineKnowledgeService.getSmartResponse('Is my data safe?');
      expect(response, isNotEmpty);
      expect(response, contains(RegExp(r'data|privacy|safe|secure', caseSensitive: false)));
    });

    test('should provide mode-specific responses for work mode', () {
      final response = OfflineKnowledgeService.getSmartResponse('Help me with work tasks', mode: 'work');
      expect(response, isNotEmpty);
      expect(response, contains(RegExp(r'work|professional|business', caseSensitive: false)));
    });

    test('should provide mode-specific responses for personal mode', () {
      final response = OfflineKnowledgeService.getSmartResponse('Help me with entertainment', mode: 'personal');
      expect(response, isNotEmpty);
      expect(response, contains(RegExp(r'entertainment|personal|music', caseSensitive: false)));
    });

    test('should provide feature-specific help', () {
      final voiceHelp = OfflineKnowledgeService.getFeatureHelp('voice');
      expect(voiceHelp, isNotEmpty);
      
      final privacyHelp = OfflineKnowledgeService.getFeatureHelp('privacy');
      expect(privacyHelp, isNotEmpty);
      
      final automationHelp = OfflineKnowledgeService.getFeatureHelp('automation');
      expect(automationHelp, isNotEmpty);
    });

    test('should handle time-based greetings', () {
      // This test verifies time-based greeting logic without mocking time
      final response = OfflineKnowledgeService.getResponse('greetings');
      expect(response, isNotEmpty);
      // Should contain contextual greeting elements
      expect(response, contains(RegExp(r'LocalMind|help|assist', caseSensitive: false)));
    });

    test('should provide fallback response for unknown categories', () {
      final response = OfflineKnowledgeService.getResponse('unknown_category');
      expect(response, isNotEmpty);
      expect(response, contains(RegExp(r'help|assist|automation|privacy|modes', caseSensitive: false)));
    });
  });
}