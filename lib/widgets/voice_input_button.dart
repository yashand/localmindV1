import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/voice_service.dart';

class VoiceInputButton extends StatefulWidget {
  final Function(String) onVoiceResult;

  const VoiceInputButton({
    Key? key,
    required this.onVoiceResult,
  }) : super(key: key);

  @override
  State<VoiceInputButton> createState() => _VoiceInputButtonState();
}

class _VoiceInputButtonState extends State<VoiceInputButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<VoiceService>(
      builder: (context, voiceService, child) {
        return GestureDetector(
          onTap: voiceService.isAvailable ? _toggleListening : null,
          child: AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _isListening ? _scaleAnimation.value : 1.0,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _isListening
                        ? Theme.of(context).colorScheme.error
                        : voiceService.isAvailable
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.outline,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _isListening ? Icons.stop : Icons.mic,
                    color: voiceService.isAvailable
                        ? Colors.white
                        : Theme.of(context).colorScheme.surface,
                    size: 24,
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  Future<void> _toggleListening() async {
    final voiceService = context.read<VoiceService>();

    if (_isListening) {
      await voiceService.stopListening();
      _stopAnimation();
    } else {
      await voiceService.startListening(
        onResult: (text) {
          if (text.isNotEmpty) {
            widget.onVoiceResult(text);
            _stopListening();
          }
        },
      );
      _startAnimation();
    }

    setState(() {
      _isListening = !_isListening;
    });
  }

  void _startAnimation() {
    _animationController.repeat(reverse: true);
  }

  void _stopAnimation() {
    _animationController.stop();
    _animationController.reset();
  }

  Future<void> _stopListening() async {
    final voiceService = context.read<VoiceService>();
    await voiceService.stopListening();
    _stopAnimation();
    setState(() {
      _isListening = false;
    });
  }
}