import 'dart:convert';

class UserModel {
  final String id;
  final String email;
  final String fullName;
  final String role; // 'patient' or 'helper'
  final String gender;
  final String phone;
  final String icNumber;
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
    this.rating = 5.0,
    this.reviewCount = 0,
  });

  UserModel copyWith({
    String? id,
    String? email,
    String? fullName,
    String? role,
    String? gender,
    String? phone,
    String? icNumber,
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
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': id,
      'email': email,
      'fullName': fullName,
      'role': role,
      'gender': gender,
      'phone': phone,
      'icNumber': icNumber,
      'rating': rating,
      'reviewCount': reviewCount,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map, {String? docId}) {
    return UserModel(
      id: docId ?? map['uid'] as String? ?? '',
      email: map['email'] as String? ?? '',
      fullName: map['fullName'] as String? ?? '',
      role: map['role'] as String? ?? 'patient',
      gender: map['gender'] as String? ?? '',
      phone: map['phone'] as String? ?? map['phoneNumber'] as String? ?? '',
      icNumber: map['icNumber'] as String? ?? '',
      rating: (map['rating'] as num?)?.toDouble() ?? 5.0,
      reviewCount: (map['reviewCount'] as num?)?.toInt() ?? 0,
    );
  }

  String toJson() => jsonEncode(toMap());

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
