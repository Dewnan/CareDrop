import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/payout_model.dart';

/// Manages database operations for storing helper bank account credentials and processing payout withdrawal requests
class PayoutService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _usersCollection = 'users';
  static const String _payoutsCollection = 'payouts';

  /// Minimum withdrawal amount threshold enforced for payout requests
  static const double minPayoutThreshold = 1000.0;

  /// Saves or updates the helper bank account details in the user's Firestore document
  static Future<bool> saveBankDetails({
    required String helperId,
    required BankDetailsModel bankDetails,
  }) async {
    if (helperId.isEmpty) return false;
    try {
      await _db.collection(_usersCollection).doc(helperId).set({
        'bankDetails': bankDetails.toMap(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return true;
    } catch (e) {
      debugPrint('Error saving bank details for helper $helperId: $e');
      return false;
    }
  }

  /// Fetches saved bank account details for a given helper
  static Future<BankDetailsModel?> getBankDetails(String helperId) async {
    if (helperId.isEmpty) return null;
    try {
      final doc = await _db.collection(_usersCollection).doc(helperId).get();
      if (!doc.exists) return null;

      final data = doc.data();
      if (data == null || data['bankDetails'] == null) return null;

      return BankDetailsModel.fromMap(
        Map<String, dynamic>.from(data['bankDetails'] as Map),
      );
    } catch (e) {
      debugPrint('Error fetching bank details for helper $helperId: $e');
      return null;
    }
  }

  /// Submits a new payout withdrawal request after validating bank details and threshold requirements
  static Future<String> requestPayout({
    required String helperId,
    required double amount,
    required double availableBalance,
  }) async {
    if (helperId.isEmpty) {
      throw Exception('User authentication required.');
    }

    if (amount < minPayoutThreshold) {
      throw Exception('Minimum payout threshold is LKR ${minPayoutThreshold.toStringAsFixed(0)}.');
    }

    if (amount > availableBalance) {
      throw Exception('Requested amount exceeds available balance of LKR ${availableBalance.toStringAsFixed(2)}.');
    }

    final bankDetails = await getBankDetails(helperId);
    if (bankDetails == null || !bankDetails.isComplete) {
      throw Exception('Please set up your Bank Details before requesting a payout withdrawal.');
    }

    try {
      final docRef = _db.collection(_payoutsCollection).doc();
      final payout = PayoutModel(
        id: docRef.id,
        helperId: helperId,
        amount: amount,
        bankDetails: bankDetails,
        status: PayoutStatus.requested,
      );

      await docRef.set(payout.toMap());
      return docRef.id;
    } catch (e) {
      debugPrint('Error creating payout request: $e');
      throw Exception('Failed to submit payout request. Please try again.');
    }
  }

  /// Streams real-time payout history for a specific helper
  static Stream<List<PayoutModel>> streamHelperPayouts(String helperId) {
    if (helperId.isEmpty) return Stream.value([]);
    return _db
        .collection(_payoutsCollection)
        .where('helperId', isEqualTo: helperId)
        .snapshots()
        .map((snapshot) {
      final list = snapshot.docs
          .map((doc) => PayoutModel.fromMap(doc.data(), docId: doc.id))
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    });
  }
}
