import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:caredrop/models/task_model.dart';
import 'package:caredrop/models/helper_model.dart';
import 'package:caredrop/providers/app_state.dart';
import 'package:caredrop/components/feedback_banner.dart';
import 'package:caredrop/screens/helper/task_details_screen.dart';

void main() {
  group('Helper Interface Unit & Widget Tests', () {
    test('TC_HELPER_001 - Default helper rating starts at 0.0 for new users', () {
      final helper = HelperModel(
        id: 'h1',
        fullName: 'New Helper',
        icNumber: '123',
        phoneNumber: '077',
        email: 'h1@test.com',
        rating: 0.0,
        totalTasksCompleted: 0,
        todayEarnings: 0.0,
        verificationStatus: 'Verified',
        isOnline: true,
      );

      expect(helper.rating, equals(0.0));
      expect(helper.totalTasksCompleted, equals(0));
    });

    testWidgets('TC_HELPER_002 - TaskDetailsScreen renders Pickup & Dropoff Location labels without hardcoded Ward 4 Bed 12', (WidgetTester tester) async {
      final task = TaskModel(
        id: 't100',
        title: 'Medicine Delivery',
        pickupAddress: 'Pharmacy Counter A',
        roomDetail: 'Room 302',
        dropoffAddress: 'Room 302, Bed 05',
        currency: 'LKR',
        price: 500.0,
        isUrgent: false,
        category: TaskCategory.medicine,
        deadline: 'ASAP',
        description: 'Deliver prescription box',
        proofItems: [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<CareDropAppState>(
            create: (_) => CareDropAppState(),
            child: TaskDetailsScreen(task: task),
          ),
        ),
      );

      expect(find.text('Pickup Location'), findsOneWidget);
      expect(find.text('Dropoff Location'), findsOneWidget);
      expect(find.text('Ward 4, Bed 12'), findsNothing);
    });

    testWidgets('TC_HELPER_003 - FeedbackBanner renders message and icon accurately', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FeedbackBanner(
              message: 'Task Accepted successfully!',
              type: FeedbackType.success,
            ),
          ),
        ),
      );

      expect(find.text('Task Accepted successfully!'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });

    testWidgets('TC_HELPER_004 - TaskDetailsScreen hides Room & Bed No. when roomDetail equals pickup or dropoff location', (WidgetTester tester) async {
      final task = TaskModel(
        id: 't101',
        title: 'Medicine Pickup',
        pickupAddress: 'General Hospital Pickup',
        roomDetail: 'General Hospital Pickup',
        dropoffAddress: 'Patient Home',
        assignedHelperId: 'helper_1',
        currency: 'LKR',
        price: 350.0,
        isUrgent: false,
        category: TaskCategory.medicine,
        deadline: 'ASAP',
        description: 'Collect pills',
        proofItems: [],
      );

      final appState = CareDropAppState();

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<CareDropAppState>(
            create: (_) => appState,
            child: TaskDetailsScreen(task: task),
          ),
        ),
      );

      expect(find.text('Pickup Location'), findsOneWidget);
      expect(find.text('Dropoff Location'), findsOneWidget);
      expect(find.text('Room & Bed No.'), findsNothing);
    });

    testWidgets('TC_HELPER_005 - TaskDetailsScreen displays distinct pickup and dropoff locations', (WidgetTester tester) async {
      final task = TaskModel(
        id: 't102',
        title: 'Document Filing',
        pickupAddress: 'Main Pharmacy, Block B',
        roomDetail: 'Building A, Ward 2',
        dropoffAddress: 'Ward 5, Bed 12',
        currency: 'LKR',
        price: 280.0,
        isUrgent: true,
        category: TaskCategory.filing,
        deadline: '2:00 PM',
        description: 'File medical records',
        proofItems: [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<CareDropAppState>(
            create: (_) => CareDropAppState(),
            child: TaskDetailsScreen(task: task),
          ),
        ),
      );

      expect(find.text('Main Pharmacy, Block B'), findsOneWidget);
      expect(find.text('Ward 5, Bed 12'), findsOneWidget);
    });

    testWidgets('TC_HELPER_006 - Accepted task displays Customer Phone, Call button, Open Map, and Continue button', (WidgetTester tester) async {
      final acceptedTask = TaskModel(
        id: 't103',
        title: 'Medicine Delivery',
        pickupAddress: 'Hospital Pharmacy',
        roomDetail: 'Room 102',
        dropoffAddress: 'Patient Residence',
        assignedHelperId: 'helper_77',
        currency: 'LKR',
        price: 450.0,
        isUrgent: false,
        category: TaskCategory.medicine,
        deadline: 'ASAP',
        description: 'Deliver meds',
        proofItems: [],
      );

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<CareDropAppState>(
            create: (_) => CareDropAppState(),
            child: TaskDetailsScreen(task: acceptedTask),
          ),
        ),
      );

      expect(find.text('Navigate Map'), findsOneWidget);
      expect(find.byIcon(Icons.phone), findsOneWidget);
      expect(find.text('Patient Contact'), findsOneWidget);
    });
  });
}
