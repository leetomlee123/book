import 'dart:ui' as ui;

import 'package:book/entity/book.dart';
import 'package:book/entity/read_page.dart';
import 'package:book/model/reader/page_picture_cache.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

/// Resolves painted page pictures for the active reading position.
///
/// Owns cache lookup + neighbor preload scheduling. Painting is delegated via
/// [drawContent]; chapter loads via [loadChapter].
class PagePictureResolver {
  PagePictureResolver({
    required this.cache,
    required this.drawContent,
    required this.loadChapter,
    required this.bookOf,
    required this.curPageOf,
    required this.prePageOf,
    required this.nextPageOf,
    required this.setNextPage,
    required this.activeBookId,
  });

  final PagePictureCache cache;
  final ui.Picture Function(ReadPage page, int pageIndex) drawContent;
  final Future<ReadPage?> Function(int chapterIndex) loadChapter;
  final Book? Function() bookOf;
  final ReadPage? Function() curPageOf;
  final ReadPage? Function() prePageOf;
  final ReadPage? Function() nextPageOf;
  final void Function(ReadPage? page) setNextPage;
  final String? Function() activeBookId;

  /// Cancels stale post-frame preload callbacks when the reading position moves.
  int _warmGeneration = 0;

  /// Prevents spamming [loadChapter] while cover drag repeatedly asks for next.
  int? _loadingNextChapter;

  static String _key(String bookId, int chapterIndex, int pageIndex) =>
      '$bookId|$chapterIndex|$pageIndex';

  static String _scrollKey(String bookId, int chapterIndex, int pageIndex) =>
      '$bookId|$chapterIndex|$pageIndex|sc';

  void _log(String msg) {
    if (kDebugMode) debugPrint('[PictureCache] $msg');
  }

  ui.Picture? resolveCurrent({bool firstInit = false}) {
    final b = bookOf();
    if (b == null) return null;
    final key = _key(b.id, b.chapterIndex, b.pageIndex);
    if (cache.containsKey(key)) {
      if (firstInit) scheduleNeighborWarm();
      return cache[key];
    }
    final pic = paintCurrent();
    if (firstInit) {
      scheduleNeighborWarm();
    }
    return pic;
  }

  /// Eagerly paint current page (if missing) then schedule prev/next on the
  /// next frame so the first gesture never cold-records mid-drag.
  void warmAroundCurrent({bool includeNeighbors = true}) {
    final b = bookOf();
    final current = curPageOf();
    if (b == null || current == null || current.pages.isEmpty) return;
    paintCurrent();
    if (includeNeighbors) {
      scheduleNeighborWarm();
    }
  }

  /// Post-frame neighbor preload (replaces the old 200 ms blind delay).
  void scheduleNeighborWarm() {
    final gen = ++_warmGeneration;
    final bookId = bookOf()?.id;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (gen != _warmGeneration) return;
      if (activeBookId() != bookId) return;
      preloadNeighbors();
    });
  }

  void preloadNeighbors() {
    final b = bookOf();
    final current = curPageOf();
    if (b == null || current == null) return;
    final sw = kDebugMode ? (Stopwatch()..start()) : null;
    if (prePageOf() != null || b.pageIndex > 0) {
      paintPrevious();
    }
    if (nextPageOf() != null || b.pageIndex + 1 < current.pageOffsets) {
      paintNext();
    }
    if (sw != null) {
      sw.stop();
      _log(
        'preloadNeighbors cur=${b.chapterIndex}:${b.pageIndex} '
        'ms=${sw.elapsedMilliseconds}',
      );
    }
  }

  /// Call when [nextPage]/[prePage] async loads complete so cover bottom layer
  /// is ready before the next gesture.
  void onNeighborChapterReady() {
    scheduleNeighborWarm();
  }

  ui.Picture? paintPrevious() {
    final b = bookOf();
    final current = curPageOf();
    if (b == null || current == null) return null;
    final i = b.pageIndex - 1;
    final key = _key(b.id, b.chapterIndex, i);
    if (cache.containsKey(key)) return cache[key];

    final sw = kDebugMode ? (Stopwatch()..start()) : null;
    final ui.Picture pic;
    if (i < 0) {
      final previous = prePageOf();
      if (previous == null || previous.pages.isEmpty) {
        _log('miss previous (no pre chapter)');
        return null;
      }
      pic = drawContent(previous, previous.pageOffsets - 1);
    } else {
      pic = drawContent(current, i);
    }
    final out = cache.putIfAbsent(key, () => pic);
    if (sw != null) {
      sw.stop();
      _log('miss previous $key drawMs=${sw.elapsedMilliseconds}');
    }
    return out;
  }

  ui.Picture? paintCurrent() {
    final b = bookOf();
    final current = curPageOf();
    if (b == null || current == null) return null;
    // Clamp for paint only — never mutate durable progress during draw.
    if (current.pages.isEmpty) return null;
    var pageIdx = b.pageIndex;
    if (pageIdx < 0) pageIdx = 0;
    if (pageIdx >= current.pageOffsets) {
      pageIdx = current.pageOffsets - 1;
    }
    final key = _key(b.id, b.chapterIndex, pageIdx);
    if (cache.containsKey(key)) return cache[key];
    final sw = kDebugMode ? (Stopwatch()..start()) : null;
    final pic = drawContent(current, pageIdx);
    final out = cache.putIfAbsent(key, () => pic);
    if (sw != null) {
      sw.stop();
      _log('miss current $key drawMs=${sw.elapsedMilliseconds}');
    }
    // Neighbors on next frame — not during the current paint stack.
    scheduleNeighborWarm();
    return out;
  }

  ui.Picture? paintNext() {
    final b = bookOf();
    final current = curPageOf();
    if (b == null || current == null) return null;
    final i = b.pageIndex + 1;
    final key = _key(b.id, b.chapterIndex, i);
    if (cache.containsKey(key)) return cache[key];

    final sw = kDebugMode ? (Stopwatch()..start()) : null;
    final ui.Picture pic;
    if (i >= current.pageOffsets) {
      final following = nextPageOf();
      if (following == null) {
        final target = b.chapterIndex + 1;
        if (_loadingNextChapter != target) {
          _loadingNextChapter = target;
          _log('miss next (loading chapter $target)');
          loadChapter(target).then((value) {
            if (_loadingNextChapter == target) _loadingNextChapter = null;
            if (activeBookId() == b.id) {
              setNextPage(value);
              // Warm as soon as the chapter body is available.
              scheduleNeighborWarm();
            }
          });
        }
        return null;
      }
      if (following.pages.isEmpty) return null;
      pic = drawContent(following, 0);
    } else {
      pic = drawContent(current, i);
    }
    final out = cache.putIfAbsent(key, () => pic);
    if (sw != null) {
      sw.stop();
      _log('miss next $key drawMs=${sw.elapsedMilliseconds}');
    }
    return out;
  }

  ui.Picture? scrollTile(
    int chapterIdx,
    int pageIdx,
    ReadPage readPage,
    ui.Picture Function(ReadPage page, int pageIndex) paintScroll,
  ) {
    final b = bookOf();
    if (b == null) return null;
    if (pageIdx < 0 || pageIdx >= readPage.pages.length) return null;
    final key = _scrollKey(b.id, chapterIdx, pageIdx);
    if (cache.containsKey(key)) return cache[key];
    final pic = paintScroll(readPage, pageIdx);
    return cache.putIfAbsent(key, () => pic);
  }
}
