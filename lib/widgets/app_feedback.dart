import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Utility widget/class for showing clean feedback notifications instead of raw debug SnackBars.
class AppFeedback {
  /// Shows a clean floating feedback banner/toast notification.
  static void showSuccess(BuildContext context, String message) {
    _showFeedback(
      context: context,
      message: message,
      icon: Icons.check_circle_outline,
      backgroundColor: CareDropTheme.royalBlue,
      textColor: Colors.white,
    );
  }

  /// Shows an error feedback notification.
  static void showError(BuildContext context, String message) {
    _showFeedback(
      context: context,
      message: message,
      icon: Icons.error_outline,
      backgroundColor: Colors.red.shade700,
      textColor: Colors.white,
    );
  }

  /// Shows an informational feedback notification.
  static void showInfo(BuildContext context, String message) {
    _showFeedback(
      context: context,
      message: message,
      icon: Icons.info_outline,
      backgroundColor: CareDropTheme.textPrimary,
      textColor: Colors.white,
    );
  }

  static void _showFeedback({
    required BuildContext context,
    required String message,
    required IconData icon,
    required Color backgroundColor,
    required Color textColor,
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        elevation: 4,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: backgroundColor,
        content: Row(
          children: [
            Icon(icon, color: textColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(
                  color: textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
