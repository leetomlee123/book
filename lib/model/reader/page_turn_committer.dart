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
    required this.scheduleProgressSave,
    required this.notify,
    required this.markNeedsPaint,
    required this.refreshBattery,
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
  final void Function() scheduleProgressSave;
  final void Function() notify;
  final void Function() markNeedsPaint;
  final void Function() refreshBattery;
  final String? Function() activeBookId;

  void commit(Object? offsetDifference) {
    final b = bookOf();
    if (b == null) return;
    final dir = (offsetDifference is num)
        ? offsetDifference.toDouble()
        : double.tryParse(offsetDifference?.toString() ?? '') ?? 0;
    final beforeCur = b.chapterIndex;
    final beforeIdx = b.pageIndex;
    final idx = b.pageIndex;
    final chapters = chaptersOf();
    final curLen = curPageOf()?.pageOffsets ?? 0;

    if (idx == curLen - 1 && dir > 0) {
      _turnToNextChapter(b, chapters, beforeCur, beforeIdx, dir, curLen);
      return;
    }
    if (idx == 0 && dir < 0) {
      _turnToPreviousChapter(b, beforeCur, beforeIdx, dir);
      return;
    }
    if (dir > 0) {
      b.pageIndex += 1;
    } else {
      b.pageIndex -= 1;
    }
    if (kDebugMode) {
      debugPrint(
        '[ReadModel] commitPageTurn page '
        '$beforeCur:$beforeIdx → ${b.chapterIndex}:${b.pageIndex} '
        'dir=$offsetDifference pages=$curLen',
      );
    }
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
    refreshBattery();
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
    scheduleProgressSave();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (activeBookId() == b.id) {
        loadChapter(b.chapterIndex + 1).then((value) {
          if (activeBookId() == b.id) setNextPage(value);
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
    refreshBattery();
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
        markNeedsPaint();
        notify();
        hideLoading();
        prunePictures();
        scheduleProgressSave();
        loadChapter(b.chapterIndex - 1).then((v) {
          if (activeBookId() == b.id) setPrePage(v);
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
    scheduleProgressSave();
    Future.delayed(const Duration(milliseconds: 500), () {
      if (activeBookId() == b.id) {
        loadChapter(b.chapterIndex - 1).then((value) {
          if (activeBookId() == b.id) setPrePage(value);
        });
      }
    });
  }
}
