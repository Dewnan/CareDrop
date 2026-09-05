import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

/// Handles runtime permission requests for app services including location, camera, phone calls, and storage.
class PermissionService {
  /// Prompts user for all required runtime permissions at application startup.
  static Future<void> requestInitialPermissions() async {
    if (kIsWeb) return;
    try {
      await [
        Permission.location,
        Permission.camera,
        Permission.phone,
        Permission.storage,
      ].request();
    } catch (_) {}
  }

  /// Requests runtime location permission for GPS tracking and route navigation.
  static Future<bool> requestLocationPermission() async {
    if (kIsWeb) return true;
    try {
      final status = await Permission.location.request();
      return status.isGranted;
    } catch (_) {
      return false;
    }
  }

  /// Requests runtime camera permission for uploading proof of completion photos.
  static Future<bool> requestCameraPermission() async {
    if (kIsWeb) return true;
    try {
      final status = await Permission.camera.request();
      return status.isGranted;
    } catch (_) {
      return false;
    }
  }

  /// Requests runtime phone call permission before dialing numbers.
  static Future<bool> requestPhonePermission() async {
    if (kIsWeb) return true;
    try {
      final status = await Permission.phone.request();
      return status.isGranted;
    } catch (_) {
      return false;
    }
  }
}
