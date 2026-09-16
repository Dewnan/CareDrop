enum TaskCategory { all, urgent, medicine, filing, queue, delivery }

enum TaskProgressStep {
  pending,
  taskAccepted,
  enRoute,
  arrivedAtLocation,
  inProgress,
  uploadProof,
  completed,
  cancelled,
}

/// Evaluates whether a task progress step can legally transition to a target step.
extension TaskProgressStepX on TaskProgressStep {
  bool canTransitionTo(TaskProgressStep nextStep) {
    if (this == nextStep) return true;
    if (nextStep == TaskProgressStep.cancelled) return this != TaskProgressStep.completed;
    switch (this) {
      case TaskProgressStep.pending:
        return nextStep == TaskProgressStep.taskAccepted;
      case TaskProgressStep.taskAccepted:
      case TaskProgressStep.enRoute:
      case TaskProgressStep.arrivedAtLocation:
      case TaskProgressStep.inProgress:
      case TaskProgressStep.uploadProof:
        return nextStep.index > index && nextStep != TaskProgressStep.cancelled;
      case TaskProgressStep.completed:
        return false;
      case TaskProgressStep.cancelled:
        return nextStep == TaskProgressStep.pending;
    }
  }
}

class ProofItem {
  final String title;
  final bool isRequired;
  final bool isUploaded;
  final String? imagePath;

  ProofItem({
    required this.title,
    required this.isRequired,
    this.isUploaded = false,
    this.imagePath,
  });

  ProofItem copyWith({
    bool? isUploaded,
    String? imagePath,
  }) {
    return ProofItem(
      title: title,
      isRequired: isRequired,
      isUploaded: isUploaded ?? this.isUploaded,
      imagePath: imagePath ?? this.imagePath,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'isRequired': isRequired,
      'isUploaded': isUploaded,
      'imagePath': imagePath,
    };
  }

  factory ProofItem.fromMap(Map<String, dynamic> map) {
    return ProofItem(
      title: map['title'] as String? ?? '',
      isRequired: map['isRequired'] as bool? ?? false,
      isUploaded: map['isUploaded'] as bool? ?? false,
      imagePath: map['imagePath'] as String?,
    );
  }
}

/// Represents a task posted by a patient and its full lifecycle state in Firestore
class TaskModel {
  final String id;
  final String patientId;
  final String? assignedHelperId;
  final String title;
  // pickupAddress is the primary location field (replaces legacy 'hospital')
  final String pickupAddress;
  final double? pickupLat;
  final double? pickupLng;
  final String? dropoffAddress;
  final double? dropoffLat;
  final double? dropoffLng;
  // roomDetail stores room/bed/ward info (replaces legacy 'locationDetail')
  final String roomDetail;
  final String currency;
  final double price;
  final bool isUrgent;
  final TaskCategory category;
  final String deadline;
  final String description;
  final TaskProgressStep progressStep;
  final List<ProofItem> proofItems;
  final String? attachmentUrl;
  final String? attachmentFileName;
  final String? serviceDuration;
  final String? preferredGender;
  final String? preferredLanguage;
  final String? itemName;
  final String? itemQuantity;
  final String? itemSpecialInstructions;
  final String? paymentMethod;
  final String? payherePaymentId;
  final String? contactPreference;

  TaskModel({
    required this.id,
    this.patientId = '',
    this.assignedHelperId,
    required this.title,
    required this.pickupAddress,
    this.pickupLat,
    this.pickupLng,
    this.dropoffAddress,
    this.dropoffLat,
    this.dropoffLng,
    this.roomDetail = '',
    required this.currency,
    required this.price,
    required this.isUrgent,
    required this.category,
    required this.deadline,
    required this.description,
    this.progressStep = TaskProgressStep.pending,
    required this.proofItems,
    this.attachmentUrl,
    this.attachmentFileName,
    this.serviceDuration,
    this.preferredGender,
    this.preferredLanguage,
    this.itemName,
    this.itemQuantity,
    this.itemSpecialInstructions,
    this.paymentMethod,
    this.payherePaymentId,
    this.contactPreference,
  });

