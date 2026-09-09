import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'permission_service.dart';
import 'user_profile_service.dart';
import 'fcm_notification_service.dart';

/// Manages real-time background location updates for active helpers when they move > 100 meters while Online.
class LocationTrackerService {
  static StreamSubscription<Position>? _positionSubscription;

  /// Starts tracking helper GPS updates when online and syncs coordinates whenever moved by at least 100 meters
  static Future<void> startTracking({required String uid}) async {
    if (uid.isEmpty) return;

    // Register FCM device push token asynchronously
    FcmNotificationService.registerFcmToken(uid: uid);

    final hasPermission = await PermissionService.requestLocationPermission();
    if (!hasPermission) return;

    // Fetch and sync initial location immediately
    try {
      final initialPosition = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      await UserProfileService.updateOnlineStatus(
        uid: uid,
        isOnline: true,
        latitude: initialPosition.latitude,
        longitude: initialPosition.longitude,
      );
    } catch (_) {}

    // Cancel any pre-existing subscription to prevent duplicate listeners
    await _positionSubscription?.cancel();

    // Listen to GPS movements beyond 100 meters
    const locationSettings = LocationSettings(
      accuracy: LocationAccuracy.high,
      distanceFilter: 100, // Triggers only when moving 100m+
    );

    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: locationSettings,
    ).listen((position) {
      UserProfileService.updateOnlineStatus(
        uid: uid,
        isOnline: true,
        latitude: position.latitude,
        longitude: position.longitude,
      );
    }, onError: (err) {
      if (kDebugMode) {
        print('[LocationTrackerService] Position stream error: $err');
      }
    });
  }

  /// Stops the GPS location tracking stream and sets helper status to offline in backend
  static Future<void> stopTracking({required String uid}) async {
    await _positionSubscription?.cancel();
    _positionSubscription = null;

    if (uid.isNotEmpty) {
      await UserProfileService.updateOnlineStatus(
        uid: uid,
        isOnline: false,
      );
    }
  }
}
