enum TaskCategory { all, urgent, medicine, filing, queue, delivery }

enum TaskProgressStep {
  taskAccepted,
  enRoute,
  arrivedAtLocation,
  inProgress,
  uploadProof,
  completed,
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
}

class TaskModel {
  final String id;
  final String title;
  final String hospital;
  final String locationDetail;
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
    required this.title,
    required this.hospital,
    required this.locationDetail,
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
    this.progressStep = TaskProgressStep.taskAccepted,
    required this.proofItems,
  });

  TaskModel copyWith({
    TaskProgressStep? progressStep,
    List<ProofItem>? proofItems,
  }) {
    return TaskModel(
      id: id,
      title: title,
      hospital: hospital,
      locationDetail: locationDetail,
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
}
