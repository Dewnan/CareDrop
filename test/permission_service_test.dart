import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:caredrop/services/permission_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('flutter.baseflow.com/permissions/methods'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'requestPermissions') {
          final List<dynamic> permissions = methodCall.arguments as List<dynamic>;
          final Map<int, int> result = {};
          for (final p in permissions) {
            if (p is int) {
              result[p] = 1; // 1 = granted
            }
          }
          return result;
        }
        return null;
      },
    );
  });

  group('PermissionService Unit Tests', () {
    test('TC_PERM_001 - requestLocationPermission returns boolean status', () async {
      final isGranted = await PermissionService.requestLocationPermission();
      expect(isGranted, isTrue);
    });

    test('TC_PERM_002 - requestCameraPermission returns boolean status', () async {
      final isGranted = await PermissionService.requestCameraPermission();
      expect(isGranted, isTrue);
    });

    test('TC_PERM_003 - requestPhonePermission returns boolean status', () async {
      final isGranted = await PermissionService.requestPhonePermission();
      expect(isGranted, isTrue);
    });
  });
}
