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

class TaskModel {
  final String id;
  final String patientId;
  final String? assignedHelperId;
  final String title;
  final String hospital;
  final String locationDetail;
  final double? latitude;
  final double? longitude;
  final String distanceStr;
  final double distanceKm;
  final String currency;
  final double price;
  final bool isUrgent;
  final TaskCategory category;
  final String deadline;
  final String patientInfo;
  final String description;
  final String startTimeStr;
  final TaskProgressStep progressStep;
  final List<ProofItem> proofItems;

  TaskModel({
    required this.id,
    this.patientId = '',
    this.assignedHelperId,
    required this.title,
    required this.hospital,
    required this.locationDetail,
    this.latitude,
    this.longitude,
    required this.distanceStr,
    required this.distanceKm,
    required this.currency,
    required this.price,
    required this.isUrgent,
    required this.category,
    required this.deadline,
    required this.patientInfo,
    required this.description,
    required this.startTimeStr,
    this.progressStep = TaskProgressStep.pending,
    required this.proofItems,
  });

  TaskModel copyWith({
    String? id,
    String? patientId,
    String? assignedHelperId,
    TaskProgressStep? progressStep,
    List<ProofItem>? proofItems,
  }) {
    return TaskModel(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      assignedHelperId: assignedHelperId ?? this.assignedHelperId,
      title: title,
      hospital: hospital,
      locationDetail: locationDetail,
      latitude: latitude,
      longitude: longitude,
      distanceStr: distanceStr,
      distanceKm: distanceKm,
      currency: currency,
      price: price,
      isUrgent: isUrgent,
      category: category,
      deadline: deadline,
      patientInfo: patientInfo,
      description: description,
      startTimeStr: startTimeStr,
      progressStep: progressStep ?? this.progressStep,
      proofItems: proofItems ?? this.proofItems,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'patientId': patientId,
      'assignedHelperId': assignedHelperId,
      'title': title,
      'hospital': hospital,
      'locationDetail': locationDetail,
      'latitude': latitude,
      'longitude': longitude,
      'distanceStr': distanceStr,
      'distanceKm': distanceKm,
      'currency': currency,
      'price': price,
      'isUrgent': isUrgent,
      'category': category.name,
      'deadline': deadline,
      'patientInfo': patientInfo,
      'description': description,
      'startTimeStr': startTimeStr,
      'progressStep': progressStep.name,
      'proofItems': proofItems.map((e) => e.toMap()).toList(),
    };
  }

  factory TaskModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    return TaskModel(
      id: docId ?? map['id'] as String? ?? '',
      patientId: map['patientId'] as String? ?? '',
      assignedHelperId: map['assignedHelperId'] as String?,
      title: map['title'] as String? ?? '',
      hospital: map['hospital'] as String? ?? '',
      locationDetail: map['locationDetail'] as String? ?? '',
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      distanceStr: map['distanceStr'] as String? ?? '0.0 km',
      distanceKm: (map['distanceKm'] as num?)?.toDouble() ?? 0.0,
      currency: map['currency'] as String? ?? 'LKR',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      isUrgent: map['isUrgent'] as bool? ?? false,
      category: TaskCategory.values.firstWhere(
        (e) => e.name == map['category'],
        orElse: () => TaskCategory.medicine,
      ),
      deadline: map['deadline'] as String? ?? '',
      patientInfo: map['patientInfo'] as String? ?? '',
      description: map['description'] as String? ?? '',
      startTimeStr: map['startTimeStr'] as String? ?? '',
      progressStep: TaskProgressStep.values.firstWhere(
        (e) => e.name == map['progressStep'],
        orElse: () => TaskProgressStep.pending,
      ),
      proofItems: (map['proofItems'] as List<dynamic>?)
              ?.map((e) => ProofItem.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}
