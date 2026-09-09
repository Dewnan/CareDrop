import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'user_profile_service.dart';

/// Manages FCM push notification permissions and device token registration for active helpers.
class FcmNotificationService {
  static final FirebaseMessaging _messaging = FirebaseMessaging.instance;

  /// Requests push notification permissions and syncs device FCM token to user profile
  static Future<void> registerFcmToken({required String uid}) async {
    if (uid.isEmpty) return;

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
        await UserProfileService.updateOnlineStatus(
          uid: uid,
          isOnline: true,
          fcmToken: token,
        );
      }
    } catch (err) {
      if (kDebugMode) {
        print('[FcmNotificationService] Error registering FCM token: $err');
      }
    }
  }

  /// Sets up foreground notification listeners to receive and handle real-time push alerts from Firebase
  static void initializeForegroundListeners({Function(RemoteMessage)? onMessageReceived}) {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('[FcmNotificationService] Incoming Push Alert: ${message.notification?.title} - ${message.notification?.body}');
      }
      if (onMessageReceived != null) {
        onMessageReceived(message);
      }
    });
  }
}
