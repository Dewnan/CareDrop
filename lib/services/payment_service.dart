import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:payhere_mobilesdk_flutter/payhere_mobilesdk_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/payment_model.dart';
import 'supabase_storage_service.dart';

/// Service managing CRUD operations, PayHere payment gateway integration, and real-time payment streaming.
class PaymentService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _collection = 'payments';

  /// Invokes the Supabase Edge Function to generate the secure PayHere MD5 checkout signature hash
  static Future<Map<String, String>> generatePayHereHash({
    required String orderId,
    required double amount,
    required String currency,
  }) async {
    try {
      if (!SupabaseStorageService().isInitialized) {
        await SupabaseStorageService().initialize();
      }

      final response = await Supabase.instance.client.functions.invoke(
        'generate_payhere_hash',
        body: {
          'orderId': orderId,
          'amount': amount,
          'currency': currency.toUpperCase(),
        },
      );

      if (response.status != 200) {
        final errorMsg = response.data is Map
            ? (response.data['error'] ?? 'Edge Function error')
            : 'Edge Function error';
        throw Exception(errorMsg);
      }

      final data = response.data as Map<String, dynamic>;
      return {
        'merchantId': data['merchantId'] as String? ?? '',
        'hash': data['hash'] as String? ?? '',
        'amount': data['amount'] as String? ?? amount.toStringAsFixed(2),
        'currency': data['currency'] as String? ?? currency,
        'orderId': data['orderId'] as String? ?? orderId,
      };
    } catch (e) {
      debugPrint('Error generating PayHere MD5 hash signature: $e');
      rethrow;
    }
  }

  /// Launches the PayHere mobile SDK checkout modal to process card or wallet payments for a task order.
  static Future<String?> processPayHerePayment({
    required String orderId,
    required double amount,
    required String taskTitle,
    required String customerName,
    required String customerEmail,
    required String customerPhone,
    String currency = 'LKR',
  }) async {
    try {
      final hashData = await generatePayHereHash(
        orderId: orderId,
        amount: amount,
        currency: currency,
      );

      final merchantId =
          hashData['merchantId'] ?? dotenv.env['PAYHERE_MERCHANT_ID'] ?? '';
      final hash = hashData['hash'] ?? '';
      final formattedAmount = hashData['amount'] ?? amount.toStringAsFixed(2);
      final isSandbox =
          (dotenv.env['PAYHERE_MODE'] ?? 'SANDBOX').toUpperCase() == 'SANDBOX';

      if (merchantId.isEmpty || hash.isEmpty) {
        throw Exception(
          'PayHere configuration error: PAYHERE_MERCHANT_ID or signature hash is missing. Verify Supabase secrets.',
        );
      }

      final nameParts = customerName.trim().split(' ');
      final firstName = nameParts.isNotEmpty ? nameParts.first : 'Patient';
      final lastName = nameParts.length > 1
          ? nameParts.sublist(1).join(' ')
          : 'User';

      final paymentObject = {
        "sandbox": isSandbox,
        "merchant_id": merchantId,
        "notify_url":
            "https://irpeebknikmygzbgntde.supabase.co/functions/v1/payhere_notify",
        "order_id": orderId,
        "items": taskTitle.isNotEmpty ? taskTitle : "CareDrop Care Task",
        "amount": double.tryParse(formattedAmount) ?? amount,
        "currency": currency.toUpperCase(),
        "first_name": firstName,
        "last_name": lastName,
        "email": customerEmail.isNotEmpty
            ? customerEmail
            : "patient@caredrop.lk",
        "phone": customerPhone.isNotEmpty ? customerPhone : "+94770000000",
        "address": "Hospital / Residential Care",
        "city": "Colombo",
        "country": "Sri Lanka",
        "hash": hash,
      };

      String? resultPaymentId;
      String? errorMessage;
      bool isCompleted = false;

      PayHere.startPayment(
        paymentObject,
        (paymentId) {
          resultPaymentId = paymentId;
          isCompleted = true;
        },
        (error) {
          errorMessage = error;
          isCompleted = true;
        },
        () {
          errorMessage = "Payment modal closed by user.";
          isCompleted = true;
        },
      );

      // Wait for SDK callback completion
      int elapsed = 0;
      while (!isCompleted && elapsed < 120) {
        await Future.delayed(const Duration(milliseconds: 500));
        elapsed++;
      }

      if (errorMessage != null) {
        debugPrint('PayHere payment error: $errorMessage');
        throw Exception(errorMessage);
      }

      return resultPaymentId ?? 'PAYHERE_SUCCESS_$orderId';
    } catch (e) {
      debugPrint('Error initiating PayHere payment: $e');
      rethrow;
    }
  }

  /// Creates a new payment transaction document in the 'payments' collection when a task is created
  static Future<String> createPaymentRecord({
    required String taskId,
    required String patientId,
    required double amount,
    required String paymentMethod,
    String? payherePaymentId,
    PaymentStatus? initialStatus,
  }) async {
    try {
      final docRef = _db.collection(_collection).doc();
      final isCash = paymentMethod.toLowerCase().contains('cash');
      final platformFee = isCash ? 0.0 : 30.0;
      final netHelper = amount - platformFee;

      final status =
          initialStatus ??
          (!isCash ? PaymentStatus.escrow : PaymentStatus.pending);

      final payment = PaymentModel(
        id: docRef.id,
        taskId: taskId,
        patientId: patientId,
        amount: amount,
        platformFee: platformFee,
        netHelperAmount: netHelper > 0 ? netHelper : amount,
        paymentMethod: paymentMethod,
        payherePaymentId: payherePaymentId,
        status: status,
      );

      await docRef.set(payment.toMap());
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating payment record: $e');
      return '';
    }
  }

  /// Updates payee (assigned helper) when a helper accepts the task
  static Future<void> assignHelperToPayment({
    required String taskId,
    required String helperId,
  }) async {
    try {
      final query = await _db
          .collection(_collection)
          .where('taskId', isEqualTo: taskId)
          .get();
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

  /// Updates payment status (e.g. released or refunded) when task progress updates
  static Future<void> updatePaymentStatus({
    required String taskId,
    required PaymentStatus status,
  }) async {
    try {
      final query = await _db
          .collection(_collection)
          .where('taskId', isEqualTo: taskId)
          .get();
      for (final doc in query.docs) {
        await doc.reference.update({
          'status': status.name,
          if (status == PaymentStatus.released)
            'releasedAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Error updating payment status: $e');
    }
  }

  /// Streams all payments associated with a specific patient user
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

  /// Streams all payments assigned to a specific helper user
  static Stream<List<PaymentModel>> streamHelperPayments(String helperId) {
    if (helperId.isEmpty) return Stream.value([]);
    return _db
        .collection(_collection)
        .where('helperId', isEqualTo: helperId)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => PaymentModel.fromMap(doc.data(), docId: doc.id))
              .toList();
        });
  }
}

