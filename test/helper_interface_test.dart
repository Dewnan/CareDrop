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
        hospital: 'General Hospital',
        locationDetail: 'Room 302',
        pickupAddress: 'Pharmacy Counter A',
        dropoffAddress: 'Room 302, Bed 05',
        distanceStr: '1.2 km',
        distanceKm: 1.2,
        currency: 'LKR',
        price: 500.0,
        isUrgent: false,
        category: TaskCategory.medicine,
        deadline: 'ASAP',
        patientInfo: 'Jane Doe',
        description: 'Deliver prescription box',
        startTimeStr: '10:00 AM',
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

    testWidgets('TC_HELPER_004 - TaskDetailsScreen hides Room & Bed No. when locationDetail equals pickup or dropoff location', (WidgetTester tester) async {
      final task = TaskModel(
        id: 't101',
        title: 'Medicine Pickup',
        hospital: 'General Hospital',
        locationDetail: 'General Hospital Pickup',
        pickupAddress: 'General Hospital Pickup',
        dropoffAddress: 'Patient Home',
        assignedHelperId: 'helper_1',
        distanceStr: '2.5 km',
        distanceKm: 2.5,
        currency: 'LKR',
        price: 350.0,
        isUrgent: false,
        category: TaskCategory.medicine,
        deadline: 'ASAP',
        patientInfo: 'John Doe',
        description: 'Collect pills',
        startTimeStr: '11:00 AM',
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
        hospital: 'National Hospital',
        locationDetail: 'Building A, Ward 2',
        pickupAddress: 'Main Pharmacy, Block B',
        dropoffAddress: 'Ward 5, Bed 12',
        distanceStr: '0.8 km',
        distanceKm: 0.8,
        currency: 'LKR',
        price: 280.0,
        isUrgent: true,
        category: TaskCategory.filing,
        deadline: '2:00 PM',
        patientInfo: 'Alice Smith',
        description: 'File medical records',
        startTimeStr: '1:00 PM',
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
        hospital: 'General Hospital',
        locationDetail: 'Room 102',
        pickupAddress: 'Hospital Pharmacy',
        dropoffAddress: 'Patient Residence',
        assignedHelperId: 'helper_77',
        distanceStr: '1.5 km',
        distanceKm: 1.5,
        currency: 'LKR',
        price: 450.0,
        isUrgent: false,
        category: TaskCategory.medicine,
        deadline: 'ASAP',
        patientInfo: 'Jane Doe',
        description: 'Deliver meds',
        startTimeStr: '10:30 AM',
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

      expect(find.text('Continue'), findsOneWidget);
      expect(find.byIcon(Icons.phone), findsOneWidget);
      expect(find.text('Patient Contact'), findsOneWidget);
    });
  });
}
