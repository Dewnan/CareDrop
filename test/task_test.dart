import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:caredrop/providers/app_state.dart';
import 'package:caredrop/screens/patient/patient_create_task_form_screen.dart';

void main() {
  group('Patient Task Request Workflow Tests', () {
    // Tests task creation form renders with category parameter
    testWidgets('TC_TASK_001 - Task creation screen renders for task category', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => CareDropAppState(),
          child: const MaterialApp(
            home: PatientCreateTaskFormScreen(initialTaskType: 'Elderly Care'),
          ),
        ),
      );

      expect(find.byType(PatientCreateTaskFormScreen), findsOneWidget);
    });

    // Tests task creation form renders input fields for title, location, fee
    testWidgets('TC_TASK_002 - Task creation form renders required form fields', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => CareDropAppState(),
          child: const MaterialApp(
            home: PatientCreateTaskFormScreen(initialTaskType: 'Medicine Pickup'),
          ),
        ),
      );

      expect(find.byType(PatientCreateTaskFormScreen), findsOneWidget);
      expect(find.byType(TextFormField), findsWidgets);
    });
  });
}
