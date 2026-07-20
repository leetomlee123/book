import 'package:book/common/app_log.dart';
import 'package:book/common/local_store.dart';
import 'package:book/data/repositories/chapter_repository.dart';

/// Disk page-layout cache policy (pages_json on reader.db chapters).
///
/// Body text remains in chapter body; this only bounds pagination JSON growth.
class ChapterCache {
  static const int defaultMaxMb = 100;
  static const int protectRadius = 30;
  static const String prefMaxMb = 'page_cache_max_mb';

  static DateTime? _lastEvictAt;
  static const _evictMinInterval = Duration(seconds: 15);

  static int maxBytes() {
    final mb = SpUtil.getInt(prefMaxMb, defValue: defaultMaxMb).clamp(20, 2048);
    return mb * 1024 * 1024;
  }

  /// Opportunistic eviction after page-cache writes.
  static Future<void> maybeEvict({
    String? activeBookId,
    int? activeCur,
  }) async {
    final now = DateTime.now();
    final last = _lastEvictAt;
    if (last != null && now.difference(last) < _evictMinInterval) {
      return;
    }
    _lastEvictAt = now;
    try {
      final chapters = ChapterRepository.instance;
      final before = await chapters.pageCacheBytes();
      final max = maxBytes();
      if (before <= max) return;
      final n = await chapters.evictPageCache(
        maxBytes: max,
        protectBookId: activeBookId,
        protectCenterIdx: activeCur ?? 0,
        protectRadius: protectRadius,
      );
      if (n > 0) {
        final after = await chapters.pageCacheBytes();
        AppLog.i(
          'Cache',
          'evict pages n=$n bytesBefore=$before bytesAfter=$after max=$max',
        );
      }
    } catch (e, st) {
      AppLog.w('Cache', 'maybeEvict failed', error: e);
      AppLog.d('Cache', '$st');
    }
  }
}
