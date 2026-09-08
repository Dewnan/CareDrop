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

    // TC_TASK_005 - Verifies location validation error when submitting form without pinned map location
    testWidgets('TC_TASK_005 - Prevents submission and shows snackbar when pickup location coordinates are unpinned', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => CareDropAppState(),
          child: const MaterialApp(
            home: PatientCreateTaskFormScreen(initialTaskType: 'Medicine Pickup'),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, 'Need paracetamol pickup from ward 2');
      await tester.pumpAndSettle();

      final submitButton = find.text('Review & Post Task');
      await tester.scrollUntilVisible(
        submitButton,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(submitButton);
      await tester.pumpAndSettle();

      expect(find.textContaining('Please select or pin'), findsOneWidget);
    });

    // TC_TASK_006 - Verifies Other task type allows empty pickup/dropoff locations
    testWidgets('TC_TASK_006 - Other task type allows submission without requiring location coordinates', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => CareDropAppState(),
          child: const MaterialApp(
            home: PatientCreateTaskFormScreen(initialTaskType: 'Other'),
          ),
        ),
      );

      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextFormField).first, 'General assistance needed');
      await tester.pumpAndSettle();

      final submitButton = find.text('Review & Post Task');
      await tester.scrollUntilVisible(
        submitButton,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(submitButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Review & Confirm Task'), findsOneWidget);
    });

    // TC_TASK_007 - Verifies Patient Caregiver / Bedside Assistance task type renders duration, gender, and language preferences
    testWidgets('TC_TASK_007 - Bedside assistance task renders duration, gender, and language preference fields', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => CareDropAppState(),
          child: const MaterialApp(
            home: PatientCreateTaskFormScreen(initialTaskType: 'Patient Caregiver / Bedside Assistance'),
          ),
        ),
      );

      await tester.pumpAndSettle();
      final sectionFinder = find.text('Service Duration (How long needed)');
      await tester.scrollUntilVisible(
        sectionFinder,
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(sectionFinder, findsOneWidget);
      expect(find.text('Preferred Helper Gender'), findsOneWidget);
      expect(find.text('Language Requirement'), findsOneWidget);
    });
  });
}
