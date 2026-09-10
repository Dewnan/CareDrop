import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/task_model.dart';

class TaskService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _collectionPath = 'tasks';

  /// Create a new Task document in Firestore and trigger backend notification for nearby online helpers
  static Future<String> createTask(TaskModel task) async {
    final docRef = _db.collection(_collectionPath).doc();
    final taskData = {
      ...task.toMap(),
      'id': docRef.id,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    await docRef.set(taskData);

    // Trigger Supabase Edge Function for zero-cost backend nearby helper matching & push notifications
    _triggerNearbyHelpersEdgeFunction(taskData);

    return docRef.id;
  }

  /// Triggers the Supabase Edge Function to evaluate nearby online helpers within 3km radius and dispatch FCM alerts
  static Future<void> _triggerNearbyHelpersEdgeFunction(Map<String, dynamic> taskData) async {
    try {
      final String baseUrl = dotenv.env['SUPABASE_URL'] ?? '';
      final String anonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
      if (baseUrl.isEmpty) return;

      final String edgeFunctionUrl = '$baseUrl/functions/v1/notify_nearby_helpers';

      await http.post(
        Uri.parse(edgeFunctionUrl),
        headers: {
          'Content-Type': 'application/json',
          if (anonKey.isNotEmpty) 'Authorization': 'Bearer $anonKey',
          if (anonKey.isNotEmpty) 'apikey': anonKey,
        },
        body: jsonEncode({
          'taskId': taskData['id'],
          'title': taskData['title'],
          'hospital': taskData['hospital'],
          'price': taskData['price'],
          'latitude': taskData['latitude'] ?? taskData['pickupLat'],
          'longitude': taskData['longitude'] ?? taskData['pickupLng'],
          'maxRadiusKm': 3.0,
        }),
      );
    } catch (_) {
      // Background trigger failure handles gracefully without breaking task creation flow
    }
  }

  /// Stream all pending tasks for nearby Helpers
  static Stream<List<TaskModel>> streamPendingTasks({String? hospitalFilter}) {
    Query query = _db
        .collection(_collectionPath)
        .where('progressStep', isEqualTo: TaskProgressStep.pending.name);

    if (hospitalFilter != null && hospitalFilter.isNotEmpty) {
      query = query.where('hospital', isEqualTo: hospitalFilter);
    }

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => TaskModel.fromMap(doc.data() as Map<String, dynamic>, docId: doc.id))
          .toList();
    });
  }

  /// Stream tasks created by a specific patient
  static Stream<List<TaskModel>> streamPatientTasks(String patientId) {
    return _db
        .collection(_collectionPath)
        .where('patientId', isEqualTo: patientId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => TaskModel.fromMap(doc.data(), docId: doc.id))
          .toList();
    });
  }

  /// Stream tasks assigned to a specific helper
  static Stream<List<TaskModel>> streamHelperTasks(String helperId) {
    return _db
        .collection(_collectionPath)
        .where('assignedHelperId', isEqualTo: helperId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => TaskModel.fromMap(doc.data(), docId: doc.id))
          .toList();
    });
  }

  /// Atomic transaction for a Helper to accept a task (prevents duplicate accepts)
  static Future<bool> acceptTask({
    required String taskId,
    required String helperId,
    String? helperName,
  }) async {
    final taskRef = _db.collection(_collectionPath).doc(taskId);

    String? patientId;
    String? title;
    String? category;

    final success = await _db.runTransaction<bool>((transaction) async {
      final snapshot = await transaction.get(taskRef);
      if (!snapshot.exists) return false;

      final data = snapshot.data()!;
      final currentStep = data['progressStep'] as String?;
      patientId = data['patientId'] as String?;
      title = data['title'] as String?;
      category = data['category'] as String? ?? 'all';

      // Check if task is still pending and unassigned
      if (currentStep == TaskProgressStep.pending.name && data['assignedHelperId'] == null) {
        transaction.update(taskRef, {
          'assignedHelperId': helperId,
          'progressStep': TaskProgressStep.taskAccepted.name,
          'acceptedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return true;
      }
      return false; // Already taken by another helper
    });

    if (success && patientId != null && patientId!.isNotEmpty) {
      _triggerPatientStatusEdgeFunction(
        taskId: taskId,
        patientId: patientId!,
        step: TaskProgressStep.taskAccepted.name,
        title: title ?? 'Task',
        category: category ?? 'all',
        helperName: helperName,
      );
    }

    return success;
  }

  /// Validates and executes state transitions for a task using an atomic transaction.
  static Future<bool> updateTaskProgress({
    required String taskId,
    required TaskProgressStep step,
    String? helperName,
  }) async {
    final taskRef = _db.collection(_collectionPath).doc(taskId);

    String? patientId;
    String? title;
    String? category;

    final success = await _db.runTransaction<bool>((transaction) async {
      final snapshot = await transaction.get(taskRef);
      if (!snapshot.exists) return false;

      final data = snapshot.data()!;
      final currentStepStr = data['progressStep'] as String? ?? TaskProgressStep.pending.name;
      patientId = data['patientId'] as String?;
      title = data['title'] as String?;
      category = data['category'] as String? ?? 'all';

      final currentStep = TaskProgressStep.values.firstWhere(
        (e) => e.name == currentStepStr,
        orElse: () => TaskProgressStep.pending,
      );

      if (currentStep.canTransitionTo(step)) {
        transaction.update(taskRef, {
          'progressStep': step.name,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        return true;
      }
      return false;
    });

    if (success && patientId != null && patientId!.isNotEmpty) {
      _triggerPatientStatusEdgeFunction(
        taskId: taskId,
        patientId: patientId!,
        step: step.name,
        title: title ?? 'Task',
        category: category ?? 'all',
        helperName: helperName,
      );
    }

    return success;
  }

  /// Safely cancel a task posted by a patient while searching or in-progress
  static Future<void> cancelTask({
    required String taskId,
    String? reason,
  }) async {
    final doc = await _db.collection(_collectionPath).doc(taskId).get();
    final data = doc.data();

    await _db.collection(_collectionPath).doc(taskId).update({
      'progressStep': TaskProgressStep.cancelled.name,
      'cancelReason': reason ?? 'Cancelled by user',
      'cancelledAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });

    if (data != null) {
      final patientId = data['patientId'] as String?;
      if (patientId != null && patientId.isNotEmpty) {
        _triggerPatientStatusEdgeFunction(
          taskId: taskId,
          patientId: patientId,
          step: TaskProgressStep.cancelled.name,
          title: data['title'] as String? ?? 'Task',
          category: data['category'] as String? ?? 'all',
        );
      }
    }
  }

  /// Triggers the Supabase Edge Function to notify the patient of task progress state transitions
  static Future<void> _triggerPatientStatusEdgeFunction({
    required String taskId,
    required String patientId,
    required String step,
    required String title,
    required String category,
    String? helperName,
  }) async {
    try {
      final String baseUrl = dotenv.env['SUPABASE_URL'] ?? '';
      final String anonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
      if (baseUrl.isEmpty) return;

      final String edgeFunctionUrl = '$baseUrl/functions/v1/taskProgressNotificationsForPatient';

      await http.post(
        Uri.parse(edgeFunctionUrl),
        headers: {
          'Content-Type': 'application/json',
          if (anonKey.isNotEmpty) 'Authorization': 'Bearer $anonKey',
          if (anonKey.isNotEmpty) 'apikey': anonKey,
        },
        body: jsonEncode({
          'taskId': taskId,
          'patientId': patientId,
          'step': step,
          'title': title,
          'category': category,
          'helperName': helperName ?? 'Helper',
        }),
      );
    } catch (_) {
      // Handles background notification triggers silently
    }
  }
}
