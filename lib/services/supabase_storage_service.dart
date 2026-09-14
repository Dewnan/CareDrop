import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Provides helper methods for initializing Supabase and managing file uploads/downloads in the Supabase Storage documents bucket.
class SupabaseStorageService {
  static final SupabaseStorageService _instance = SupabaseStorageService._internal();
  factory SupabaseStorageService() => _instance;
  SupabaseStorageService._internal();

  bool _isInitialized = false;
  static const String documentsBucket = 'caredrop_documents';
  static const String avatarsBucket = 'caredrop_avatars';

  /// Validates whether a file name ends with an allowed image extension.
  static bool isImageFileName(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    return ['jpg', 'jpeg', 'png', 'webp', 'gif', 'heic', 'heif', 'bmp'].contains(ext);
  }

  /// Fetches the active Firebase user's ID token and constructs authorization headers for Supabase RLS
  Future<Map<String, String>> _getAuthHeaders() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final idToken = await user.getIdToken();
        if (idToken != null && idToken.isNotEmpty) {
          return {'Authorization': 'Bearer $idToken'};
        }
      } catch (e) {
        debugPrint('Error retrieving Firebase ID token for Supabase Storage: $e');
      }
    }
    return {};
  }

  /// Initializes the Supabase client using environment variables from dotenv or string environment definitions.
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await dotenv.load(fileName: ".env");
    } catch (_) {
      // Gracefully continue if .env file is missing or unreadable in production
    }

    final String url = dotenv.env['SUPABASE_URL'] ?? 
        const String.fromEnvironment('SUPABASE_URL', defaultValue: '');
    final String anonKey = dotenv.env['SUPABASE_ANON_KEY'] ?? 
        const String.fromEnvironment('SUPABASE_ANON_KEY', defaultValue: '');

    if (url.isNotEmpty && anonKey.isNotEmpty) {
      try {
        await Supabase.initialize(
          url: url,
          publishableKey: anonKey,
        );
        _isInitialized = true;
      } catch (e) {
        debugPrint('Failed to initialize Supabase client: $e');
      }
    } else {
      debugPrint('Supabase credentials missing or invalid placeholder.');
    }
  }

  /// Returns true if the Supabase client has been successfully initialized.
  bool get isInitialized => _isInitialized;

  /// Uploads a document or image file to the Supabase documents bucket and returns its public URL.
  Future<String?> uploadDocument({
    required File file,
    required String userId,
    required String fileName,
    String? taskId,
  }) async {
    if (!_isInitialized) {
      await initialize();
      if (!_isInitialized) {
        throw Exception('Supabase Storage is not configured. Please add valid credentials in .env.');
      }
    }

    try {
      final sanitizeName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
      final path = taskId != null && taskId.isNotEmpty
          ? '$userId/$taskId/${DateTime.now().millisecondsSinceEpoch}_$sanitizeName'
          : '$userId/${DateTime.now().millisecondsSinceEpoch}_$sanitizeName';

      final headers = await _getAuthHeaders();
      final storage = Supabase.instance.client.storage.from(documentsBucket);
      await storage.upload(
        path,
        file,
        fileOptions: FileOptions(cacheControl: '3600', upsert: true, headers: headers),
      );

      final String publicUrl = storage.getPublicUrl(path);
      return publicUrl;
    } catch (e) {
      debugPrint('Error uploading file to Supabase Storage: $e');
      rethrow;
    }
  }

  /// Uploads raw file bytes to the Supabase documents bucket for Web/Cross-platform compatibility.
  Future<String?> uploadDocumentBytes({
    required Uint8List bytes,
    required String userId,
    required String fileName,
    String? taskId,
  }) async {
    if (!_isInitialized) {
      await initialize();
      if (!_isInitialized) {
        throw Exception('Supabase Storage is not configured. Please add valid credentials in .env.');
      }
    }

    try {
      final sanitizeName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
      final path = taskId != null && taskId.isNotEmpty
          ? '$userId/$taskId/${DateTime.now().millisecondsSinceEpoch}_$sanitizeName'
          : '$userId/${DateTime.now().millisecondsSinceEpoch}_$sanitizeName';

      final headers = await _getAuthHeaders();
      final storage = Supabase.instance.client.storage.from(documentsBucket);
      await storage.uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(cacheControl: '3600', upsert: true, headers: headers),
      );

      final String publicUrl = storage.getPublicUrl(path);
      return publicUrl;
    } catch (e) {
      debugPrint('Error uploading bytes to Supabase Storage: $e');
      rethrow;
    }
  }

  /// Uploads a user profile image file to the Supabase caredrop_avatars bucket after validating the file extension.
  Future<String?> uploadAvatar({
    required File file,
    required String userId,
    required String fileName,
  }) async {
    if (!isImageFileName(fileName)) {
      throw Exception('Invalid file type. Only image files (JPG, PNG, WEBP, GIF, HEIC) are allowed.');
    }

    if (!_isInitialized) {
      await initialize();
      if (!_isInitialized) {
        throw Exception('Supabase Storage is not configured. Please add valid credentials in .env.');
      }
    }

    try {
      final sanitizeName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
      final path = '$userId/avatar_${DateTime.now().millisecondsSinceEpoch}_$sanitizeName';

      final headers = await _getAuthHeaders();
      final storage = Supabase.instance.client.storage.from(avatarsBucket);
      await storage.upload(
        path,
        file,
        fileOptions: FileOptions(cacheControl: '3600', upsert: true, headers: headers),
      );

      final String publicUrl = storage.getPublicUrl(path);
      return publicUrl;
    } catch (e) {
      debugPrint('Error uploading avatar to Supabase Storage: $e');
      rethrow;
    }
  }

  /// Uploads raw user profile image bytes to the Supabase caredrop_avatars bucket after validating the file extension.
  Future<String?> uploadAvatarBytes({
    required Uint8List bytes,
    required String userId,
    required String fileName,
  }) async {
    if (!isImageFileName(fileName)) {
      throw Exception('Invalid file type. Only image files (JPG, PNG, WEBP, GIF, HEIC) are allowed.');
    }

    if (!_isInitialized) {
      await initialize();
      if (!_isInitialized) {
        throw Exception('Supabase Storage is not configured. Please add valid credentials in .env.');
      }
    }

    try {
      final sanitizeName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
      final path = '$userId/avatar_${DateTime.now().millisecondsSinceEpoch}_$sanitizeName';

      final headers = await _getAuthHeaders();
      final storage = Supabase.instance.client.storage.from(avatarsBucket);
      await storage.uploadBinary(
        path,
        bytes,
        fileOptions: FileOptions(cacheControl: '3600', upsert: true, headers: headers),
      );

      final String publicUrl = storage.getPublicUrl(path);
      return publicUrl;
    } catch (e) {
      debugPrint('Error uploading avatar bytes to Supabase Storage: $e');
      rethrow;
    }
  }

  /// Generates a temporary signed access URL for private files in the documents bucket.
  Future<String?> createSignedUrl({
    required String path,
    int expiresInSeconds = 3600,
  }) async {
    if (!_isInitialized) return null;
    try {
      return await Supabase.instance.client.storage.from(documentsBucket).createSignedUrl(path, expiresInSeconds);
    } catch (e) {
      debugPrint('Error creating signed URL: $e');
      return null;
    }
  }
}
