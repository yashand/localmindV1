import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../../models/chat_message.dart';

class MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const MessageBubble({Key? key, required this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!message.isUser) ...[
            // AI Avatar
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: PalantirTheme.backgroundSurface,
                border: Border.all(color: PalantirTheme.accentTeal, width: 1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(
                Icons.psychology_outlined,
                color: PalantirTheme.accentTeal,
                size: 16,
              ),
            ),
            SizedBox(width: 12),
          ],
          
          // Message Content
          Expanded(
            child: Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: message.isUser 
                    ? PalantirTheme.backgroundSurface 
                    : PalantirTheme.backgroundCard,
                border: Border.all(
                  color: message.isUser 
                      ? PalantirTheme.borderColor 
                      : PalantirTheme.accentTeal.withOpacity(0.3),
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(
                      color: PalantirTheme.textPrimary,
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    _formatTimestamp(message.timestamp),
                    style: TextStyle(
                      color: PalantirTheme.textMuted,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          if (message.isUser) ...[
            SizedBox(width: 12),
            // User Avatar
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: PalantirTheme.backgroundSurface,
                border: Border.all(color: PalantirTheme.borderColor, width: 1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Icon(
                Icons.person_outline,
                color: PalantirTheme.textSecondary,
                size: 16,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    if (difference.inSeconds < 60) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${timestamp.day}/${timestamp.month}';
    }
  }
}