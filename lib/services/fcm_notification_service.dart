import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import '../models/notification_model.dart';
import 'notification_service.dart';
import 'user_profile_service.dart';

/// Top-level background message handler invoked by FCM when app is minimized/terminated.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  final title = message.notification?.title ?? message.data['title'] ?? 'CareDrop Alert';
  final body = message.notification?.body ?? message.data['body'] ?? 'New notification received';
  final taskId = message.data['taskId'] as String?;
  final typeStr = message.data['type'] as String?;

  final type = typeStr == 'helperMatch'
      ? NotificationType.helperMatch
      : typeStr == 'payment'
          ? NotificationType.payment
          : NotificationType.taskUpdate;

  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid != null && uid.isNotEmpty) {
    await NotificationService.saveNotificationLocally(
      userId: uid,
      title: title,
      message: body,
      type: type,
      relatedTaskId: taskId,
    );
  }
}

/// Manages FCM push notification permissions, device token registration, and capturing incoming push alerts for local storage.
class FcmNotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  static String? _registeredUserId;

  /// Requests push notification permissions and syncs device FCM token to user profile
  static Future<void> registerFcmToken({required String uid}) async {
    if (uid.isEmpty) return;
    _registeredUserId = uid;

    try {
      // Request push notification permissions for iOS / Android 13+
      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      final token = await _messaging.getToken();

      if (token != null && token.isNotEmpty) {
        if (kDebugMode) {
          print('[FcmNotificationService] Obtained FCM Token: ${token.substring(0, 12)}...');
        }
        await UserProfileService.updateFcmToken(
          uid: uid,
          fcmToken: token,
        );
      }
    } catch (err) {
      if (kDebugMode) {
        print('[FcmNotificationService] Error registering FCM token: $err');
      }
    }
  }

  /// Sets up foreground notification listeners to receive, save, and handle real-time push alerts from Firebase
  static void initializeForegroundListeners({Function(RemoteMessage)? onMessageReceived}) {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      final title = message.notification?.title ?? message.data['title'] ?? 'CareDrop Alert';
      final body = message.notification?.body ?? message.data['body'] ?? 'New notification received';
      final taskId = message.data['taskId'] as String?;
      final typeStr = message.data['type'] as String?;

      final type = typeStr == 'helperMatch'
          ? NotificationType.helperMatch
          : typeStr == 'payment'
              ? NotificationType.payment
              : NotificationType.taskUpdate;

      if (kDebugMode) {
        print('[FcmNotificationService] Incoming Push Alert: $title - $body');
      }

      final activeUid = FirebaseAuth.instance.currentUser?.uid ?? _registeredUserId;
      if (activeUid != null && activeUid.isNotEmpty) {
        await NotificationService.saveNotificationLocally(
          userId: activeUid,
          title: title,
          message: body,
          type: type,
          relatedTaskId: taskId,
        );
      }

      if (onMessageReceived != null) {
        onMessageReceived(message);
      }
    });
  }
}
