import 'package:book/common/app_log.dart';
import 'package:book/entity/book.dart';
import 'package:book/entity/chapter_toc_entry.dart';
import 'package:book/entity/read_page.dart';
import 'package:book/model/reader/reader_loading_presenter.dart';
import 'package:book/view/page_turn/novel_page_painter.dart';
import 'package:flutter/material.dart';

/// Session shell: prepare / clear / fail-open and page-index restore.
///
/// Owns no long-lived state of its own — mutates [ReadModel] session fields
/// through the injected accessors.
class ReadingSessionLifecycle {
  ReadingSessionLifecycle({
    required this.bookOf,
    required this.setBook,
    required this.setChapters,
    required this.curPageOf,
    required this.setCurPage,
    required this.setPrePage,
    required this.setNextPage,
    required this.setShowMenu,
    required this.setChaptersLoading,
    required this.setLoadingHint,
    required this.loadingHintOf,
    required this.setSessionReady,
    required this.setAllowProgressSave,
    required this.setProgressReady,
    required this.cancelProgress,
    required this.hideLoading,
    required this.clearPictures,
    required this.clearDiskWarm,
    required this.setPagePainter,
    required this.setCanvasKey,
    required this.messagePage,
    required this.notify,
  });

  final Book? Function() bookOf;
  final void Function(Book? book) setBook;
  final void Function(List<ChapterTocEntry> chapters) setChapters;
  final ReadPage? Function() curPageOf;
  final void Function(ReadPage? page) setCurPage;
  final void Function(ReadPage? page) setPrePage;
  final void Function(ReadPage? page) setNextPage;
  final void Function(bool value) setShowMenu;
  final void Function(bool value) setChaptersLoading;
  final void Function(String text) setLoadingHint;
  final String Function() loadingHintOf;
  final void Function(bool value) setSessionReady;
  final void Function(bool value) setAllowProgressSave;
  final void Function(bool value) setProgressReady;
  final void Function() cancelProgress;
  final void Function() hideLoading;
  final void Function() clearPictures;
  final void Function() clearDiskWarm;
  final void Function(NovelPagePainter? painter) setPagePainter;
  final void Function(GlobalKey? key) setCanvasKey;
  final Future<ReadPage> Function(String title, String message) messagePage;
  final void Function() notify;

  /// Sync seed when opening a book from shelf — call before first paint.
  /// Clears previous book state. Shelf re-open plants a blank paper page with
  /// the last chapter title (no "加载中/加载目录" flash); cold open keeps a
  /// short generic hint.
  void prepareOpen(Book b) {
    hideLoading();
    setShowMenu(false);
    setChaptersLoading(true);
    setAllowProgressSave(true);
    setProgressReady(false);
    cancelProgress();
    clearPictures();
    setPrePage(null);
    setNextPage(null);
    setPagePainter(null);
    setCanvasKey(null);
    setChapters([]);
    setBook(b);
    b.pageIndex = b.pageIndex < 0 ? 0 : b.pageIndex;

    // Prefer last reading chapter as chrome title so reopen looks continuous.
    final lastChapter = b.readingChapter.trim();
    final hasLastChapter =
        lastChapter.isNotEmpty && lastChapter != '加载中' && lastChapter != '目录';
    final title = hasLastChapter
        ? lastChapter
        : (b.name.isNotEmpty ? b.name : '阅读');
    // Blank body for re-open (cache typically paints within ~1 frame).
    // Cold open still gets a soft "正在加载…" until hydrate fills content.
    final hint = hasLastChapter ? '' : '正在加载…';
    setLoadingHint(hint);
    setCurPage(
      ReaderLoadingPresenter.syncPlaceholder(hint, chapterTitle: title),
    );
    setSessionReady(true);
    // Do not notify: the upcoming ReadBook build will watch the model.
  }

  /// Restore in-chapter page index after pagination.
  /// Prefer last page over page 0 when layout shrank (font/size change).
  void restorePageIndex(int savedIndex) {
    final b = bookOf();
    if (b == null) return;
    final pages = curPageOf()?.pageOffsets ?? 0;
    if (pages <= 0) {
      // Content not ready — keep saved index so we don't wipe progress.
      b.pageIndex = savedIndex < 0 ? 0 : savedIndex;
      return;
    }
    final maxIdx = pages - 1;
    if (savedIndex < 0) {
      b.pageIndex = 0;
    } else if (savedIndex > maxIdx) {
      AppLog.w(
        'Read',
        'clamp index $savedIndex -> $maxIdx (pages=$pages)',
      );
      b.pageIndex = maxIdx;
    } else {
      b.pageIndex = savedIndex;
    }
  }

  /// Surface a fatal open failure without crashing the reader route.
  Future<void> failOpen(Object error) async {
    setCurPage(await messagePage('打开失败', '阅读页初始化异常：$error'));
    // Do not zero progress or mark ready — avoid wiping DB on open failure.
    setSessionReady(true);
    setChaptersLoading(false);
    setProgressReady(false);
    notify();
  }

  /// Tear down session state. Caller must flush progress first.
  Future<void> clear() async {
    // Cancel only the timer so a late debounce cannot write after clear.
    cancelProgress();
    setProgressReady(false);
    hideLoading();
    setChapters([]);
    clearDiskWarm();
    setSessionReady(false);
    setChaptersLoading(false);
    setLoadingHint('正在加载…');
    clearPictures();
    // Keep a neutral loading page so the next open doesn't paint stale content
    // if prepareOpen races with a rebuild.
    setCurPage(ReaderLoadingPresenter.syncPlaceholder(loadingHintOf()));
    setPrePage(null);
    setNextPage(null);
    setBook(null);
    setPagePainter(null);
    setCanvasKey(null);
  }
}
