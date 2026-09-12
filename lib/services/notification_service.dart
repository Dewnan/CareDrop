import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notification_model.dart';

/// Manages pure local notification storage, SharedPreferences persistence,
/// reactive local streams, and FCM push notification capturing without Firestore database reads/writes.
class NotificationService {
  static final StreamController<List<NotificationModel>> _localStreamController =
      StreamController<List<NotificationModel>>.broadcast();

  /// Returns cache storage key for a specific user.
  static String _cacheKey(String userId) => 'caredrop_notifications_$userId';

  /// Saves list of notifications to local SharedPreferences storage.
  static Future<void> _saveToCache(String userId, List<NotificationModel> notifications) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = notifications.map((n) => n.toJson()).toList();
      await prefs.setStringList(_cacheKey(userId), jsonList);
      _localStreamController.add(notifications);
    } catch (e) {
      debugPrint('Failed to save notifications cache: $e');
    }
  }

  /// Loads cached notifications from local SharedPreferences storage.
  static Future<List<NotificationModel>> getCachedNotifications(String userId) async {
    if (userId.isEmpty) return [];
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = prefs.getStringList(_cacheKey(userId)) ?? [];
      final list = jsonList.map((str) => NotificationModel.fromJson(str)).toList();
      list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return list;
    } catch (e) {
      debugPrint('Failed to load notifications cache: $e');
      return [];
    }
  }

  /// Streams real-time local notifications for a user backed by SharedPreferences cache.
  static Stream<List<NotificationModel>> streamNotifications(String userId) {
    if (userId.isEmpty) return Stream.value([]);

    // Immediately load and emit cached notifications, then listen for updates
    final controller = StreamController<List<NotificationModel>>();
    getCachedNotifications(userId).then((list) {
      if (!controller.isClosed) controller.add(list);
    });

    final subscription = _localStreamController.stream.listen((list) {
      if (!controller.isClosed) controller.add(list);
    });

    controller.onCancel = () {
      subscription.cancel();
    };

    return controller.stream;
  }

  /// Saves a new notification directly to local SharedPreferences and broadcasts to active UI listeners.
  static Future<void> saveNotificationLocally({
    required String userId,
    required String title,
    required String message,
    NotificationType type = NotificationType.system,
    String? relatedTaskId,
  }) async {
    if (userId.isEmpty) return;

    final existing = await getCachedNotifications(userId);
    final newId = DateTime.now().millisecondsSinceEpoch.toString();

    final notification = NotificationModel(
      id: newId,
      userId: userId,
      title: title,
      message: message,
      type: type,
      relatedTaskId: relatedTaskId,
      timestamp: DateTime.now(),
    );

    existing.insert(0, notification);
    await _saveToCache(userId, existing);
  }

  /// Legacy alias for sendNotification pointing to saveNotificationLocally.
  static Future<void> sendNotification({
    required String userId,
    required String title,
    required String message,
    NotificationType type = NotificationType.system,
    String? relatedTaskId,
  }) async {
    await saveNotificationLocally(
      userId: userId,
      title: title,
      message: message,
      type: type,
      relatedTaskId: relatedTaskId,
    );
  }

  /// Deletes a single notification from local SharedPreferences and updates stream.
  static Future<void> deleteNotification(String userId, String notificationId) async {
    if (userId.isEmpty || notificationId.isEmpty) return;

    try {
      final cached = await getCachedNotifications(userId);
      cached.removeWhere((n) => n.id == notificationId);
      await _saveToCache(userId, cached);
    } catch (e) {
      debugPrint('Error deleting notification: $e');
    }
  }

  /// Clears all notifications for a user in local SharedPreferences and updates stream.
  static Future<void> clearAllNotifications(String userId) async {
    if (userId.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_cacheKey(userId));
      _localStreamController.add([]);
    } catch (e) {
      debugPrint('Error clearing all notifications: $e');
    }
  }
}
