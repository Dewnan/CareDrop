import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

enum FeedbackType { success, info, warning, error }

/// Reusable banner/toast feedback component for task & helper actions.
class FeedbackBanner extends StatelessWidget {
  final String message;
  final FeedbackType type;
  final VoidCallback? onDismiss;

  const FeedbackBanner({
    super.key,
    required this.message,
    this.type = FeedbackType.info,
    this.onDismiss,
  });

  /// Displays the feedback banner inside an Overlay or bottom banner.
  static void show(
    BuildContext context, {
    required String message,
    FeedbackType type = FeedbackType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 12,
        left: 16,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: FeedbackBanner(
            message: message,
            type: type,
            onDismiss: () => entry.remove(),
          ),
        ),
      ),
    );

    overlay.insert(entry);
    Future.delayed(duration, () {
      if (entry.mounted) {
        entry.remove();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color iconColor;
    IconData iconData;

    switch (type) {
      case FeedbackType.success:
        bgColor = const Color(0xFFDCFCE7);
        iconColor = const Color(0xFF15803D);
        iconData = Icons.check_circle_rounded;
        break;
      case FeedbackType.warning:
        bgColor = const Color(0xFFFEF3C7);
        iconColor = const Color(0xFFB45309);
        iconData = Icons.warning_rounded;
        break;
      case FeedbackType.error:
        bgColor = const Color(0xFFFEE2E2);
        iconColor = const Color(0xFFB91C1C);
        iconData = Icons.error_rounded;
        break;
      case FeedbackType.info:
      default:
        bgColor = const Color(0xFFEFF6FF);
        iconColor = CareDropTheme.royalBlue;
        iconData = Icons.info_rounded;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: iconColor.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(iconData, color: iconColor, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: CareDropTheme.textPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (onDismiss != null)
            GestureDetector(
              onTap: onDismiss,
              child: Icon(Icons.close, size: 18, color: CareDropTheme.textMuted),
            ),
        ],
      ),
    );
  }
}