  /// Creates a copy of the task model with optional field overrides
  TaskModel copyWith({
    String? id,
    String? patientId,
    String? assignedHelperId,
    String? pickupAddress,
    double? pickupLat,
    double? pickupLng,
    String? dropoffAddress,
    double? dropoffLat,
    double? dropoffLng,
    String? roomDetail,
    TaskProgressStep? progressStep,
    List<ProofItem>? proofItems,
    String? attachmentUrl,
    String? attachmentFileName,
    String? serviceDuration,
    String? preferredGender,
    String? preferredLanguage,
    String? itemName,
    String? itemQuantity,
    String? itemSpecialInstructions,
    String? paymentMethod,
    String? payherePaymentId,
    String? contactPreference,
  }) {
    return TaskModel(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      assignedHelperId: assignedHelperId ?? this.assignedHelperId,
      title: title,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      pickupLat: pickupLat ?? this.pickupLat,
      pickupLng: pickupLng ?? this.pickupLng,
      dropoffAddress: dropoffAddress ?? this.dropoffAddress,
      dropoffLat: dropoffLat ?? this.dropoffLat,
      dropoffLng: dropoffLng ?? this.dropoffLng,
      roomDetail: roomDetail ?? this.roomDetail,
      currency: currency,
      price: price,
      isUrgent: isUrgent,
      category: category,
      deadline: deadline,
      description: description,
      progressStep: progressStep ?? this.progressStep,
      proofItems: proofItems ?? this.proofItems,
      attachmentUrl: attachmentUrl ?? this.attachmentUrl,
      attachmentFileName: attachmentFileName ?? this.attachmentFileName,
      serviceDuration: serviceDuration ?? this.serviceDuration,
      preferredGender: preferredGender ?? this.preferredGender,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      itemName: itemName ?? this.itemName,
      itemQuantity: itemQuantity ?? this.itemQuantity,
      itemSpecialInstructions: itemSpecialInstructions ?? this.itemSpecialInstructions,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      payherePaymentId: payherePaymentId ?? this.payherePaymentId,
      contactPreference: contactPreference ?? this.contactPreference,
    );
  }

  /// Converts TaskModel fields into a clean Map for Firestore storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientId': patientId,
      'assignedHelperId': assignedHelperId,
      'title': title,
      'pickupAddress': pickupAddress,
      'pickupLat': pickupLat,
      'pickupLng': pickupLng,
      'dropoffAddress': dropoffAddress,
      'dropoffLat': dropoffLat,
      'dropoffLng': dropoffLng,
      'roomDetail': roomDetail,
      'currency': currency,
      'price': price,
      'isUrgent': isUrgent,
      'category': category.name,
      'deadline': deadline,
      'description': description,
      'progressStep': progressStep.name,
      'proofItems': proofItems.map((e) => e.toMap()).toList(),
      'attachmentUrl': attachmentUrl,
      'attachmentFileName': attachmentFileName,
      'serviceDuration': serviceDuration,
      'preferredGender': preferredGender,
      'preferredLanguage': preferredLanguage,
      'itemName': itemName,
      'itemQuantity': itemQuantity,
      'itemSpecialInstructions': itemSpecialInstructions,
      'paymentMethod': paymentMethod,
      'payherePaymentId': payherePaymentId,
      'contactPreference': contactPreference,
    };
  }

  /// Constructs a TaskModel instance from a Firestore document map with backward-compat fallbacks for legacy fields
  factory TaskModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    // Backward-compat: 'hospital' and 'pickupAddress' both map to pickupAddress
    final pickup = (map['pickupAddress'] as String?)?.isNotEmpty == true
        ? map['pickupAddress'] as String
        : (map['hospital'] as String? ?? '');

    // Backward-compat: 'locationDetail' maps to roomDetail
    final room = map['roomDetail'] as String? ??
        map['locationDetail'] as String? ?? '';

    return TaskModel(
      id: docId ?? map['id'] as String? ?? '',
      patientId: map['patientId'] as String? ?? '',
      assignedHelperId: map['assignedHelperId'] as String?,
      title: map['title'] as String? ?? '',
      pickupAddress: pickup,
      pickupLat: (map['pickupLat'] as num?)?.toDouble(),
      pickupLng: (map['pickupLng'] as num?)?.toDouble(),
      dropoffAddress: map['dropoffAddress'] as String?,
      dropoffLat: (map['dropoffLat'] as num?)?.toDouble(),
      dropoffLng: (map['dropoffLng'] as num?)?.toDouble(),
      roomDetail: room,
      currency: map['currency'] as String? ?? 'LKR',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      isUrgent: map['isUrgent'] as bool? ?? false,
      category: TaskCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => TaskCategory.medicine,
      ),
      deadline: map['deadline'] as String? ?? '',
      description: map['description'] as String? ?? '',
      progressStep: TaskProgressStep.values.firstWhere(
        (e) => e.name == map['progressStep'],
        orElse: () => TaskProgressStep.pending,
      ),
      proofItems: (map['proofItems'] as List<dynamic>?)
              ?.map((e) => ProofItem.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
      attachmentUrl: map['attachmentUrl'] as String?,
      attachmentFileName: map['attachmentFileName'] as String?,
      serviceDuration: map['serviceDuration'] as String?,
      preferredGender: map['preferredGender'] as String?,
      preferredLanguage: map['preferredLanguage'] as String?,
      itemName: map['itemName'] as String?,
      itemQuantity: map['itemQuantity'] as String?,
      itemSpecialInstructions: map['itemSpecialInstructions'] as String?,
      paymentMethod: map['paymentMethod'] as String?,
      payherePaymentId: map['payherePaymentId'] as String? ?? map['stripePaymentIntentId'] as String?,
      contactPreference: map['contactPreference'] as String?,
    );
  }
}
