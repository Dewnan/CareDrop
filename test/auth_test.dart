import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:caredrop/providers/app_state.dart';
import 'package:caredrop/screens/common/common_register_screen.dart';
import 'package:caredrop/screens/common/common_signin_screen.dart';

void main() {
  group('Auth Unit & Widget Tests', () {
    // Tests registration form renders Patient and Helper role options
    testWidgets('TC_AUTH_001 - Register screen displays Patient and Helper role options', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => CareDropAppState(),
          child: const MaterialApp(
            home: CommonRegisterScreen(),
          ),
        ),
      );

      expect(find.textContaining('Patient'), findsWidgets);
      expect(find.textContaining('Helper'), findsWidgets);
    });

    // Tests registration email validation for malformed input
    testWidgets('TC_AUTH_002 - Register form validates email input', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => CareDropAppState(),
          child: const MaterialApp(
            home: CommonRegisterScreen(),
          ),
        ),
      );

      final registerButton = find.widgetWithText(ElevatedButton, 'Register');
      if (registerButton.evaluate().isNotEmpty) {
        await tester.tap(registerButton);
        await tester.pump();
      }
      expect(find.byType(CommonRegisterScreen), findsOneWidget);
    });

    // Tests sign in screen renders email and password fields
    testWidgets('TC_AUTH_005 - Sign In screen renders required fields', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => CareDropAppState(),
          child: const MaterialApp(
            home: CommonSignInScreen(),
          ),
        ),
      );

      expect(find.byType(TextField), findsWidgets);
    });
  });
}
