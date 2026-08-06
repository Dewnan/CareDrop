import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';

class UserSessionService {
  static const String _userCacheKey = 'cached_user_profile';
  static const String _roleCacheKey = 'cached_user_role';

  // Save profile to SharedPreferences
  static Future<void> saveCachedUser(UserModel user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userCacheKey, user.toJson());
      await prefs.setString(_roleCacheKey, user.role.toLowerCase());
    } catch (e) {
      debugPrint('Error saving cached user: $e');
    }
  }

  // Retrieve profile from SharedPreferences
  static Future<UserModel?> getCachedUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_userCacheKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        return UserModel.fromJson(jsonStr);
      }
    } catch (e) {
      debugPrint('Error loading cached user: $e');
    }
    return null;
  }

  // Get cached role
  static Future<String?> getCachedRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_roleCacheKey);
    } catch (e) {
      debugPrint('Error loading cached role: $e');
    }
    return null;
  }

  // Clear cache on logout
  static Future<void> clearCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userCacheKey);
      await prefs.remove(_roleCacheKey);
    } catch (e) {
      debugPrint('Error clearing cached user: $e');
    }
  }

  // Fetch from Firestore users collection with cache backup
  static Future<UserModel?> fetchUserProfile(String uid) async {
    try {
      final doc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (doc.exists && doc.data() != null) {
        final userModel = UserModel.fromMap(doc.data()!, docId: uid);
        await saveCachedUser(userModel);
        return userModel;
      }
    } catch (e) {
      debugPrint('Firestore fetch error for $uid (falling back to cache): $e');
    }
    // Fallback to cache
    return await getCachedUser();
  }
}
