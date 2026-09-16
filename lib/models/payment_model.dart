import 'dart:convert';

enum PaymentStatus {
  pending,
  authorized,
  escrow,
  released,
  refunded,
  failed,
}

/// Model representing a payment transaction record in the separate 'payments' collection.
class PaymentModel {
  final String id;
  final String taskId;
  final String patientId;
  final String? helperId;
  final double amount;
  final String currency;
  final double platformFee;
  final double netHelperAmount;
  final String paymentMethod;
  final String? payherePaymentId;
  final PaymentStatus status;
  final DateTime createdAt;
  final DateTime? releasedAt;

  PaymentModel({
    required this.id,
    required this.taskId,
    required this.patientId,
    this.helperId,
    required this.amount,
    this.currency = 'LKR',
    this.platformFee = 0.0,
    required this.netHelperAmount,
    this.paymentMethod = 'Cash',
    this.payherePaymentId,
    this.status = PaymentStatus.pending,
    DateTime? createdAt,
    this.releasedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Creates a copy of the PaymentModel with modified optional parameters
  PaymentModel copyWith({
    String? helperId,
    String? payherePaymentId,
    PaymentStatus? status,
    DateTime? releasedAt,
  }) {
    return PaymentModel(
      id: id,
      taskId: taskId,
      patientId: patientId,
      helperId: helperId ?? this.helperId,
      amount: amount,
      currency: currency,
      platformFee: platformFee,
      netHelperAmount: netHelperAmount,
      paymentMethod: paymentMethod,
      payherePaymentId: payherePaymentId ?? this.payherePaymentId,
      status: status ?? this.status,
      createdAt: createdAt,
      releasedAt: releasedAt ?? this.releasedAt,
    );
  }

  /// Converts the PaymentModel instance into a map structure suitable for Firestore storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'taskId': taskId,
      'patientId': patientId,
      'helperId': helperId,
      'amount': amount,
      'currency': currency,
      'platformFee': platformFee,
      'netHelperAmount': netHelperAmount,
      'paymentMethod': paymentMethod,
      'payherePaymentId': payherePaymentId,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'releasedAt': releasedAt?.toIso8601String(),
    };
  }

  /// Constructs a PaymentModel instance from a Firestore document map
  factory PaymentModel.fromMap(Map<String, dynamic> map, {required String docId}) {
    return PaymentModel(
      id: docId,
      taskId: map['taskId'] as String? ?? '',
      patientId: map['patientId'] as String? ?? '',
      helperId: map['helperId'] as String?,
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      currency: map['currency'] as String? ?? 'LKR',
      platformFee: (map['platformFee'] as num?)?.toDouble() ?? 0.0,
      netHelperAmount: (map['netHelperAmount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: map['paymentMethod'] as String? ?? 'Cash',
      payherePaymentId: map['payherePaymentId'] as String? ?? map['stripePaymentIntentId'] as String?,
      status: PaymentStatus.values.firstWhere(
        (e) => e.name == (map['status'] as String?),
        orElse: () => PaymentStatus.pending,
      ),
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] is String
              ? DateTime.tryParse(map['createdAt'])
              : (map['createdAt'] as dynamic).toDate())
          : DateTime.now(),
      releasedAt: map['releasedAt'] != null
          ? (map['releasedAt'] is String
              ? DateTime.tryParse(map['releasedAt'])
              : (map['releasedAt'] as dynamic).toDate())
          : null,
    );
  }


  /// Serializes the PaymentModel into a JSON string
  String toJson() => jsonEncode(toMap());

  /// Creates a PaymentModel instance from a JSON string representation
  factory PaymentModel.fromJson(String source) =>
      PaymentModel.fromMap(jsonDecode(source) as Map<String, dynamic>, docId: '');
}

