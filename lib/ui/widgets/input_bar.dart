import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class InputBar extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onVoicePress;
  final bool isLoading;

  const InputBar({
    Key? key,
    required this.controller,
    required this.onSend,
    required this.onVoicePress,
    this.isLoading = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            style: TextStyle(
              color: PalantirTheme.textPrimary,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              hintText: 'Type your message...',
              hintStyle: TextStyle(
                color: PalantirTheme.textMuted,
                fontSize: 14,
              ),
              filled: true,
              fillColor: PalantirTheme.backgroundSurface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: PalantirTheme.borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: PalantirTheme.borderColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: PalantirTheme.accentTeal, width: 2),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            maxLines: null,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => onSend(),
          ),
        ),
        SizedBox(width: 12),
        
        // Voice Input Button
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: PalantirTheme.backgroundSurface,
            border: Border.all(color: PalantirTheme.borderColor),
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            onPressed: onVoicePress,
            icon: Icon(
              Icons.mic_outlined,
              color: PalantirTheme.textSecondary,
              size: 20,
            ),
          ),
        ),
        
        SizedBox(width: 12),
        
        // Send Button
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: isLoading ? PalantirTheme.backgroundSurface : PalantirTheme.accentTeal,
            border: Border.all(
              color: isLoading ? PalantirTheme.borderColor : PalantirTheme.accentTeal,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: IconButton(
            onPressed: isLoading ? null : onSend,
            icon: isLoading
                ? SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: PalantirTheme.textMuted,
                    ),
                  )
                : Icon(
                    Icons.send_outlined,
                    color: isLoading ? PalantirTheme.textMuted : PalantirTheme.backgroundDeep,
                    size: 20,
                  ),
          ),
        ),
      ],
    );
  }
}