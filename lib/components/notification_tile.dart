import 'package:flutter/material.dart';
import '../models/notification_model.dart';
import '../theme/app_theme.dart';

/// Reusable modular notification tile component with swipe-to-dismiss support,
/// unread indicator dot, relative time formatting, and dynamic type icons.
class NotificationTile extends StatelessWidget {
  final NotificationModel notification;
  final VoidCallback? onTap;
  final VoidCallback? onDismiss;

  const NotificationTile({
    super.key,
    required this.notification,
    this.onTap,
    this.onDismiss,
  });

  /// Formats DateTime into clean human-readable relative time string.
  String _formatRelativeTime(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${dateTime.year}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
  }

  /// Selects icon and theme colors based on notification type.
  (IconData, Color, Color) _getTypeStyling(NotificationType type) {
    switch (type) {
      case NotificationType.taskUpdate:
        return (Icons.sync_rounded, CareDropTheme.royalBlue, const Color(0xFFEFF6FF));
      case NotificationType.helperMatch:
        return (Icons.person_pin_circle_outlined, CareDropTheme.tealPrimary, CareDropTheme.tealLight);
      case NotificationType.payment:
        return (Icons.account_balance_wallet_outlined, const Color(0xFF16A34A), CareDropTheme.paidBg);
      case NotificationType.system:
        return (Icons.notifications_none_rounded, CareDropTheme.textSecondary, CareDropTheme.normalBg);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (iconData, iconColor, iconBg) = _getTypeStyling(notification.type);

    final content = InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: notification.isRead ? Colors.white : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: notification.isRead ? CareDropTheme.cardBorderColor : CareDropTheme.royalBlue.withValues(alpha: 0.3),
            width: notification.isRead ? 1 : 1.5,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(iconData, color: iconColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notification.title,
                          style: TextStyle(
                            fontWeight: notification.isRead ? FontWeight.w600 : FontWeight.bold,
                            fontSize: 14,
                            color: CareDropTheme.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        _formatRelativeTime(notification.timestamp),
                        style: const TextStyle(
                          fontSize: 11,
                          color: CareDropTheme.textMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notification.message,
                    style: const TextStyle(
                      fontSize: 12,
                      color: CareDropTheme.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            if (!notification.isRead) ...[
              const SizedBox(width: 8),
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 4),
                decoration: const BoxDecoration(
                  color: CareDropTheme.royalBlue,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ],
        ),
      ),
    );

    if (onDismiss != null) {
      return Dismissible(
        key: Key(notification.id),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => onDismiss!(),
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          decoration: BoxDecoration(
            color: Colors.red.shade400,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.delete_outline, color: Colors.white, size: 24),
        ),
        child: content,
      );
    }

    return content;
  }
}
