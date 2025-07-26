import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ModeIndicator extends StatelessWidget {
  final String mode;
  final VoidCallback? onTap;

  const ModeIndicator({
    Key? key,
    required this.mode,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isWork = mode == 'work';
    final color = isWork ? PalantirTheme.accentBlue : PalantirTheme.accentOrange;
    final icon = isWork ? Icons.work_outline : Icons.person_outline;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: color,
            ),
            SizedBox(width: 6),
            Text(
              mode.toUpperCase(),
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}