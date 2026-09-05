import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:provider/provider.dart';
import 'package:caredrop/providers/app_state.dart';
import 'package:caredrop/screens/patient/patient_create_task_form_screen.dart';

void main() {
  setUpAll(() async {
    dotenv.loadFromString(envString: 'GEOAPIFY_API_KEY=test_key');
  });

  group('Patient Task Creation Form Tests', () {
    // TC_TASK_003 - Verifies pickup location search input and map pin icon exist
    testWidgets('TC_TASK_003 - Task creation screen renders pickup address input and map picker button', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => CareDropAppState(),
          child: const MaterialApp(
            home: PatientCreateTaskFormScreen(initialTaskType: 'Medicine Pickup'),
          ),
        ),
      );

      expect(find.textContaining('Hospital / Location Name'), findsOneWidget);
      expect(find.byIcon(Icons.map), findsWidgets);
    });

    // TC_TASK_004 - Verifies dropoff location search input when dropoff is required
    testWidgets('TC_TASK_004 - Task creation screen renders dropoff location field for delivery tasks', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => CareDropAppState(),
          child: const MaterialApp(
            home: PatientCreateTaskFormScreen(initialTaskType: 'Medicine Pickup'),
          ),
        ),
      );

      await tester.pumpAndSettle();
      final dropoffFinder = find.textContaining('3. DROP-OFF LOCATION');
      await tester.scrollUntilVisible(
        dropoffFinder,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(dropoffFinder, findsOneWidget);
    });
  });
}
