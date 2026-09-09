import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Renders a light-gray offline state placeholder message for helper task screens.
class OfflineTaskPlaceholder extends StatelessWidget {
  final bool showBorder;

  const OfflineTaskPlaceholder({
    super.key,
    this.showBorder = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: showBorder ? Border.all(color: CareDropTheme.cardBorderColor) : null,
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 10),
          Text(
            'You are currently Offline',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: CareDropTheme.textPrimary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Turn Online on your availability status to receive nearby task requests.',
            style: TextStyle(
              fontSize: 12,
              color: CareDropTheme.textMuted,
              height: 1.3,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
