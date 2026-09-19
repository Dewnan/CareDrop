import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a support ticket raised by a patient or helper.
class SupportTicketModel {
  final String id;
  final String userId;
  final String userRole;
  final String userName;
  final String category;
  final String subject;
  final String description;
  final String status;
  final String priority;
  final String? relatedTaskId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? resolvedAt;

  SupportTicketModel({
    required this.id,
    required this.userId,
    required this.userRole,
    required this.userName,
    required this.category,
    required this.subject,
    this.description = '',
    this.status = 'open',
    this.priority = 'medium',
    this.relatedTaskId,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.resolvedAt,
  })  : createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Formats the raw category string into a human-readable label.
  String get categoryDisplay {
    switch (category) {
      case 'payment_issue':
        return 'Payment Issue';
      case 'task_dispute':
        return 'Task Dispute';
      case 'account_problem':
        return 'Account Problem';
      case 'helper_complaint':
        return 'Helper Complaint';
      case 'other':
      default:
        return 'Other';
    }
  }

  /// Converts the support ticket object into a key-value map for Firestore storage.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userRole': userRole,
      'userName': userName,
      'category': category,
      'subject': subject,
      'description': description.isNotEmpty ? description : subject,
      'status': status,
      'priority': priority,
      'relatedTaskId': relatedTaskId,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'lastMessageAt': Timestamp.fromDate(updatedAt),
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
    };
  }

  /// Creates a SupportTicketModel instance from a Firestore document map.
  factory SupportTicketModel.fromMap(Map<String, dynamic> map, {required String docId}) {
    return SupportTicketModel(
      id: docId,
      userId: map['userId'] as String? ?? '',
      userRole: map['userRole'] as String? ?? 'patient',
      userName: map['userName'] as String? ?? 'User',
      category: map['category'] as String? ?? 'other',
      subject: map['subject'] as String? ?? '',
      description: map['description'] as String? ?? map['subject'] as String? ?? '',
      status: map['status'] as String? ?? 'open',
      priority: map['priority'] as String? ?? 'medium',
      relatedTaskId: map['relatedTaskId'] as String?,
      createdAt: _parseDateTime(map['createdAt']),
      updatedAt: _parseDateTime(map['updatedAt'] ?? map['lastMessageAt']),
      resolvedAt: map['resolvedAt'] != null ? _parseDateTime(map['resolvedAt']) : null,
    );
  }

  /// Parses Firestore dynamic timestamp or ISO string into a DateTime object.
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }

  /// Converts the ticket instance to a JSON encoded string.
  String toJson() => jsonEncode(toMap());
}

/// Represents a single message within a support ticket chat thread.
class TicketMessageModel {
  final String id;
  final String senderId;
  final String senderRole;
  final String senderName;
  final String body;
  final DateTime createdAt;

  TicketMessageModel({
    required this.id,
    required this.senderId,
    required this.senderRole,
    this.senderName = 'User',
    required this.body,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Checks if the message was sent by an administrator.
  bool get isAdmin => senderRole == 'admin';

  /// Converts the ticket message instance into a key-value map for Firestore.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'sender': senderRole == 'admin' ? 'admin' : 'user',
      'senderId': senderId,
      'senderRole': senderRole,
      'senderName': senderName,
      'message': body,
      'body': body,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  /// Creates a TicketMessageModel instance from a Firestore map.
  factory TicketMessageModel.fromMap(Map<String, dynamic> map, {required String docId}) {
    final senderRaw = (map['sender'] as String?)?.toLowerCase();
    final roleRaw = (map['senderRole'] as String?)?.toLowerCase();
    final isAdmin = senderRaw == 'admin' || roleRaw == 'admin';

    final text = map['message'] as String? ??
        map['body'] as String? ??
        map['text'] as String? ??
        map['content'] as String? ??
        '';

    return TicketMessageModel(
      id: docId,
      senderId: map['senderId'] as String? ?? '',
      senderRole: isAdmin ? 'admin' : (roleRaw ?? senderRaw ?? 'user'),
      senderName: map['senderName'] as String? ?? (isAdmin ? 'CareDrop Support' : 'User'),
      body: text,
      createdAt: _parseDateTime(map['createdAt']),
    );
  }

  /// Parses Firestore dynamic timestamp or ISO string into a DateTime object.
  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is Timestamp) return value.toDate();
    if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
    return DateTime.now();
  }
}
