import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/task_assignment_model.dart';

/// Service managing CRUD operations and real-time streaming for the separate 'task_assignments' Firestore collection.
class TaskAssignmentService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _collection = 'task_assignments';

  /// Records a new task assignment document in the 'task_assignments' collection upon helper acceptance.
  static Future<String> recordTaskAssignment({
    required String taskId,
    required String patientId,
    required String helperId,
    String? helperName,
  }) async {
    try {
      final docRef = _db.collection(_collection).doc();

      final assignment = TaskAssignmentModel(
        id: docRef.id,
        taskId: taskId,
        patientId: patientId,
        helperId: helperId,
        helperName: helperName ?? 'Helper',
        status: AssignmentStatus.active,
      );

      await docRef.set(assignment.toMap());
      return docRef.id;
    } catch (e) {
      debugPrint('Error recording task assignment: $e');
      return '';
    }
  }

  /// Updates assignment status (e.g. completed or cancelled) when task status changes.
  static Future<void> updateAssignmentStatus({
    required String taskId,
    required AssignmentStatus status,
  }) async {
    try {
      final query = await _db.collection(_collection).where('taskId', isEqualTo: taskId).get();
      for (final doc in query.docs) {
        await doc.reference.update({
          'status': status.name,
          if (status == AssignmentStatus.completed) 'completedAt': FieldValue.serverTimestamp(),
        });
      }

      final directRef = _db.collection(_collection).doc(taskId);
      final directSnap = await directRef.get();
      if (directSnap.exists) {
        await directRef.update({
          'status': status.name,
          if (status == AssignmentStatus.completed) 'completedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Error updating assignment status: $e');
    }
  }

  /// Streams active/past task assignments for a specific helper user.
  static Stream<List<TaskAssignmentModel>> streamHelperAssignments(String helperId) {
    if (helperId.isEmpty) return Stream.value([]);
    return _db
        .collection(_collection)
        .where('helperId', isEqualTo: helperId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => TaskAssignmentModel.fromMap(doc.data(), docId: doc.id))
          .toList();
    });
  }
}
