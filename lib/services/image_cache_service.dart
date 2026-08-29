import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Provides a configured CacheManager instance with auto-expiring cache policies to prevent disk bloat.
class ImageCacheService {
  static const String cacheKey = 'caredrop_image_cache';

  static final CacheManager instance = CacheManager(
    Config(
      cacheKey,
      stalePeriod: const Duration(days: 3),
      maxNrOfCacheObjects: 100,
      repo: JsonCacheInfoRepository(databaseName: cacheKey),
      fileService: HttpFileService(),
    ),
  );

  /// Clears all stored image cache files from local device storage.
  static Future<void> clearCache() async {
    await instance.emptyCache();
  }
}
