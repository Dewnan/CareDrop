class UserModel {
  final String id;
  final String email;
  final String password;
  final String fullName;
  final String role; // 'Patient' or 'Helper'
  final String gender;
  final String phone;

  const UserModel({
    required this.id,
    required this.email,
    required this.password,
    required this.fullName,
    required this.role,
    required this.gender,
    required this.phone,
  });
}

class MockUsers {
  static const UserModel patientUser = UserModel(
    id: 'user_patient_01',
    email: 'patient@caredrop.lk',
    password: 'password123',
    fullName: 'Sahan Wishwapriya',
    role: 'Patient',
    gender: 'Male',
    phone: '+9470000001',
  );

  static const UserModel helperUser = UserModel(
    id: 'user_helper_01',
    email: 'helper@caredrop.lk',
    password: 'password123',
    fullName: 'Dewnan Chamithka',
    role: 'Helper',
    gender: 'Male',
    phone: '+9470000002',
  );
}
