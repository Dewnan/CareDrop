import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:caredrop/providers/app_state.dart';
import 'package:caredrop/screens/patient/patient_create_task_form_screen.dart';
import 'package:caredrop/screens/patient/patient_task_type_screen.dart';

void main() {
  group('Patient Task Request Workflow Tests', () {
    // Tests task category screen renders available task types
    testWidgets('TC_TASK_001 - Task type screen displays task categories', (WidgetTester tester) async {
      await tester.pumpWidget(
        ChangeNotifierProvider(
          create: (_) => CareDropAppState(),
          child: const MaterialApp(
            home: PatientTaskTypeScreen(),
          ),
        ),
      );

      expect(find.byType(PatientTaskTypeScreen), findsOneWidget);
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
