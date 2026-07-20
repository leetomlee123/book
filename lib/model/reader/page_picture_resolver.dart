import 'dart:ui' as ui;

import 'package:book/entity/book.dart';
import 'package:book/entity/read_page.dart';
import 'package:book/model/reader/page_picture_cache.dart';

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

  static String _key(String bookId, int chapterIndex, int pageIndex) =>
      '$bookId|$chapterIndex|$pageIndex';

  static String _scrollKey(String bookId, int chapterIndex, int pageIndex) =>
      '$bookId|$chapterIndex|$pageIndex|sc';

  ui.Picture? resolveCurrent({bool firstInit = false}) {
    final b = bookOf();
    if (b == null) return null;
    final key = _key(b.id, b.chapterIndex, b.pageIndex);
    if (cache.containsKey(key)) return cache[key];
    final pic = paintCurrent();
    if (pic != null) {
      cache.putIfAbsent(key, () => pic);
    }
    if (firstInit) {
      Future.delayed(const Duration(milliseconds: 200), preloadNeighbors);
    }
    return pic;
  }

  void preloadNeighbors() {
    final b = bookOf();
    final current = curPageOf();
    if (b == null || current == null) return;
    if (prePageOf() != null || b.pageIndex > 0) {
      paintPrevious();
    }
    if (nextPageOf() != null || b.pageIndex + 1 < current.pageOffsets) {
      paintNext();
    }
  }

  ui.Picture? paintPrevious() {
    final b = bookOf();
    final current = curPageOf();
    if (b == null || current == null) return null;
    final i = b.pageIndex - 1;
    final key = _key(b.id, b.chapterIndex, i);
    if (cache.containsKey(key)) return cache[key];

    final ui.Picture pic;
    if (i < 0) {
      final previous = prePageOf();
      if (previous == null || previous.pages.isEmpty) return null;
      pic = drawContent(previous, previous.pageOffsets - 1);
    } else {
      pic = drawContent(current, i);
    }
    return cache.putIfAbsent(key, () => pic);
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
    Future.delayed(const Duration(milliseconds: 200), () {
      if (activeBookId() == b.id) preloadNeighbors();
    });
    final pic = drawContent(current, pageIdx);
    return cache.putIfAbsent(key, () => pic);
  }

  ui.Picture? paintNext() {
    final b = bookOf();
    final current = curPageOf();
    if (b == null || current == null) return null;
    final i = b.pageIndex + 1;
    final key = _key(b.id, b.chapterIndex, i);
    if (cache.containsKey(key)) return cache[key];

    final ui.Picture pic;
    if (i >= current.pageOffsets) {
      final following = nextPageOf();
      if (following == null) {
        loadChapter(b.chapterIndex + 1).then((value) {
          if (activeBookId() == b.id) setNextPage(value);
        });
        return null;
      }
      if (following.pages.isEmpty) return null;
      pic = drawContent(following, 0);
    } else {
      pic = drawContent(current, i);
    }
    return cache.putIfAbsent(key, () => pic);
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
