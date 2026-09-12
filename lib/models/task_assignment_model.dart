import 'dart:convert';

enum AssignmentStatus {
  active,
  completed,
  cancelled,
}

/// Model representing a task assignment match entry in the separate 'task_assignments' collection.
class TaskAssignmentModel {
  final String id;
  final String taskId;
  final String patientId;
  final String helperId;
  final String helperName;
  final AssignmentStatus status;
  final DateTime acceptedAt;
  final DateTime? completedAt;

  TaskAssignmentModel({
    required this.id,
    required this.taskId,
    required this.patientId,
    required this.helperId,
    this.helperName = 'Helper',
    this.status = AssignmentStatus.active,
    DateTime? acceptedAt,
    this.completedAt,
  }) : acceptedAt = acceptedAt ?? DateTime.now();

  TaskAssignmentModel copyWith({
    AssignmentStatus? status,
    DateTime? completedAt,
  }) {
    return TaskAssignmentModel(
      id: id,
      taskId: taskId,
      patientId: patientId,
      helperId: helperId,
      helperName: helperName,
      status: status ?? this.status,
      acceptedAt: acceptedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'taskId': taskId,
      'patientId': patientId,
      'helperId': helperId,
      'helperName': helperName,
      'status': status.name,
      'acceptedAt': acceptedAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  factory TaskAssignmentModel.fromMap(Map<String, dynamic> map, {required String docId}) {
    return TaskAssignmentModel(
      id: docId,
      taskId: map['taskId'] as String? ?? '',
      patientId: map['patientId'] as String? ?? '',
      helperId: map['helperId'] as String? ?? '',
      helperName: map['helperName'] as String? ?? 'Helper',
      status: AssignmentStatus.values.firstWhere(
        (e) => e.name == (map['status'] as String?),
        orElse: () => AssignmentStatus.active,
      ),
      acceptedAt: map['acceptedAt'] != null
          ? (map['acceptedAt'] is String
              ? DateTime.tryParse(map['acceptedAt'])
              : (map['acceptedAt'] as dynamic).toDate())
          : DateTime.now(),
      completedAt: map['completedAt'] != null
          ? (map['completedAt'] is String
              ? DateTime.tryParse(map['completedAt'])
              : (map['completedAt'] as dynamic).toDate())
          : null,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory TaskAssignmentModel.fromJson(String source) =>
      TaskAssignmentModel.fromMap(jsonDecode(source) as Map<String, dynamic>, docId: '');
}
