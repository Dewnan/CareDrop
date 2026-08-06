import 'dart:convert';

class HelperModel {
  final String id;
  final String fullName;
  final String icNumber;
  final String phoneNumber;
  final String email;
  final double rating;
  final int totalTasksCompleted;
  final double todayEarnings;
  final String verificationStatus;
  final bool isOnline;

  HelperModel({
    required this.id,
    required this.fullName,
    required this.icNumber,
    required this.phoneNumber,
    required this.email,
    required this.rating,
    required this.totalTasksCompleted,
    required this.todayEarnings,
    required this.verificationStatus,
    required this.isOnline,
  });

  HelperModel copyWith({
    String? fullName,
    String? icNumber,
    String? phoneNumber,
    String? email,
    double? rating,
    int? totalTasksCompleted,
    double? todayEarnings,
    String? verificationStatus,
    bool? isOnline,
  }) {
    return HelperModel(
      id: id,
      fullName: fullName ?? this.fullName,
      icNumber: icNumber ?? this.icNumber,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      rating: rating ?? this.rating,
      totalTasksCompleted: totalTasksCompleted ?? this.totalTasksCompleted,
      todayEarnings: todayEarnings ?? this.todayEarnings,
      verificationStatus: verificationStatus ?? this.verificationStatus,
      isOnline: isOnline ?? this.isOnline,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': id,
      'fullName': fullName,
      'icNumber': icNumber,
      'phoneNumber': phoneNumber,
      'email': email,
      'rating': rating,
      'totalTasksCompleted': totalTasksCompleted,
      'todayEarnings': todayEarnings,
      'verificationStatus': verificationStatus,
      'isOnline': isOnline,
    };
  }

  factory HelperModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    return HelperModel(
      id: docId ?? map['uid'] as String? ?? '',
      fullName: map['fullName'] as String? ?? '',
      icNumber: map['icNumber'] as String? ?? '',
      phoneNumber: map['phone'] as String? ?? map['phoneNumber'] as String? ?? '',
      email: map['email'] as String? ?? '',
      rating: (map['rating'] as num?)?.toDouble() ?? 5.0,
      totalTasksCompleted: (map['totalTasksCompleted'] as num?)?.toInt() ?? 0,
      todayEarnings: (map['todayEarnings'] as num?)?.toDouble() ?? 0.0,
      verificationStatus: map['verificationStatus'] as String? ?? 'Verified',
      isOnline: map['isOnline'] as bool? ?? true,
    );
  }

  String toJson() => jsonEncode(toMap());

  factory HelperModel.fromJson(String source) =>
      HelperModel.fromMap(jsonDecode(source) as Map<String, dynamic>);
}