import 'package:book/common/app_log.dart';
import 'package:book/entity/book.dart';
import 'package:book/entity/read_page.dart';

/// Opens a chapter into the pre/cur/next window and paints neighbors.
class ChapterWindowController {
  ChapterWindowController({
    required this.bookOf,
    required this.chaptersLength,
    required this.loadChapter,
    required this.warmDiskCaches,
    required this.messagePage,
    required this.showLoading,
    required this.hideLoading,
    required this.setCurPage,
    required this.setPrePage,
    required this.setNextPage,
    required this.clearPictures,
    required this.warmPictures,
    required this.restorePageIndex,
    required this.markNeedsPaint,
    required this.notify,
  });

  final Book? Function() bookOf;
  final int Function() chaptersLength;
  final Future<ReadPage?> Function(int idx) loadChapter;
  final Future<void> Function(int centerIdx) warmDiskCaches;
  final Future<ReadPage> Function(String title, String message) messagePage;
  final Future<void> Function(String text) showLoading;
  final void Function() hideLoading;
  final void Function(ReadPage? page) setCurPage;
  final void Function(ReadPage? page) setPrePage;
  final void Function(ReadPage? page) setNextPage;
  final void Function() clearPictures;
  /// Record current page picture + schedule prev/next after chapter open.
  final void Function() warmPictures;
  final void Function(int savedIndex) restorePageIndex;
  final void Function() markNeedsPaint;
  final void Function() notify;

  /// Bumped on every [openAt] so stale neighbor futures cannot overwrite pages.
  int _openGeneration = 0;

  Future<void> openAt(
    int idx,
    bool jump, {
    bool showLoadingUi = true,
  }) async {
    final keepIndex = bookOf()?.pageIndex ?? 0;
    final gen = ++_openGeneration;
    final openBookId = bookOf()?.id;
    if (showLoadingUi) {
      await showLoading('正在加载…');
    }

    try {
      final b = bookOf();
      final len = chaptersLength();
      if (b != null && len > 0) {
        if (idx < 0) idx = 0;
        if (idx >= len) idx = len - 1;
        b.chapterIndex = idx;
      }

      await warmDiskCaches(idx);
      if (gen != _openGeneration || bookOf()?.id != openBookId) return;

      var cur = await loadChapter(idx);
      if (gen != _openGeneration || bookOf()?.id != openBookId) return;
      cur ??= await messagePage(
        '加载失败',
        '当前章节内容为空，请检查书源或点击菜单刷新。',
      );
      if (gen != _openGeneration || bookOf()?.id != openBookId) return;
      setCurPage(cur);
      clearPictures();

      final center = idx;
      final centerBookId = openBookId;
      loadChapter(center + 1).then((page) {
        if (gen != _openGeneration) return;
        if (bookOf()?.id != centerBookId) return;
        if (bookOf()?.chapterIndex != center) return;
        setNextPage(page);
        // Cross-chapter cover bottom layer becomes available — warm now.
        warmPictures();
      });
      loadChapter(center - 1).then((page) {
        if (gen != _openGeneration) return;
        if (bookOf()?.id != centerBookId) return;
        if (bookOf()?.chapterIndex != center) return;
        setPrePage(page);
        warmPictures();
      });

      if (jump) {
        bookOf()?.pageIndex = 0;
      } else {
        restorePageIndex(keepIndex);
      }
      // Eager current picture + post-frame neighbors (cover first gesture).
      warmPictures();
      markNeedsPaint();
      notify();
    } catch (e, st) {
      if (gen != _openGeneration) return;
      AppLog.e('Read', 'openChapterAt failed idx=$idx', error: e, stackTrace: st);
      final cur = await messagePage('加载失败', '章节加载异常：$e');
      if (gen != _openGeneration || bookOf()?.id != openBookId) return;
      setCurPage(cur);
      notify();
    } finally {
      if (showLoadingUi && gen == _openGeneration) {
        hideLoading();
      }
    }
  }
}
