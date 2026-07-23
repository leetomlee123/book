import 'package:book/entity/book.dart';
import 'package:book/entity/chapter_toc_entry.dart';
import 'package:book/entity/read_page.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/foundation.dart';

/// Commits a logical page/chapter advance after a swipe or tap turn.
///
/// Mutates the active [Book] indices and swaps pre/cur/next [ReadPage]s via
/// the provided session callbacks.
class PageTurnCommitter {
  PageTurnCommitter({
    required this.bookOf,
    required this.chaptersOf,
    required this.curPageOf,
    required this.prePageOf,
    required this.nextPageOf,
    required this.setCurPage,
    required this.setPrePage,
    required this.setNextPage,
    required this.loadChapter,
    required this.showLoading,
    required this.hideLoading,
    required this.prunePictures,
    required this.warmPictures,
    required this.scheduleProgressSave,
    required this.notify,
    required this.markNeedsPaint,
    required this.activeBookId,
  });

  final Book? Function() bookOf;
  final List<ChapterTocEntry> Function() chaptersOf;
  final ReadPage? Function() curPageOf;
  final ReadPage? Function() prePageOf;
  final ReadPage? Function() nextPageOf;
  final void Function(ReadPage? page) setCurPage;
  final void Function(ReadPage? page) setPrePage;
  final void Function(ReadPage? page) setNextPage;
  final Future<ReadPage?> Function(int idx) loadChapter;
  final Future<void> Function(String text) showLoading;
  final void Function() hideLoading;
  final void Function() prunePictures;
  /// Warm current + schedule prev/next after page/chapter advance.
  final void Function() warmPictures;
  final void Function() scheduleProgressSave;
  final void Function() notify;
  final void Function() markNeedsPaint;
  final String? Function() activeBookId;

  void commit(Object? offsetDifference) {
    final b = bookOf();
    if (b == null) return;
    final dir = (offsetDifference is num)
        ? offsetDifference.toDouble()
        : double.tryParse(offsetDifference?.toString() ?? '') ?? 0;
    if (dir == 0) return;
    final beforeCur = b.chapterIndex;
    final beforeIdx = b.pageIndex;
    final idx = b.pageIndex;
    final chapters = chaptersOf();
    final curLen = curPageOf()?.pageOffsets ?? 0;

    // No laid-out pages yet — never treat as "last page → next chapter".
    if (curLen <= 0) {
      if (kDebugMode) {
        debugPrint(
          '[ReadModel] commitPageTurn ignored (no pages) '
          '$beforeCur:$beforeIdx dir=$dir',
        );
      }
      return;
    }

    // Clamp a stale index before deciding chapter vs in-chapter turn.
    final safeIdx = idx < 0 ? 0 : (idx >= curLen ? curLen - 1 : idx);
    if (safeIdx != idx) {
      b.pageIndex = safeIdx;
      if (kDebugMode) {
        debugPrint(
          '[ReadModel] commitPageTurn clamp index $idx → $safeIdx '
          '(pages=$curLen)',
        );
      }
    }

    if (dir > 0) {
      // Only leave the chapter from its real last page.
      if (safeIdx >= curLen - 1) {
        _turnToNextChapter(b, chapters, beforeCur, safeIdx, dir, curLen);
        return;
      }
      b.pageIndex = safeIdx + 1;
    } else {
      if (safeIdx <= 0) {
        _turnToPreviousChapter(b, beforeCur, safeIdx, dir);
        return;
      }
      b.pageIndex = safeIdx - 1;
    }
    if (kDebugMode) {
      debugPrint(
        '[ReadModel] commitPageTurn page '
        '$beforeCur:$beforeIdx → ${b.chapterIndex}:${b.pageIndex} '
        'dir=$offsetDifference pages=$curLen',
      );
    }
    // New current may already be cached from neighbor warm; schedule next ±1.
    warmPictures();
    markNeedsPaint();
    notify();
    scheduleProgressSave();
  }

  void _turnToNextChapter(
    Book b,
    List<ChapterTocEntry> chapters,
    int beforeCur,
    int beforeIdx,
    double dir,
    int curLen,
  ) {
    final tempCur = b.chapterIndex + 1;
    if (tempCur >= chapters.length) {
      BotToast.showText(text: '最后一页');
      return;
    }

    b.chapterIndex += 1;
    setPrePage(curPageOf());
    final following = nextPageOf();
    if (following == null || following.chapterName == '-1') {
      showLoading('正在加载下一章…');
      loadChapter(b.chapterIndex).then((value) {
        if (activeBookId() == b.id) {
          setCurPage(value);
          warmPictures();
          markNeedsPaint();
          notify();
        }
        hideLoading();
      });
    } else {
      setCurPage(following);
    }
    b.pageIndex = 0;
    setNextPage(null);
    if (kDebugMode) {
      debugPrint(
        '[ReadModel] commitPageTurn +chapter '
        '$beforeCur:$beforeIdx → ${b.chapterIndex}:${b.pageIndex} '
        'dir=$dir pages=$curLen',
      );
    }
    prunePictures();
    warmPictures();
    scheduleProgressSave();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (activeBookId() == b.id) {
        loadChapter(b.chapterIndex + 1).then((value) {
          if (activeBookId() == b.id) {
            setNextPage(value);
            warmPictures();
          }
        });
      }
    });
  }

  void _turnToPreviousChapter(
    Book b,
    int beforeCur,
    int beforeIdx,
    double dir,
  ) {
    final tempCur = b.chapterIndex - 1;
    if (tempCur < 0) {
      BotToast.showText(text: '第一页');
      return;
    }
    final previous = prePageOf();
    if (previous == null) {
      showLoading('正在加载上一章…');
      loadChapter(tempCur).then((value) {
        if (activeBookId() != b.id) {
          hideLoading();
          return;
        }
        setNextPage(curPageOf());
        setCurPage(value);
        b.chapterIndex = tempCur;
        b.pageIndex = (curPageOf()?.pageOffsets ?? 1) - 1;
        setPrePage(null);
        warmPictures();
        markNeedsPaint();
        notify();
        hideLoading();
        prunePictures();
        scheduleProgressSave();
        loadChapter(b.chapterIndex - 1).then((v) {
          if (activeBookId() == b.id) {
            setPrePage(v);
            warmPictures();
          }
        });
      });
      return;
    }
    setNextPage(curPageOf());
    setCurPage(previous);
    b.chapterIndex -= 1;
    b.pageIndex = (curPageOf()?.pageOffsets ?? 1) - 1;
    notify();
    setPrePage(null);
    if (kDebugMode) {
      debugPrint(
        '[ReadModel] commitPageTurn -chapter '
        '$beforeCur:$beforeIdx → ${b.chapterIndex}:${b.pageIndex} '
        'dir=$dir',
      );
    }
    prunePictures();
    warmPictures();
    scheduleProgressSave();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (activeBookId() == b.id) {
        loadChapter(b.chapterIndex - 1).then((value) {
          if (activeBookId() == b.id) {
            setPrePage(value);
            warmPictures();
          }
        });
      }
    });
  }
}
