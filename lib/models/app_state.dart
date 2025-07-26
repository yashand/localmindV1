import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show ThemeMode;

enum AppMode { work, personal }

class AppState extends ChangeNotifier {
  AppMode _currentMode = AppMode.personal;
  ThemeMode _themeMode = ThemeMode.system;
  bool _isConnectedToOllama = false;
  bool _isVoiceEnabled = false;
  String? _lastError;
  
  // Getters
  AppMode get currentMode => _currentMode;
  ThemeMode get themeMode => _themeMode;
  bool get isConnectedToOllama => _isConnectedToOllama;
  bool get isVoiceEnabled => _isVoiceEnabled;
  String? get lastError => _lastError;
  
  // Mode switching
  void switchMode(AppMode mode) {
    if (_currentMode != mode) {
      _currentMode = mode;
      notifyListeners();
    }
  }
  
  void autoSwitchMode() {
    final now = DateTime.now();
    final isWorkHours = now.hour >= 9 && now.hour < 17 && 
                       now.weekday >= 1 && now.weekday <= 5;
    
    final newMode = isWorkHours ? AppMode.work : AppMode.personal;
    if (_currentMode != newMode) {
      switchMode(newMode);
    }
  }
  
  // Theme
  void setThemeMode(ThemeMode mode) {
    _themeMode = mode;
    notifyListeners();
  }
  
  // Connection status
  void setOllamaConnection(bool connected) {
    _isConnectedToOllama = connected;
    notifyListeners();
  }
  
  // Voice status
  void setVoiceEnabled(bool enabled) {
    _isVoiceEnabled = enabled;
    notifyListeners();
  }
  
  // Error handling
  void setError(String? error) {
    _lastError = error;
    notifyListeners();
  }
  
  void clearError() {
    _lastError = null;
    notifyListeners();
  }
}