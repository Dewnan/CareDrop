import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:caredrop/providers/app_state.dart';
import 'package:caredrop/screens/common/landing_screen.dart';

void main() {
  // Initial launch smoke test verifying LandingScreen renders title and button
  testWidgets('CareDrop app initial launch smoke test', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => CareDropAppState(),
        child: const MaterialApp(home: LandingScreen()),
      ),
    );

    // Verify that CareDrop landing title and Get Started button exist
    expect(find.text('CareDrop'), findsWidgets);
    expect(find.text('Get Started'), findsOneWidget);
  });
}
