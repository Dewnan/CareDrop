import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/notification_model.dart';
import '../models/payment_model.dart';
import '../models/task_assignment_model.dart';
import '../models/task_model.dart';
import 'notification_service.dart';
import 'payment_service.dart';
import 'task_assignment_service.dart';
import 'user_profile_service.dart';

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

    // Create entry in separate 'payments' collection
    await PaymentService.createPaymentRecord(
      taskId: docRef.id,
      patientId: task.patientId,
      amount: task.price,
      paymentMethod: task.paymentMethod ?? 'Cash',
    );

    // Persist notification for patient user directly
    if (task.patientId.isNotEmpty) {
      await NotificationService.sendNotification(
        userId: task.patientId,
        title: 'Task Created: ${task.title}',
        message: 'Your care task has been created and broadcast to nearby helpers.',
        type: NotificationType.taskUpdate,
        relatedTaskId: docRef.id,
      );
    }

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
    String? paymentMethod;
    double price = 0.0;

    final success = await _db.runTransaction<bool>((transaction) async {
      final snapshot = await transaction.get(taskRef);
      if (!snapshot.exists) return false;

      final data = snapshot.data()!;
      final currentStep = data['progressStep'] as String?;
      patientId = data['patientId'] as String?;
      title = data['title'] as String?;
      category = data['category'] as String? ?? 'all';
      paymentMethod = data['paymentMethod'] as String? ?? 'Cash';
      price = (data['price'] as num?)?.toDouble() ?? 0.0;

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
      // Record assignment in separate 'task_assignments' collection
      await TaskAssignmentService.recordTaskAssignment(
        taskId: taskId,
        patientId: patientId!,
        helperId: helperId,
        helperName: helperName,
      );

      // Assign helper payee in 'payments' collection
      await PaymentService.assignHelperToPayment(
        taskId: taskId,
        helperId: helperId,
      );

      // Save notification to patient
      await NotificationService.sendNotification(
        userId: patientId!,
        title: 'Helper Matched!',
        message: '${helperName ?? "A verified helper"} accepted your task "${title ?? "Care Task"}".',
        type: NotificationType.helperMatch,
        relatedTaskId: taskId,
      );

      // Save task update notification to helper
      await NotificationService.sendNotification(
        userId: helperId,
        title: 'Task Accepted',
        message: 'You accepted "${title ?? "Care Task"}". Tap to view details.',
        type: NotificationType.taskUpdate,
        relatedTaskId: taskId,
      );

      // Save payment notification to helper and push FCM
      final isOnlinePay = paymentMethod?.toLowerCase().contains('payhere') == true ||
          paymentMethod?.toLowerCase().contains('online') == true ||
          paymentMethod?.toLowerCase().contains('card') == true ||
          paymentMethod?.toLowerCase().contains('escrow') == true;
      final payNoticeMsg = isOnlinePay
          ? 'Payment Secured: LKR ${price.toStringAsFixed(2)} is held in Escrow for "${title ?? "Care Task"}".'
          : 'Cash Collection: Please collect LKR ${price.toStringAsFixed(2)} cash from the patient upon delivery.';

      await NotificationService.sendNotification(
        userId: helperId,
        title: isOnlinePay ? 'Escrow Payment Secured' : 'Cash on Delivery Reminder',
        message: payNoticeMsg,
        type: NotificationType.payment,
        relatedTaskId: taskId,
      );

      _triggerPatientStatusEdgeFunction(
        taskId: taskId,
        patientId: patientId!,
        step: TaskProgressStep.taskAccepted.name,
        title: title ?? 'Task',
        category: category ?? 'all',
        helperName: helperName,
      );

      // Push FCM to helper device for task acceptance and payment info
      _triggerHelperNotificationEdgeFunction(
        helperId: helperId,
        title: isOnlinePay ? 'Escrow Payment Secured' : 'Cash on Delivery Reminder',
        body: payNoticeMsg,
        taskId: taskId,
        type: 'payment',
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
    String? assignedHelperId;
    String? title;
    String? category;
    double price = 0.0;

    final success = await _db.runTransaction<bool>((transaction) async {
      final snapshot = await transaction.get(taskRef);
      if (!snapshot.exists) return false;

      final data = snapshot.data()!;
      final currentStepStr = data['progressStep'] as String? ?? TaskProgressStep.pending.name;
      patientId = data['patientId'] as String?;
      assignedHelperId = data['assignedHelperId'] as String?;
      title = data['title'] as String?;
      category = data['category'] as String? ?? 'all';
      price = (data['price'] as num?)?.toDouble() ?? 0.0;

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

    if (success) {
      if (step == TaskProgressStep.completed) {
        await PaymentService.updatePaymentStatus(taskId: taskId, status: PaymentStatus.released);
        await TaskAssignmentService.updateAssignmentStatus(taskId: taskId, status: AssignmentStatus.completed);
        
        if (assignedHelperId != null && assignedHelperId!.isNotEmpty) {
          // Increment the helper's global stats (earnings and tasks completed)
          await UserProfileService.incrementHelperStats(uid: assignedHelperId!, earnedAmount: price);
        }
      }

      final stepDisplayName = step.name.replaceAll(RegExp(r'([A-Z])'), ' \$1').toLowerCase();

      if (patientId != null && patientId!.isNotEmpty) {
        await NotificationService.sendNotification(
          userId: patientId!,
          title: 'Task Status Updated',
          message: 'Your task "${title ?? "Care Task"}" is now $stepDisplayName.',
          type: NotificationType.taskUpdate,
          relatedTaskId: taskId,
        );

        _triggerPatientStatusEdgeFunction(
          taskId: taskId,
          patientId: patientId!,
          step: step.name,
          title: title ?? 'Task',
          category: category ?? 'all',
          helperName: helperName,
        );
      }

      if (assignedHelperId != null && assignedHelperId!.isNotEmpty) {
        await NotificationService.sendNotification(
          userId: assignedHelperId!,
          title: 'Task Progress Updated',
          message: 'Task "${title ?? "Care Task"}" updated to $stepDisplayName.',
          type: NotificationType.taskUpdate,
          relatedTaskId: taskId,
        );

        _triggerHelperNotificationEdgeFunction(
          helperId: assignedHelperId!,
          title: 'Task Progress Updated',
          body: 'Task "${title ?? "Care Task"}" is now $stepDisplayName.',
          taskId: taskId,
          type: 'taskUpdate',
        );

        if (step == TaskProgressStep.completed) {
          await NotificationService.sendNotification(
            userId: assignedHelperId!,
            title: 'Payment Released!',
            message: 'Earnings for "${title ?? "Care Task"}" have been credited to your available wallet balance.',
            type: NotificationType.payment,
            relatedTaskId: taskId,
          );

          _triggerHelperNotificationEdgeFunction(
            helperId: assignedHelperId!,
            title: 'Payment Released!',
            body: 'Earnings for "${title ?? "Care Task"}" have been credited to your wallet balance.',
            taskId: taskId,
            type: 'payment',
          );
        }
      }
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

    await PaymentService.updatePaymentStatus(taskId: taskId, status: PaymentStatus.refunded);
    await TaskAssignmentService.updateAssignmentStatus(taskId: taskId, status: AssignmentStatus.cancelled);

    if (data != null) {
      final patientId = data['patientId'] as String?;
      final assignedHelperId = data['assignedHelperId'] as String?;
      final title = data['title'] as String? ?? 'Task';

      if (patientId != null && patientId.isNotEmpty) {
        await NotificationService.sendNotification(
          userId: patientId,
          title: 'Task Cancelled',
          message: 'Your task "$title" has been cancelled.',
          type: NotificationType.taskUpdate,
          relatedTaskId: taskId,
        );

        _triggerPatientStatusEdgeFunction(
          taskId: taskId,
          patientId: patientId,
          step: TaskProgressStep.cancelled.name,
          title: title,
          category: data['category'] as String? ?? 'all',
        );
      }

      if (assignedHelperId != null && assignedHelperId.isNotEmpty) {
        await NotificationService.sendNotification(
          userId: assignedHelperId,
          title: 'Task Cancelled',
          message: 'Task "$title" was cancelled by patient.',
          type: NotificationType.taskUpdate,
          relatedTaskId: taskId,
        );

        _triggerHelperNotificationEdgeFunction(
          helperId: assignedHelperId,
          title: 'Task Cancelled',
          body: 'Task "$title" was cancelled by the patient.',
          taskId: taskId,
          type: 'taskUpdate',
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

      await http.post(
        Uri.parse('$baseUrl/functions/v1/taskProgressNotificationsForPatient'),
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
      // Handles background patient notification triggers silently
    }
  }

  /// Triggers the Supabase Edge Function to push FCM notifications directly to a helper device
  static Future<void> _triggerHelperNotificationEdgeFunction({
    required String helperId,
    required String title,
    required String body,
    required String taskId,
    required String type,
  }) async {
    try {
      final String baseUrl = dotenv.env['SUPABASE_URL'] ?? '';
      final String anonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';
      if (baseUrl.isEmpty) return;

      await http.post(
        Uri.parse('$baseUrl/functions/v1/notifyHelper'),
        headers: {
          'Content-Type': 'application/json',
          if (anonKey.isNotEmpty) 'Authorization': 'Bearer $anonKey',
          if (anonKey.isNotEmpty) 'apikey': anonKey,
        },
        body: jsonEncode({
          'helperId': helperId,
          'title': title,
          'body': body,
          'taskId': taskId,
          'type': type,
        }),
      );
    } catch (_) {
      // Handles background helper notification triggers silently
    }
  }
}


