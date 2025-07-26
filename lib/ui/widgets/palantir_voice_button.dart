import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/voice_service.dart';
import '../theme/app_theme.dart';

class PalantirVoiceButton extends StatefulWidget {
  final Function(String) onVoiceResult;

  const PalantirVoiceButton({
    Key? key,
    required this.onVoiceResult,
  }) : super(key: key);

  @override
  State<PalantirVoiceButton> createState() => _PalantirVoiceButtonState();
}

class _PalantirVoiceButtonState extends State<PalantirVoiceButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.8,
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
            animation: _pulseAnimation,
            builder: (context, child) {
              return Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _isListening
                      ? PalantirTheme.accentOrange
                      : voiceService.isAvailable
                          ? PalantirTheme.backgroundSurface
                          : PalantirTheme.backgroundSurface.withOpacity(0.5),
                  border: Border.all(
                    color: _isListening
                        ? PalantirTheme.accentOrange
                        : voiceService.isAvailable
                            ? PalantirTheme.borderColor
                            : PalantirTheme.borderColor.withOpacity(0.5),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Transform.scale(
                  scale: _isListening ? _pulseAnimation.value : 1.0,
                  child: Icon(
                    _isListening ? Icons.stop_outlined : Icons.mic_outlined,
                    color: _isListening
                        ? PalantirTheme.backgroundDeep
                        : voiceService.isAvailable
                            ? PalantirTheme.textSecondary
                            : PalantirTheme.textMuted,
                    size: 20,
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