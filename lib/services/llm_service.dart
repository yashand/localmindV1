import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:logger/logger.dart';
import '../models/chat_message.dart';
import '../models/user_profile.dart';
import 'offline_knowledge_service.dart';

class LLMService {
  static const String _defaultOllamaUrl = 'http://localhost:11434';
  static const String _ollamaModel = 'llama3';
  static const String _ollamaUrlKey = 'ollama_url';
  
  final FlutterSecureStorage _storage;
  final Logger _logger = Logger();
  
  String? _currentOllamaUrl;
  bool _isConnected = false;

  LLMService(this._storage);

  Future<void> initialize() async {
    _currentOllamaUrl = await _storage.read(key: _ollamaUrlKey) ?? _defaultOllamaUrl;
    await checkConnection();
  }

  Future<bool> checkConnection() async {
    try {
      final response = await http.get(
        Uri.parse('$_currentOllamaUrl/api/tags'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 5));
      
      _isConnected = response.statusCode == 200;
      _logger.i('Ollama connection status: $_isConnected');
      return _isConnected;
    } catch (e) {
      _isConnected = false;
      _logger.w('Failed to connect to Ollama: $e');
      return false;
    }
  }

  Future<void> setOllamaUrl(String url) async {
    _currentOllamaUrl = url;
    await _storage.write(key: _ollamaUrlKey, value: url);
    await checkConnection();
  }

  Future<String> generateResponse(
    String prompt, 
    UserProfile profile, 
    String mode,
    {List<ChatMessage>? conversationHistory}
  ) async {
    if (!_isConnected) {
      _logger.w('Ollama not connected, using offline knowledge base');
      return OfflineKnowledgeService.getSmartResponse(prompt, mode: mode);
    }

    try {
      final systemPrompt = _buildSystemPrompt(profile, mode);
      final contextPrompt = _buildContextPrompt(conversationHistory);
      final fullPrompt = '$systemPrompt\n\n$contextPrompt\n\nUser: $prompt\nAssistant:';

      final response = await http.post(
        Uri.parse('$_currentOllamaUrl/api/generate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'model': _ollamaModel,
          'prompt': fullPrompt,
          'stream': false,
          'options': {
            'temperature': 0.7,
            'top_p': 0.9,
            'max_tokens': 1000,
          }
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['response'] ?? 'No response generated';
      } else {
        throw Exception('Ollama API error: ${response.statusCode}');
      }
    } catch (e) {
      _logger.e('Error generating response: $e');
      return OfflineKnowledgeService.getSmartResponse(prompt, mode: mode);
    }
  }

  String _buildSystemPrompt(UserProfile profile, String mode) {
    final modeContext = mode == 'work' 
        ? 'You are in work mode. Be professional, concise, and focus on productivity.'
        : 'You are in personal mode. Be friendly, casual, and helpful with personal tasks.';
    
    final preferences = profile.preferences;
    final preferencesText = preferences.isNotEmpty 
        ? 'User preferences: ${preferences.toString()}'
        : '';

    return '''You are LocalMind, a privacy-focused AI assistant running locally. 
$modeContext

You can help with:
- Answering questions and providing information
- Automating phone tasks (opening apps, controlling settings)
- Managing schedules and reminders
- Personal productivity and organization

$preferencesText

Always prioritize user privacy and local processing. Be helpful but respect boundaries.''';
  }

  String _buildContextPrompt(List<ChatMessage>? history) {
    if (history == null || history.isEmpty) return '';
    
    final recentMessages = history.take(5).map((msg) {
      final role = msg.isUser ? 'User' : 'Assistant';
      return '$role: ${msg.content}';
    }).join('\n');
    
    return 'Recent conversation:\n$recentMessages';
  }

  bool get isConnected => _isConnected;
  String? get currentUrl => _currentOllamaUrl;
}