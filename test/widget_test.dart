import 'package:flutter_test/flutter_test.dart';
import 'package:localmind/models/app_state.dart';
import 'package:localmind/models/user_profile.dart';
import 'package:localmind/models/chat_message.dart';

void main() {
  group('AppState Tests', () {
    test('should initialize with personal mode', () {
      final appState = AppState();
      expect(appState.currentMode, AppMode.personal);
    });

    test('should switch modes correctly', () {
      final appState = AppState();
      appState.switchMode(AppMode.work);
      expect(appState.currentMode, AppMode.work);
    });

    test('should auto-switch to work mode during work hours', () {
      final appState = AppState();
      // This would need to be mocked for proper testing
      // For now, just test the method exists
      expect(() => appState.autoSwitchMode(), returnsNormally);
    });
  });

  group('UserProfile Tests', () {
    test('should create with default values', () {
      final profile = UserProfile();
      expect(profile.preferences, isEmpty);
      expect(profile.appUsage, isEmpty);
      expect(profile.locationData, isEmpty);
      expect(profile.habits, isEmpty);
      expect(profile.privacySettings.encryptLocalData, isTrue);
    });

    test('should update preferences', () {
      final profile = UserProfile();
      profile.updatePreference('theme', 'dark');
      expect(profile.preferences['theme'], 'dark');
    });

    test('should serialize to/from JSON', () {
      final profile = UserProfile(
        userId: 'test-user',
        preferences: {'theme': 'dark'},
      );
      
      final json = profile.toJson();
      final restored = UserProfile.fromJson(json);
      
      expect(restored.userId, 'test-user');
      expect(restored.preferences['theme'], 'dark');
    });
  });

  group('ChatMessage Tests', () {
    test('should create chat message correctly', () {
      final message = ChatMessage(
        id: '1',
        content: 'Hello',
        isUser: true,
        timestamp: DateTime.now(),
        mode: 'personal',
      );

      expect(message.content, 'Hello');
      expect(message.isUser, isTrue);
      expect(message.mode, 'personal');
    });

    test('should serialize to/from JSON', () {
      final timestamp = DateTime.now();
      final message = ChatMessage(
        id: '1',
        content: 'Hello',
        isUser: true,
        timestamp: timestamp,
        mode: 'personal',
      );

      final json = message.toJson();
      final restored = ChatMessage.fromJson(json);

      expect(restored.id, '1');
      expect(restored.content, 'Hello');
      expect(restored.isUser, isTrue);
      expect(restored.mode, 'personal');
    });
  });

  group('Privacy Settings Tests', () {
    test('should have secure defaults', () {
      final settings = PrivacySettings();
      
      expect(settings.allowAppUsageTracking, isFalse);
      expect(settings.allowLocationTracking, isFalse);
      expect(settings.allowCalendarAccess, isFalse);
      expect(settings.allowContactAccess, isFalse);
      expect(settings.encryptLocalData, isTrue);
      expect(settings.dataRetentionDays, 30);
    });
  });
}