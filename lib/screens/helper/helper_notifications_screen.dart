import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../components/feedback_banner.dart';
import '../../components/loading_indicator.dart';
import '../../components/notification_tile.dart';
import '../../models/notification_model.dart';
import '../../providers/app_state.dart';
import '../../services/notification_service.dart';
import '../../theme/app_theme.dart';

/// Screen for helpers to view persistent past notifications, cached locally with offline support,
/// real-time Firestore sync, swipe-to-dismiss, and a clear all option.
class HelperNotificationsScreen extends StatefulWidget {
  const HelperNotificationsScreen({super.key});

  @override
  State<HelperNotificationsScreen> createState() => _HelperNotificationsScreenState();
}

class _HelperNotificationsScreenState extends State<HelperNotificationsScreen> {
  List<NotificationModel> _cachedNotifications = [];

  @override
  void initState() {
    super.initState();
    _loadInitialCache();
  }

  /// Loads cached notifications from SharedPreferences before Firestore stream emits.
  Future<void> _loadInitialCache() async {
    final userId = context.read<CareDropAppState>().currentUserModel?.id ?? '';
    if (userId.isNotEmpty) {
      final cached = await NotificationService.getCachedNotifications(userId);
      if (mounted && cached.isNotEmpty) {
        setState(() {
          _cachedNotifications = cached;
        });
      }
    }
  }

  /// Displays confirmation dialog before clearing all notifications.
  void _confirmClearAll(BuildContext context, String userId) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Clear All Notifications?'),
        content: const Text('This will remove all notification records permanently.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              Navigator.pop(dialogCtx);
              await NotificationService.clearAllNotifications(userId);
              if (context.mounted) {
                FeedbackBanner.show(
                  context,
                  message: 'All notifications cleared',
                  type: FeedbackType.success,
                );
              }
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = context.watch<CareDropAppState>();
    final userId = appState.currentUserModel?.id ?? '';

    return Scaffold(
      backgroundColor: CareDropTheme.backgroundColor,
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: CareDropTheme.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (userId.isNotEmpty)
            TextButton(
              onPressed: () => _confirmClearAll(context, userId),
              child: const Text(
                'Clear All',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
      body: userId.isEmpty
          ? const Center(
              child: Text(
                'Please sign in to view notifications.',
                style: TextStyle(color: CareDropTheme.textMuted),
              ),
            )
          : StreamBuilder<List<NotificationModel>>(
              stream: NotificationService.streamNotifications(userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting && _cachedNotifications.isEmpty) {
                  return const Center(
                    child: AppLoadingIndicator(color: CareDropTheme.royalBlue, size: 24),
                  );
                }

                final notifications = snapshot.data ?? _cachedNotifications;

                if (notifications.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.notifications_none_outlined, size: 64, color: Colors.grey),
                        SizedBox(height: 12),
                        Text(
                          'No notifications at this time.',
                          style: TextStyle(color: CareDropTheme.textMuted, fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: notifications.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = notifications[index];
                    return NotificationTile(
                      notification: item,
                      onDismiss: () => NotificationService.deleteNotification(userId, item.id),
                    );
                  },
                );
              },
            ),
    );
  }
}
