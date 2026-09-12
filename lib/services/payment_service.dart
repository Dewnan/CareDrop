import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/payment_model.dart';

/// Service managing CRUD operations and real-time streaming for the separate 'payments' Firestore collection.
class PaymentService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _collection = 'payments';

  /// Creates a new payment transaction document in the 'payments' collection when a task is created.
  static Future<String> createPaymentRecord({
    required String taskId,
    required String patientId,
    required double amount,
    required String paymentMethod,
  }) async {
    try {
      final docRef = _db.collection(_collection).doc();
      final isCash = paymentMethod.toLowerCase().contains('cash');
      final platformFee = isCash ? 0.0 : 30.0;
      final netHelper = amount - platformFee;

      final payment = PaymentModel(
        id: docRef.id,
        taskId: taskId,
        patientId: patientId,
        amount: amount,
        platformFee: platformFee,
        netHelperAmount: netHelper > 0 ? netHelper : amount,
        paymentMethod: paymentMethod,
        status: PaymentStatus.pending,
      );

      await docRef.set(payment.toMap());
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating payment record: $e');
      return '';
    }
  }

  /// Updates payee (assigned helper) when a helper accepts the task.
  static Future<void> assignHelperToPayment({
    required String taskId,
    required String helperId,
  }) async {
    try {
      final query = await _db.collection(_collection).where('taskId', isEqualTo: taskId).get();
      for (final doc in query.docs) {
        await doc.reference.update({
          'helperId': helperId,
          'status': PaymentStatus.escrow.name,
        });
      }
    } catch (e) {
      debugPrint('Error assigning helper to payment: $e');
    }
  }

  /// Updates payment status (e.g. released or refunded) when task progress updates.
  static Future<void> updatePaymentStatus({
    required String taskId,
    required PaymentStatus status,
  }) async {
    try {
      final query = await _db.collection(_collection).where('taskId', isEqualTo: taskId).get();
      for (final doc in query.docs) {
        await doc.reference.update({
          'status': status.name,
          if (status == PaymentStatus.released) 'releasedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Error updating payment status: $e');
    }
  }

  /// Streams all payments associated with a specific patient or helper user.
  static Stream<List<PaymentModel>> streamUserPayments(String userId) {
    if (userId.isEmpty) return Stream.value([]);
    return _db
        .collection(_collection)
        .where('patientId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => PaymentModel.fromMap(doc.data(), docId: doc.id))
          .toList();
    });
  }
}
