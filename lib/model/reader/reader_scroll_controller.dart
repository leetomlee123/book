import 'dart:ui' as ui;

import 'package:book/common/app_log.dart';
import 'package:book/common/read_setting.dart';
import 'package:book/entity/book.dart';
import 'package:book/entity/chapter_toc_entry.dart';
import 'package:book/entity/read_page.dart';
import 'package:book/model/reader/page_picture_resolver.dart';
import 'package:book/model/reader/reader_painter.dart';
import 'package:book/view/page_turn/reader_page_manager.dart';

/// Vertical-scroll mode + page-turn animation selection for the reader.
class ReaderScrollController {
  ReaderScrollController({
    required this.bookOf,
    required this.chaptersOf,
    required this.progressReady,
    required this.scheduleProgressSave,
    required this.pictures,
    required this.painter,
    required this.syncPaperTheme,
    required this.paperThemeOf,
    required this.loadChapter,
    required this.clearPictures,
    required this.notify,
  });

  final Book? Function() bookOf;
  final List<ChapterTocEntry> Function() chaptersOf;
  final bool Function() progressReady;
  final void Function() scheduleProgressSave;
  final PagePictureResolver pictures;
  final ReaderPainter painter;
  final void Function() syncPaperTheme;
  final PaperTheme Function() paperThemeOf;
  final Future<ReadPage?> Function(int idx) loadChapter;
  final void Function() clearPictures;
  final void Function() notify;

  /// 翻页/阅读模式：0 无动画 / 1 仿真 / 2 覆盖 / 3 滚动（见 [ReaderPageManager]）
  int currentAnimationMode = () {
    final m = ReadSetting.getPageTurnMode();
    // Legacy unused slide id mapped to static none.
    if (m == 3) return ReaderPageManager.TYPE_ANIMATION_SLIDE_TURN;
    return m.clamp(0, 3);
  }();

  /// True when reader uses vertical page-stack scroll (mode 3).
  bool get isScrollMode =>
      currentAnimationMode == ReaderPageManager.TYPE_ANIMATION_SLIDE_TURN;

  /// Switch page-turn / scroll mode.
  /// 0 none / 1 simulation / 2 cover / 3 vertical scroll.
  void setAnimationMode(int mode) {
    final m = mode.clamp(0, 3);
    if (currentAnimationMode == m) return;
    currentAnimationMode = m;
    ReadSetting.setPageTurnMode(m);
    // Drop pictures so chrome / no-chrome caches do not mix.
    clearPictures();
    notify();
  }

  static String animationModeLabel(int mode) {
    switch (mode) {
      case ReaderPageManager.TYPE_ANIMATION_SIMULATION_TURN:
        return '仿真';
      case ReaderPageManager.TYPE_ANIMATION_COVER_TURN:
        return '覆盖';
      case ReaderPageManager.TYPE_ANIMATION_SLIDE_TURN:
        return '滚动';
      case ReaderPageManager.TYPE_ANIMATION_NONE:
      default:
        return '无动画';
    }
  }

  /// Update progress from scroll list visible page.
  void applyScrollProgress(int chapterIdx, int pageIdx) {
    final b = bookOf();
    if (b == null || !progressReady()) return;
    final chapters = chaptersOf();
    if (chapterIdx < 0 || chapterIdx >= chapters.length) return;
    final idx = pageIdx < 0 ? 0 : pageIdx;
    if (b.chapterIndex == chapterIdx && b.pageIndex == idx) return;
    b.chapterIndex = chapterIdx;
    b.pageIndex = idx;
    final name = chapters[chapterIdx].title;
    if (name.isNotEmpty) b.readingChapter = name;
    // Debounced disk write only — do NOT notifyListeners (scroll UI owns state).
    scheduleProgressSave();
    AppLog.i('Read', 'scroll progress cur=$chapterIdx idx=$idx name=$name');
  }

  /// Content-only picture for vertical scroll (no title/battery/page chrome).
  ui.Picture? scrollPagePicture(
    int chapterIdx,
    int pageIdx,
    ReadPage readPage,
  ) {
    return pictures.scrollTile(
      chapterIdx,
      pageIdx,
      readPage,
      drawScrollContent,
    );
  }

  /// Natural height of a scroll tile (content only + tiny pad).
  double scrollPageHeight(ReadPage readPage, int pageIdx) =>
      painter.scrollPageHeight(readPage, pageIdx);

  /// Paint body lines only into a tight-height picture for continuous scroll.
  ui.Picture drawScrollContent(ReadPage readPage, int pageIdx) {
    syncPaperTheme();
    return painter.drawScrollContent(
      readPage,
      pageIdx,
      paperTheme: paperThemeOf(),
    );
  }

  /// Load a chapter for the scroll window (skips sentinel empty pages).
  Future<ReadPage?> loadScrollChapter(int idx) async {
    final chapters = chaptersOf();
    if (idx < 0 || idx >= chapters.length) return null;
    final page = await loadChapter(idx);
    if (page == null) return null;
    if (page.chapterName == '加载中' ||
        page.chapterName == '1' ||
        page.chapterName == '-1') {
      return null;
    }
    if (page.pages.isEmpty && page.chapterContent.isEmpty) return null;
    return page;
  }
}
