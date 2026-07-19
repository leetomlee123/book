import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// App cache managers used by the reader (fonts / optional APK update).
class CustomCacheManager {
  static const fontKey = 'fontCacheKey';

  static CacheManager instanceFont = CacheManager(
    Config(
      fontKey,
      stalePeriod: const Duration(days: 1000),
      maxNrOfCacheObjects: 20,
      repo: JsonCacheInfoRepository(databaseName: fontKey),
      fileService: HttpFileService(),
    ),
  );

  static CacheManager apk = CacheManager(
    Config(
      'apk',
      stalePeriod: const Duration(days: 1),
      maxNrOfCacheObjects: 5,
      repo: JsonCacheInfoRepository(databaseName: 'apk'),
      fileService: HttpFileService(),
    ),
  );
}
