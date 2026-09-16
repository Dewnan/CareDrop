import 'package:flutter_test/flutter_test.dart';
import 'package:caredrop/models/task_model.dart';
import 'package:caredrop/services/geoapify_service.dart';

void main() {
  group('TaskModel Serialization Tests', () {
    test('toMap and fromMap should correctly preserve pickup and dropoff fields', () {
      final task = TaskModel(
        id: 'test_task_1',
        title: 'Medicine Delivery',
        pickupAddress: 'Hospital Pharmacy, Ward 4B',
        pickupLat: 6.9271,
        pickupLng: 79.8612,
        dropoffAddress: '123 Main Street, Colombo 03',
        dropoffLat: 6.9147,
        dropoffLng: 79.8510,
        roomDetail: 'Ward 4B',
        currency: 'LKR',
        price: 500.0,
        isUrgent: true,
        category: TaskCategory.medicine,
        deadline: 'Today, 5:00 PM',
        description: 'Pick up prescriptions',
        proofItems: [],
      );

      final map = task.toMap();

      expect(map['pickupAddress'], equals('Hospital Pharmacy, Ward 4B'));
      expect(map['pickupLat'], equals(6.9271));
      expect(map['pickupLng'], equals(79.8612));
      expect(map['dropoffAddress'], equals('123 Main Street, Colombo 03'));
      expect(map['dropoffLat'], equals(6.9147));
      expect(map['dropoffLng'], equals(79.8510));
      expect(map['roomDetail'], equals('Ward 4B'));

      final restoredTask = TaskModel.fromMap(map, docId: 'test_task_1');

      expect(restoredTask.pickupAddress, equals(task.pickupAddress));
      expect(restoredTask.pickupLat, equals(task.pickupLat));
      expect(restoredTask.pickupLng, equals(task.pickupLng));
      expect(restoredTask.dropoffAddress, equals(task.dropoffAddress));
      expect(restoredTask.dropoffLat, equals(task.dropoffLat));
      expect(restoredTask.dropoffLng, equals(task.dropoffLng));
      expect(restoredTask.roomDetail, equals(task.roomDetail));
    });
  });

  group('GeoapifySearchResult Serialization Tests', () {
    test('GeoapifySearchResult.fromJson parses valid response correctly', () {
      final json = {
        'properties': {
          'formatted': 'Colombo, Sri Lanka',
          'name': 'Colombo',
          'lat': 6.9388614,
          'lon': 79.8542005,
        }
      };

      final result = GeoapifySearchResult.fromJson(json);

      expect(result.formattedAddress, equals('Colombo, Sri Lanka'));
      expect(result.title, equals('Colombo'));
      expect(result.latitude, equals(6.9388614));
      expect(result.longitude, equals(79.8542005));
    });
  });
}
