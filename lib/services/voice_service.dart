import 'package:speech_to_text/speech_to_text.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:logger/logger.dart';

class VoiceService {
  final SpeechToText _speechToText = SpeechToText();
  final Logger _logger = Logger();
  
  bool _isListening = false;
  bool _isAvailable = false;
  String _recognizedText = '';
  
  bool get isListening => _isListening;
  bool get isAvailable => _isAvailable;
  String get recognizedText => _recognizedText;

  Future<bool> initialize() async {
    try {
      // Request microphone permission
      final status = await Permission.microphone.request();
      if (status != PermissionStatus.granted) {
        _logger.w('Microphone permission denied');
        return false;
      }

      // Initialize speech to text
      _isAvailable = await _speechToText.initialize(
        onStatus: _onStatusChanged,
        onError: _onError,
      );
      
      _logger.i('Voice service initialized: $_isAvailable');
      return _isAvailable;
    } catch (e) {
      _logger.e('Failed to initialize voice service: $e');
      return false;
    }
  }

  Future<void> startListening({
    required Function(String) onResult,
    String? localeId,
  }) async {
    if (!_isAvailable || _isListening) return;

    try {
      await _speechToText.listen(
        onResult: (result) {
          _recognizedText = result.recognizedWords;
          onResult(_recognizedText);
        },
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
        partialResults: true,
        localeId: localeId ?? 'en_US',
        onSoundLevelChange: null,
        cancelOnError: true,
        listenMode: ListenMode.confirmation,
      );
      
      _isListening = true;
      _logger.i('Started listening for voice input');
    } catch (e) {
      _logger.e('Failed to start listening: $e');
    }
  }

  Future<void> stopListening() async {
    if (!_isListening) return;

    try {
      await _speechToText.stop();
      _isListening = false;
      _logger.i('Stopped listening for voice input');
    } catch (e) {
      _logger.e('Failed to stop listening: $e');
    }
  }

  Future<void> cancelListening() async {
    if (!_isListening) return;

    try {
      await _speechToText.cancel();
      _isListening = false;
      _recognizedText = '';
      _logger.i('Cancelled voice input');
    } catch (e) {
      _logger.e('Failed to cancel listening: $e');
    }
  }

  List<LocaleName> getAvailableLocales() {
    return _speechToText.locales;
  }

  void _onStatusChanged(String status) {
    _logger.d('Speech recognition status: $status');
    
    switch (status) {
      case 'listening':
        _isListening = true;
        break;
      case 'notListening':
        _isListening = false;
        break;
      case 'done':
        _isListening = false;
        break;
    }
  }

  void _onError(dynamic error) {
    _logger.e('Speech recognition error: $error');
    _isListening = false;
  }

  void dispose() {
    if (_isListening) {
      stopListening();
    }
  }
}