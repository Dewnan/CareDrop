import 'dart:convert';

class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String role; // 'patient' or 'helper'
  final String gender;
  final String phone;
  final String icNumber;
  final String profilePictureUrl;
  final double rating;
  final int reviewCount;

  const UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.gender,
    required this.phone,
    this.icNumber = '',
    this.profilePictureUrl = '',
    this.rating = 5.0,
    this.reviewCount = 0,
  });

  /// Creates a copy of the current UserModel with updated fields
  UserModel copyWith({
    String? id,
    String? email,
    String? fullName,
    String? role,
    String? gender,
    String? phone,
    String? icNumber,
    String? profilePictureUrl,
    double? rating,
    int? reviewCount,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      gender: gender ?? this.gender,
      phone: phone ?? this.phone,
      icNumber: icNumber ?? this.icNumber,
      profilePictureUrl: profilePictureUrl ?? this.profilePictureUrl,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
    );
  }

  /// Converts the UserModel into a serializable map
  Map<String, dynamic> toMap() {
    return {
      'uid': id,
      'email': email,
      'fullName': fullName,
      'role': role,
      'gender': gender,
      'phone': phone,
      'icNumber': icNumber,
      'profilePictureUrl': profilePictureUrl,
      'rating': rating,
      'reviewCount': reviewCount,
    };
  }

  /// Deserializes a user document map into a UserModel instance
  factory UserModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    return UserModel(
      id: docId ?? map['uid'] as String? ?? '',
      email: map['email'] as String? ?? '',
      fullName: map['fullName'] as String? ?? '',
      role: map['role'] as String? ?? 'patient',
      gender: map['gender'] as String? ?? '',
      phone: map['phone'] as String? ?? map['phoneNumber'] as String? ?? '',
      icNumber: map['icNumber'] as String? ?? '',
      profilePictureUrl: map['profilePictureUrl'] as String? ?? map['avatarUrl'] as String? ?? '',
      rating: (map['rating'] as num?)?.toDouble() ?? 5.0,
      reviewCount: (map['reviewCount'] as num?)?.toInt() ?? 0,
    );
  }

  /// Converts the UserModel to a JSON string representation
  String toJson() => jsonEncode(toMap());

  /// Creates a UserModel instance from a JSON string
  factory UserModel.fromJson(String source) =>
      UserModel.fromMap(jsonDecode(source) as Map<String, dynamic>);
}

class MockUsers {
  static const UserModel patientUser = UserModel(
    id: 'p0001',
    email: 'dewnanc@proton.me',
    fullName: 'Patient Demo',
    role: 'patient',
    gender: 'Male',
    phone: '+94 70 000 0001',
  );

  static const UserModel helperUser = UserModel(
    id: 'h0001',
    email: 'dewnancw@proton.me',
    fullName: 'Helper Demo',
    role: 'helper',
    gender: 'Male',
    phone: '+94 70 000 0002',
  );
}
