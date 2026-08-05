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
}