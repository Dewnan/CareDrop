import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class UserProfileService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static const String _collectionPath = 'users';

  /// Create a new user profile document in Firestore
  static Future<void> createUserProfile(UserModel user) async {
    await _db.collection(_collectionPath).doc(user.id).set(
      {
        ...user.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  /// Read / Fetch user profile by UID
  static Future<UserModel?> getUserProfile(String uid) async {
    final doc = await _db.collection(_collectionPath).doc(uid).get();
    if (doc.exists && doc.data() != null) {
      return UserModel.fromMap(doc.data()!, docId: doc.id);
    }
    return null;
  }

  /// Stream real-time updates for a single user profile
  static Stream<UserModel?> streamUserProfile(String uid) {
    return _db.collection(_collectionPath).doc(uid).snapshots().map((doc) {
      if (doc.exists && doc.data() != null) {
        return UserModel.fromMap(doc.data()!, docId: doc.id);
      }
      return null;
    });
  }

  /// Update user profile data
  static Future<void> updateUserProfile({
    required String uid,
    String? fullName,
    String? phone,
    String? gender,
    String? icNumber,
  }) async {
    final Map<String, dynamic> updates = {
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (fullName != null) updates['fullName'] = fullName;
    if (phone != null) updates['phone'] = phone;
    if (gender != null) updates['gender'] = gender;
    if (icNumber != null) updates['icNumber'] = icNumber;

    await _db.collection(_collectionPath).doc(uid).update(updates);
  }

  /// Updates the online availability status, FCM push token, and current GPS coordinates for a helper profile
  static Future<void> updateOnlineStatus({
    required String uid,
    required bool isOnline,
    double? latitude,
    double? longitude,
    String? fcmToken,
  }) async {
    if (uid.isEmpty) return;
    final Map<String, dynamic> updates = {
      'isOnline': isOnline,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (latitude != null) updates['latitude'] = latitude;
    if (longitude != null) updates['longitude'] = longitude;
    if (fcmToken != null && fcmToken.isNotEmpty) updates['fcmToken'] = fcmToken;

    await _db.collection(_collectionPath).doc(uid).set(updates, SetOptions(merge: true));
  }

  /// Query profiles by role ('patient' or 'helper')
  static Future<List<UserModel>> getUsersByRole(String role) async {
    final snapshot = await _db
        .collection(_collectionPath)
        .where('role', isEqualTo: role)
        .get();

    return snapshot.docs
        .map((doc) => UserModel.fromMap(doc.data(), docId: doc.id))
        .toList();
  }
}
