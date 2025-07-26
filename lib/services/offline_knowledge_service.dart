import 'dart:convert';
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:yaml/yaml.dart';
import 'package:logger/logger.dart';

class OfflineKnowledgeService {
  static Map<String, dynamic>? _knowledgeBase;
  static final Random _random = Random();
  static final Logger _logger = Logger();
  
  // Initialize knowledge base from assets
  static Future<void> initialize() async {
    try {
      final yamlString = await rootBundle.loadString('assets/knowledge/offline_responses.yaml');
      final yamlMap = loadYaml(yamlString);
      _knowledgeBase = Map<String, dynamic>.from(yamlMap);
      _logger.i('Offline knowledge base loaded successfully');
    } catch (e) {
      _logger.e('Error loading offline knowledge base: $e');
      _initializeFallbackResponses();
    }
  }
  
  // Get contextual response based on category and time
  static String getResponse(String category, {String? subcategory, String? mode}) {
    if (_knowledgeBase == null) {
      return "I'm here to help, but my knowledge base isn't loaded yet.";
    }
    
    try {
      // Handle time-based greetings
      if (category == 'greetings') {
        return _getTimeBasedGreeting();
      }
      
      // Handle mode-specific responses
      if (mode != null && _knowledgeBase!.containsKey('${category}_$mode')) {
        category = '${category}_$mode';
      }
      
      final categoryResponses = _knowledgeBase![category];
      if (categoryResponses == null) return _getDefaultResponse();
      
      // Handle subcategories
      if (subcategory != null && categoryResponses[subcategory] != null) {
        final responses = List<String>.from(categoryResponses[subcategory]);
        return responses[_random.nextInt(responses.length)];
      }
      
      // Handle flat category responses
      if (categoryResponses is List) {
        final responses = List<String>.from(categoryResponses);
        return responses[_random.nextInt(responses.length)];
      }
      
      // Handle nested categories - pick random subcategory
      final subcategories = categoryResponses.keys.toList();
      final randomSubcategory = subcategories[_random.nextInt(subcategories.length)];
      final responses = List<String>.from(categoryResponses[randomSubcategory]);
      return responses[_random.nextInt(responses.length)];
      
    } catch (e) {
      _logger.e('Error getting response for $category: $e');
      return _getDefaultResponse();
    }
  }
  
  // Smart greeting based on time of day
  static String _getTimeBasedGreeting() {
    final hour = DateTime.now().hour;
    String timeCategory;
    
    if (hour >= 5 && hour < 12) {
      timeCategory = 'morning';
    } else if (hour >= 12 && hour < 17) {
      timeCategory = 'afternoon';
    } else if (hour >= 17 && hour < 22) {
      timeCategory = 'evening';
    } else {
      timeCategory = 'general';
    }
    
    return getResponse('greetings', subcategory: timeCategory);
  }
  
  // Fallback responses if YAML fails to load
  static void _initializeFallbackResponses() {
    _knowledgeBase = {
      'greetings': {
        'general': [
          "Hello! LocalMind is ready to help.",
          "Hi there! Your privacy-first assistant is here.",
          "Welcome! How can I assist you today?"
        ]
      },
      'automation_help': {
        'basic_commands': [
          "I can help open apps and control your device.",
          "Try commands like 'Open Spotify' or 'Turn on WiFi'.",
          "Voice commands work great for hands-free control."
        ]
      },
      'privacy_info': {
        'data_protection': [
          "Your data stays on your device - never sent to external servers.",
          "Check Privacy Dashboard for complete data transparency.",
          "You control all permissions and can delete data anytime."
        ]
      }
    };
    _logger.w('Using fallback knowledge base due to loading error');
  }
  
  static String _getDefaultResponse() {
    return "I'm here to help! Try asking about automation, privacy, or switching modes.";
  }
  
  // Get help for specific features
  static String getFeatureHelp(String feature) {
    final helpMap = {
      'voice': getResponse('automation_help', subcategory: 'troubleshooting'),
      'privacy': getResponse('privacy_info', subcategory: 'user_control'),
      'automation': getResponse('automation_help', subcategory: 'advanced_examples'),
      'work_mode': getResponse('work_mode', subcategory: 'capabilities'),
      'personal_mode': getResponse('personal_mode', subcategory: 'lifestyle'),
      'connection': getResponse('connection_issues', subcategory: 'laptop_offline'),
    };
    
    return helpMap[feature] ?? getResponse('automation_help', subcategory: 'basic_commands');
  }
  
  // Smart intent detection for offline responses
  static String getSmartResponse(String prompt, {String? mode}) {
    final lowerPrompt = prompt.toLowerCase();
    
    // Greeting detection
    if (lowerPrompt.contains('hello') || lowerPrompt.contains('hi') || 
        lowerPrompt.contains('hey') || lowerPrompt.contains('good morning') ||
        lowerPrompt.contains('good afternoon') || lowerPrompt.contains('good evening')) {
      return getResponse('greetings');
    }
    
    // Privacy-related queries
    if (lowerPrompt.contains('privacy') || lowerPrompt.contains('data') ||
        lowerPrompt.contains('secure') || lowerPrompt.contains('safe')) {
      return getResponse('privacy_info', subcategory: 'data_protection');
    }
    
    // Automation and app control
    if (lowerPrompt.contains('open') || lowerPrompt.contains('launch') ||
        lowerPrompt.contains('start') || lowerPrompt.contains('automation')) {
      return getResponse('automation_help', subcategory: 'basic_commands');
    }
    
    // Work mode specific
    if ((lowerPrompt.contains('work') || lowerPrompt.contains('business') ||
         lowerPrompt.contains('professional')) && mode == 'work') {
      return getResponse('work_mode', subcategory: 'capabilities');
    }
    
    // Personal mode specific  
    if ((lowerPrompt.contains('personal') || lowerPrompt.contains('home') ||
         lowerPrompt.contains('entertainment')) || mode == 'personal') {
      return getResponse('personal_mode', subcategory: 'lifestyle');
    }
    
    // Connection issues
    if (lowerPrompt.contains('offline') || lowerPrompt.contains('connection') ||
        lowerPrompt.contains('server') || lowerPrompt.contains('network')) {
      return getResponse('connection_issues', subcategory: 'laptop_offline');
    }
    
    // Voice/speech issues
    if (lowerPrompt.contains('voice') || lowerPrompt.contains('speech') ||
        lowerPrompt.contains('microphone') || lowerPrompt.contains('listen')) {
      return getResponse('connection_issues', subcategory: 'voice_recognition');
    }
    
    // Help and learning
    if (lowerPrompt.contains('help') || lowerPrompt.contains('how') ||
        lowerPrompt.contains('learn') || lowerPrompt.contains('teach')) {
      return getResponse('learning_responses', subcategory: 'feedback_requests');
    }
    
    // Default fallback with mode awareness
    if (mode == 'work') {
      return "I'm currently offline but ready to help with work tasks. Could you rephrase your request?";
    } else {
      return "I'm in offline mode right now, but I'm here to help however I can!";
    }
  }
}