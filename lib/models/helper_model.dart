import 'dart:convert';

class HelperModel {
  final String id;
  final String fullName;
  final String icNumber;
  final String phoneNumber;
  final String email;
  final String profilePictureUrl;
  final double rating;
  final int totalTasksCompleted;
  final double todayEarnings;
  final String verificationStatus;
  final bool isOnline;
  final double? latitude;
  final double? longitude;
  final double completionRate;

  HelperModel({
    required this.id,
    required this.fullName,
    required this.icNumber,
    required this.phoneNumber,
    required this.email,
    this.profilePictureUrl = '',
    required this.rating,
    required this.totalTasksCompleted,
    required this.todayEarnings,
    required this.verificationStatus,
    required this.isOnline,
    this.latitude,
    this.longitude,
    this.completionRate = 100.0,
  });

  /// Evaluates and returns the helper performance rank tier based on ratings and completed tasks
  String get rankTier {
    if (totalTasksCompleted >= 50 && rating >= 4.8) return 'Platinum';
    if (totalTasksCompleted >= 21 && rating >= 4.7) return 'Gold';
    if (totalTasksCompleted >= 6 && rating >= 4.5) return 'Silver';
    return 'Bronze';
  }

  /// Creates a copy of HelperModel with optional updated fields
  HelperModel copyWith({
    String? fullName,
    String? icNumber,
    String? phoneNumber,
    String? email,
    String? profilePictureUrl,
    double? rating,
    int? totalTasksCompleted,
    double? todayEarnings,
    String? verificationStatus,
    bool? isOnline,
    double? latitude,
    double? longitude,
    double? completionRate,
  }) {
    return HelperModel(
      id: id,
      fullName: fullName ?? this.fullName,
      icNumber: icNumber ?? this.icNumber,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      rating: rating ?? this.rating,
      totalTasksCompleted: totalTasksCompleted ?? this.totalTasksCompleted,
      todayEarnings: todayEarnings ?? this.todayEarnings,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      isOnline: isOnline ?? this.isOnline,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      completionRate: completionRate ?? this.completionRate,
    );
  }

  /// Converts the HelperModel instance into a JSON-serializable Map
  Map<String, dynamic> toMap() {
    return {
      'uid': id,
      'fullName': fullName,
      'icNumber': icNumber,
      'phoneNumber': phoneNumber,
      'email': email,
      'profilePictureUrl': profilePictureUrl,
      'rating': rating,
      'totalTasksCompleted': totalTasksCompleted,
      'todayEarnings': todayEarnings,
      'verificationStatus': verificationStatus,
      'isOnline': isOnline,
      'latitude': latitude,
      'longitude': longitude,
      'completionRate': completionRate,
      'rankTier': rankTier,
    };
  }

  /// Deserializes a Map into a HelperModel object with fallback defaults
  factory HelperModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    return HelperModel(
      id: docId ?? map['uid'] as String? ?? '',
      fullName: map['fullName'] as String? ?? '',
      icNumber: map['icNumber'] as String? ?? '',
      phoneNumber: map['phone'] as String? ?? map['phoneNumber'] as String? ?? '',
      email: map['email'] as String? ?? '',
      profilePictureUrl: map['profilePictureUrl'] as String? ?? map['avatarUrl'] as String? ?? '',
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      totalTasksCompleted: (map['totalTasksCompleted'] as num?)?.toInt() ?? 0,
      todayEarnings: (map['todayEarnings'] as num?)?.toDouble() ?? 0.0,
      verificationStatus: map['verificationStatus'] as String? ?? 'Verified',
      isOnline: map['isOnline'] as bool? ?? true,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      completionRate: (map['completionRate'] as num?)?.toDouble() ?? 100.0,
    );
  }

  /// Converts the HelperModel to a JSON string representation
  String toJson() => jsonEncode(toMap());

  /// Creates a HelperModel instance from a JSON string
  factory HelperModel.fromJson(String source) =>
      HelperModel.fromMap(jsonDecode(source) as Map<String, dynamic>);
}