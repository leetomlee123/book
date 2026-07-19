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
  final void Function(int savedIndex) restorePageIndex;
  final void Function() markNeedsPaint;
  final void Function() notify;

  Future<void> openAt(
    int idx,
    bool jump, {
    bool showLoadingUi = true,
  }) async {
    final keepIndex = bookOf()?.pageIndex ?? 0;
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

      var cur = await loadChapter(idx);
      cur ??= await messagePage(
        '加载失败',
        '当前章节内容为空，请检查书源或点击菜单刷新。',
      );
      setCurPage(cur);
      clearPictures();

      loadChapter(idx + 1).then(setNextPage);
      loadChapter(idx - 1).then(setPrePage);

      if (jump) {
        bookOf()?.pageIndex = 0;
      } else {
        restorePageIndex(keepIndex);
      }
      markNeedsPaint();
      notify();
    } catch (e, st) {
      AppLog.e('Read', 'openChapterAt failed idx=$idx', error: e, stackTrace: st);
      final cur = await messagePage('加载失败', '章节加载异常：$e');
      setCurPage(cur);
      notify();
    } finally {
      if (showLoadingUi) {
        hideLoading();
      }
    }
  }
}
