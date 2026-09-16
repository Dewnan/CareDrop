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

  /// Updates user profile fields including name, phone, gender, IC, and profile picture URL in Firestore
  static Future<void> updateUserProfile({
    required String uid,
    String? fullName,
    String? phone,
    String? gender,
    String? icNumber,
    String? profilePictureUrl,
  }) async {
    final Map<String, dynamic> updates = {
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (fullName != null) updates['fullName'] = fullName;
    if (phone != null) updates['phone'] = phone;
    if (gender != null) updates['gender'] = gender;
    if (icNumber != null) updates['icNumber'] = icNumber;
    if (profilePictureUrl != null) {
      updates['profilePictureUrl'] = profilePictureUrl;
      updates['avatarUrl'] = profilePictureUrl;
    }

    await _db.collection(_collectionPath).doc(uid).set(updates, SetOptions(merge: true));
  }

  /// Increments the total completed tasks count and today's earnings for a helper
  static Future<void> incrementHelperStats({
    required String uid,
    required double earnedAmount,
  }) async {
    if (uid.isEmpty) return;
    await _db.collection(_collectionPath).doc(uid).set({
      'totalTasksCompleted': FieldValue.increment(1),
      'todayEarnings': FieldValue.increment(earnedAmount),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
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

  /// Updates or registers the device FCM push token for any authenticated user profile (patient or helper)
  static Future<void> updateFcmToken({
    required String uid,
    required String fcmToken,
  }) async {
    if (uid.isEmpty || fcmToken.isEmpty) return;
    await _db.collection(_collectionPath).doc(uid).set(
      {
        'fcmToken': fcmToken,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
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
