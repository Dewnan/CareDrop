import 'dart:convert';

enum NotificationType { taskUpdate, helperMatch, payment, system }

/// Model representing a notification entry for patients and helpers.
class NotificationModel {
  final String id;
  final String userId;
  final String title;
  final String message;
  final DateTime timestamp;
  final NotificationType type;
  final String? relatedTaskId;
  final bool isRead;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.message,
    DateTime? timestamp,
    this.type = NotificationType.system,
    this.relatedTaskId,
    this.isRead = false,
  }) : timestamp = timestamp ?? DateTime.now();

  NotificationModel copyWith({
    bool? isRead,
  }) {
    return NotificationModel(
      id: id,
      userId: userId,
      title: title,
      message: message,
      timestamp: timestamp,
      type: type,
      relatedTaskId: relatedTaskId,
      isRead: isRead ?? this.isRead,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'type': type.name,
      'relatedTaskId': relatedTaskId,
      'isRead': isRead,
    };
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    return NotificationModel(
      id: docId ?? map['id'] as String? ?? '',
      userId: map['userId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      message: map['message'] as String? ?? '',
      timestamp: map['timestamp'] != null
          ? DateTime.tryParse(map['timestamp'] as String) ?? DateTime.now()
          : DateTime.now(),
      type: NotificationType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => NotificationType.system,
      ),
      relatedTaskId: map['relatedTaskId'] as String?,
      isRead: map['isRead'] as bool? ?? false,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory NotificationModel.fromJson(String source) =>
      NotificationModel.fromMap(jsonDecode(source) as Map<String, dynamic>);
}
