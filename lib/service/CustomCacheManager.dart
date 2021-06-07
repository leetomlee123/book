import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class CustomCacheManager {
  static const fontKey = 'fontCacheKey';
  static const voiceKey = 'voiceKey';
  static CacheManager instanceFont = CacheManager(
    Config(
      fontKey,
      stalePeriod: const Duration(days: 1000),
      maxNrOfCacheObjects: 20,
      repo: JsonCacheInfoRepository(databaseName: fontKey),
      // fileSystem: IOFileSystem(key),
      fileService: HttpFileService(),
    ),
  );
  static CacheManager apk = CacheManager(
    Config(
      fontKey,
      stalePeriod: const Duration(days: 1),
      maxNrOfCacheObjects: 20,
      repo: JsonCacheInfoRepository(databaseName: "apk"),
      // fileSystem: IOFileSystem(key),
      fileService: HttpFileService(),
    ),
  );
  static CacheManager instanceVoice = CacheManager(
    Config(
      voiceKey,
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 20,
      repo: JsonCacheInfoRepository(databaseName: voiceKey),
      // fileSystem: IOFileSystem(key),
      fileService: HttpFileService(),
    ),
  );
  static CacheManager instanceVideo = CacheManager(
    Config(
      voiceKey,
      stalePeriod: const Duration(days: 1),
      maxNrOfCacheObjects: 20,
      repo: JsonCacheInfoRepository(databaseName: voiceKey),
      // fileSystem: IOFileSystem(key),
      fileService: HttpFileService(),
    ),
  );
}
