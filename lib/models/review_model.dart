import 'dart:convert';

/// Model representing a patient review entry in the separate 'reviews' Firestore collection.
class ReviewModel {
  final String id;
  final String taskId;
  final String reviewerId;
  final String reviewerName;
  final String helperId;
  final double rating;
  final String comment;
  final List<String> tags;
  final DateTime createdAt;

  ReviewModel({
    required this.id,
    required this.taskId,
    required this.reviewerId,
    required this.reviewerName,
    required this.helperId,
    required this.rating,
    this.comment = '',
    this.tags = const [],
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  String get avatarInitials {
    if (reviewerName.trim().isEmpty) return 'P';
    final parts = reviewerName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return reviewerName[0].toUpperCase();
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'taskId': taskId,
      'reviewerId': reviewerId,
      'reviewerName': reviewerName,
      'helperId': helperId,
      'rating': rating,
      'comment': comment,
      'tags': tags,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ReviewModel.fromMap(Map<String, dynamic> map, {required String docId}) {
    return ReviewModel(
      id: docId,
      taskId: map['taskId'] as String? ?? '',
      reviewerId: map['reviewerId'] as String? ?? '',
      reviewerName: map['reviewerName'] as String? ?? 'Patient User',
      helperId: map['helperId'] as String? ?? '',
      rating: (map['rating'] as num?)?.toDouble() ?? 5.0,
      comment: map['comment'] as String? ?? '',
      tags: map['tags'] != null ? List<String>.from(map['tags'] as Iterable) : const [],
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] is String
              ? DateTime.tryParse(map['createdAt'])
              : (map['createdAt'] as dynamic).toDate())
          : DateTime.now(),
    );
  }

  String toJson() => jsonEncode(toMap());

  factory ReviewModel.fromJson(String source) =>
      ReviewModel.fromMap(jsonDecode(source) as Map<String, dynamic>, docId: '');
}

// Alias for backwards compatibility
typedef ReviewItem = ReviewModel;
