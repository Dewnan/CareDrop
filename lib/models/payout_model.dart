import 'dart:convert';

enum PayoutStatus {
  requested,
  processing,
  completed,
  rejected,
}

/// Model storing helper bank account credentials for direct earnings transfers
class BankDetailsModel {
  final String bankName;
  final String accountHolderName;
  final String accountNumber;
  final String branchName;
  final String? branchCode;

  BankDetailsModel({
    required this.bankName,
    required this.accountHolderName,
    required this.accountNumber,
    required this.branchName,
    this.branchCode,
  });

  /// Checks whether all mandatory bank details fields are populated
  bool get isComplete =>
      bankName.trim().isNotEmpty &&
      accountHolderName.trim().isNotEmpty &&
      accountNumber.trim().isNotEmpty &&
      branchName.trim().isNotEmpty;

  /// Converts the BankDetailsModel object into a Map for database persistence
  Map<String, dynamic> toMap() {
    return {
      'bankName': bankName,
      'accountHolderName': accountHolderName,
      'accountNumber': accountNumber,
      'branchName': branchName,
      'branchCode': branchCode ?? '',
    };
  }

  /// Instantiates a BankDetailsModel object from a map payload
  factory BankDetailsModel.fromMap(Map<String, dynamic> map) {
    return BankDetailsModel(
      bankName: map['bankName'] as String? ?? '',
      accountHolderName: map['accountHolderName'] as String? ?? '',
      accountNumber: map['accountNumber'] as String? ?? '',
      branchName: map['branchName'] as String? ?? '',
      branchCode: map['branchCode'] as String?,
    );
  }
}

/// Represents a payout withdrawal request document submitted by a helper
class PayoutModel {
  final String id;
  final String helperId;
  final double amount;
  final String currency;
  final BankDetailsModel bankDetails;
  final PayoutStatus status;
  final DateTime createdAt;
  final DateTime? processedAt;
  final String? rejectionReason;

  PayoutModel({
    required this.id,
    required this.helperId,
    required this.amount,
    this.currency = 'LKR',
    required this.bankDetails,
    this.status = PayoutStatus.requested,
    DateTime? createdAt,
    this.processedAt,
    this.rejectionReason,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Converts PayoutModel instance into a Map structure for Firestore collection
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'helperId': helperId,
      'amount': amount,
      'currency': currency,
      'bankDetails': bankDetails.toMap(),
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'processedAt': processedAt?.toIso8601String(),
      'rejectionReason': rejectionReason,
    };
  }

  /// Instantiates a PayoutModel object from a Firestore document map
  factory PayoutModel.fromMap(Map<String, dynamic> map, {required String docId}) {
    return PayoutModel(
      id: docId,
      helperId: map['helperId'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      currency: map['currency'] as String? ?? 'LKR',
      bankDetails: BankDetailsModel.fromMap(
        (map['bankDetails'] as Map<String, dynamic>?) ?? {},
      ),
      status: PayoutStatus.values.firstWhere(
        (e) => e.name == (map['status'] as String?),
        orElse: () => PayoutStatus.requested,
      ),
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] is String
              ? DateTime.tryParse(map['createdAt'])
              : (map['createdAt'] as dynamic).toDate())
          : DateTime.now(),
      processedAt: map['processedAt'] != null
          ? (map['processedAt'] is String
              ? DateTime.tryParse(map['processedAt'])
              : (map['processedAt'] as dynamic).toDate())
          : null,
      rejectionReason: map['rejectionReason'] as String?,
    );
  }

  /// Serializes the PayoutModel into a JSON string
  String toJson() => jsonEncode(toMap());

  /// Deserializes a JSON string into a PayoutModel instance
  factory PayoutModel.fromJson(String source) =>
      PayoutModel.fromMap(jsonDecode(source) as Map<String, dynamic>, docId: '');
}
