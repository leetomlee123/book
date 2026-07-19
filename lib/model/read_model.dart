import 'dart:ui' as ui;

import 'package:book/common/read_setting.dart';
import 'package:book/common/app_log.dart';
import 'package:book/common/common.dart';
import 'package:book/data/repositories/book_repository.dart';
import 'package:book/data/repositories/chapter_repository.dart';
import 'package:book/entity/book.dart';
import 'package:book/entity/chapter_toc_entry.dart';
import 'package:book/entity/read_page.dart';
import 'package:book/model/reader/chapter_content_loader.dart';
import 'package:book/model/reader/chapter_disk_warm_cache.dart';
import 'package:book/model/reader/chapter_download_service.dart';
import 'package:book/model/reader/chapter_window_controller.dart';
import 'package:book/model/reader/reader_content_reloader.dart';
import 'package:book/model/reader/page_picture_cache.dart';
import 'package:book/model/reader/page_picture_resolver.dart';
import 'package:book/model/reader/page_turn_committer.dart';
import 'package:book/model/reader/reading_progress_store.dart';
import 'package:book/model/reader/reading_session_lifecycle.dart';
import 'package:book/model/reader/reading_session_opener.dart';
import 'package:book/model/reader/source_switch_service.dart';
import 'package:book/model/reader/toc_service.dart';
import 'package:book/model/reader/reader_chrome_controller.dart';
import 'package:book/model/reader/reader_input_controller.dart';
import 'package:book/model/reader/reader_loading_presenter.dart';
import 'package:book/model/reader/reader_painter.dart';
import 'package:book/model/reader/reader_scroll_controller.dart';
import 'package:book/model/reader/reader_source_coordinator.dart';
import 'package:book/model/reader/reader_theme_controller.dart';
import 'package:book/model/reader/text_paginator.dart';
import 'package:book/source/engine/book_source_engine.dart';
import 'package:book/source/model/book_source.dart';
import 'package:book/source/model/search_book.dart';
import 'package:book/view/page_turn/novel_page_painter.dart';
import 'package:book/common/local_store.dart';
import 'package:flutter/material.dart';

class ReadModel with ChangeNotifier {
  NovelPagePainter? pagePainter;
  final PagePictureCache pictureCache = PagePictureCache();
  late final PagePictureResolver _pictures = PagePictureResolver(
    cache: pictureCache,
    drawContent: (page, i) => drawContent(page, i),
    loadChapter: loadChapter,
    bookOf: () => book,
    curPageOf: () => curPage,
    prePageOf: () => prePage,
    nextPageOf: () => nextPage,
    setNextPage: (page) => nextPage = page,
    activeBookId: () => book?.id,
  );
  late final PageTurnCommitter _pageTurn = PageTurnCommitter(
    bookOf: () => book,
    chaptersOf: () => chapters,
    curPageOf: () => curPage,
    prePageOf: () => prePage,
    nextPageOf: () => nextPage,
    setCurPage: (page) => curPage = page,
    setPrePage: (page) => prePage = page,
    setNextPage: (page) => nextPage = page,
    loadChapter: loadChapter,
    showLoading: _showTextLoading,
    hideLoading: _hideTextLoading,
    prunePictures: _prunePictureCache,
    scheduleProgressSave: () => scheduleProgressSave(),
    notify: notifyListeners,
    markNeedsPaint: _markNeedsPaint,
    activeBookId: () => book?.id,
  );
  GlobalKey? canvasKey;
  final ReaderPainter _painter = ReaderPainter();

  ui.Image? get bgUI => _painter.bgUI;
  set bgUI(ui.Image? value) => _painter.bgUI = value;

  /// 翻页/阅读模式：0 无动画 / 1 仿真 / 2 覆盖 / 3 滚动
  int get currentAnimationMode => _scroll.currentAnimationMode;
  set currentAnimationMode(int value) => _scroll.currentAnimationMode = value;

  Book? book;
  List<ChapterTocEntry> chapters = [];
  final BookRepository _books = BookRepository.instance;
  final ChapterRepository _chapters = ChapterRepository.instance;
  final BookSourceEngine _engine = BookSourceEngine();
  final TextPaginator _paginator = const TextPaginator();
  late final ChapterContentLoader _contentLoader = ChapterContentLoader(
    chaptersRepo: _chapters,
    paginator: _paginator,
    fetchContent: fetchChapterBody,
  );
  late final ChapterDiskWarmCache _diskWarm = ChapterDiskWarmCache(
    chapters: _chapters,
    paginator: _paginator,
  );
  late final ChapterDownloadService _downloads = ChapterDownloadService(
    engine: _engine,
    chapters: _chapters,
  );
  late final SourceSwitchService _sourceSwitch = SourceSwitchService(
    engine: _engine,
    books: _books,
    chapters: _chapters,
    ensureBookRow: _ensureBookRow,
  );
  late final ReaderSourceCoordinator _source = ReaderSourceCoordinator(
    downloads: _downloads,
    sourceSwitch: _sourceSwitch,
    bookOf: () => book,
    chaptersOf: () => chapters,
    setChapters: (c) => chapters = c,
    clearDiskWarm: _diskWarm.clear,
    resetPages: resetPages,
    clearPictures: pictureCache.clear,
    openChapterAt: (idx, jump, {bool showLoading = true}) =>
        openChapterAt(idx, jump, showLoading: showLoading),
    showLoading: _showTextLoading,
    hideLoading: _hideTextLoading,
    loadToc: ({bool init = false}) => loadToc(init: init),
    notify: notifyListeners,
  );
  late final ReaderContentReloader _reloader = ReaderContentReloader(
    chaptersRepo: _chapters,
    bookOf: () => book,
    chaptersOf: () => chapters,
    setChaptersLoading: (v) => chaptersLoading = v,
    setLoadingHint: (v) => loadingHint = v,
    loadToc: ({bool init = false}) => loadToc(init: init),
    fetchChapterBody: (id, {int? idx}) => fetchChapterBody(id, idx: idx),
    loadChapter: loadChapter,
    setCurPage: (page) => curPage = page,
    removeWarm: _diskWarm.remove,
    clearPictures: pictureCache.clear,
    openChapterAt: (idx, jump, {bool showLoading = true}) =>
        openChapterAt(idx, jump, showLoading: showLoading),
    restorePageIndex: (idx) => _lifecycle.restorePageIndex(idx),
    toggleMenu: toggleShowMenu,
    showLoading: _showTextLoading,
    hideLoading: _hideTextLoading,
    markNeedsPaint: _markNeedsPaint,
    notify: notifyListeners,
  );
  late final ChapterWindowController _window = ChapterWindowController(
    bookOf: () => book,
    chaptersLength: () => chapters.length,
    loadChapter: loadChapter,
    warmDiskCaches: (idx) => _diskWarm.warmAround(chapters, idx),
    messagePage: _messagePage,
    showLoading: _showTextLoading,
    hideLoading: _hideTextLoading,
    setCurPage: (page) => curPage = page,
    setPrePage: (page) => prePage = page,
    setNextPage: (page) => nextPage = page,
    clearPictures: pictureCache.clear,
    restorePageIndex: (idx) => _lifecycle.restorePageIndex(idx),
    markNeedsPaint: _markNeedsPaint,
    notify: notifyListeners,
  );
  late final ReaderInputController _input = ReaderInputController(
    isBusy: () => pagePainter?.pageManager?.isBusy == true,
    tapLeftToAdvanceOf: () => tapLeftToAdvance,
    toggleMenu: toggleShowMenu,
    hasPageManager: () => pagePainter?.pageManager != null,
    triggerTapTurn: (dir) {
      final mgr = pagePainter?.pageManager;
      if (mgr == null) return false;
      return mgr.triggerTapTurn(dir);
    },
    commitPageTurn: (dir) => commitPageTurn(dir),
    markNeedsPaint: _markNeedsPaint,
    notify: notifyListeners,
    bookOf: () => book,
    chaptersLength: () => chapters.length,
    curPageOf: () => curPage,
    hasNextPicture: () => paintNextPicture() != null,
    hasPreviousPicture: () => paintPreviousPicture() != null,
  );
  late final ReaderChromeController _chrome = ReaderChromeController(
    notify: notifyListeners,
  );
  late final ReaderLoadingPresenter _loading = ReaderLoadingPresenter(
    paginator: _paginator,
    setLoadingHint: (text) => loadingHint = text,
    setCurPage: (page) => curPage = page,
    clearPictures: pictureCache.clear,
    markNeedsPaint: _markNeedsPaint,
    notify: notifyListeners,
  );
  late final ReaderThemeController _theme = ReaderThemeController(
    setBgUI: (image) => bgUI = image,
    clearPictures: pictureCache.clear,
    markNeedsPaint: _markNeedsPaint,
    notify: notifyListeners,
  );
  late final ReaderScrollController _scroll = ReaderScrollController(
    bookOf: () => book,
    chaptersOf: () => chapters,
    progressReady: () => _progress.ready,
    scheduleProgressSave: () => scheduleProgressSave(),
    pictures: _pictures,
    painter: _painter,
    syncPaperTheme: _theme.syncPaperTheme,
    paperThemeOf: () => paperTheme,
    loadChapter: loadChapter,
    clearPictures: pictureCache.clear,
    notify: notifyListeners,
  );

  bool isDark() => SpUtil.getBool(PrefsKeys.dark);

  //本书记录
  ReadPage? prePage;
  ReadPage? curPage;
  ReadPage? nextPage;

  //缓存批量提交大小
  late final ReadingProgressStore _progress = ReadingProgressStore(
    books: _books,
    chapters: _chapters,
    ensureBookRow: _ensureBookRow,
  );
  late final ReadingSessionLifecycle _lifecycle = ReadingSessionLifecycle(
    bookOf: () => book,
    setBook: (b) => book = b,
    setChapters: (c) => chapters = c,
    curPageOf: () => curPage,
    setCurPage: (page) => curPage = page,
    setPrePage: (page) => prePage = page,
    setNextPage: (page) => nextPage = page,
    setShowMenu: (v) => showMenu = v,
    setChaptersLoading: (v) => chaptersLoading = v,
    setLoadingHint: (v) => loadingHint = v,
    loadingHintOf: () => loadingHint,
    setSessionReady: (v) => sessionReady = v,
    setAllowProgressSave: (v) => allowProgressSave = v,
    setProgressReady: (v) => _progress.ready = v,
    cancelProgress: _progress.cancel,
    hideLoading: _hideTextLoading,
    clearPictures: pictureCache.clear,
    clearDiskWarm: _diskWarm.clear,
    setPagePainter: (p) => pagePainter = p,
    setCanvasKey: (k) => canvasKey = k,
    messagePage: _messagePage,
    notify: notifyListeners,
  );
  late final TocService _toc = TocService(
    engine: _engine,
    chapters: _chapters,
    ensureBookRow: _ensureBookRow,
    resolveSource: (b) async {
      book = b;
      await _source.ensureSource();
      return _source.activeSource;
    },
  );
  late final ReadingSessionOpener _sessionOpener = ReadingSessionOpener(
    books: _books,
    chapters: _chapters,
    ensureSource: _source.ensureSource,
    activeSourceOf: () => _source.activeSource,
    loadToc: ({bool init = false}) => loadToc(init: init),
    openChapterAt: (idx, jump, {bool showLoading = true}) =>
        openChapterAt(idx, jump, showLoading: showLoading),
    hasPageCache: (idx) => _diskWarm.hasPageCache(chapters, idx),
    restorePageIndex: (idx) => _lifecycle.restorePageIndex(idx),
    messagePage: _messagePage,
    showLoading: _showTextLoading,
    bookOf: () => book,
    setBook: (b) => book = b,
    chaptersOf: () => chapters,
    setChapters: (c) => chapters = c,
    curPageOf: () => curPage,
    setCurPage: (page) => curPage = page,
    setShowMenu: (v) => showMenu = v,
    setChaptersLoading: (v) => chaptersLoading = v,
    setLoadingHint: (v) => loadingHint = v,
    loadingHintOf: () => loadingHint,
    setAllowProgressSave: (v) => allowProgressSave = v,
    setSessionReady: (v) => sessionReady = v,
    setProgressReady: (v) => _progress.ready = v,
    notify: notifyListeners,
  );

  //显示上层 设置
  bool get showMenu => _chrome.showMenu;
  set showMenu(bool value) => _chrome.showMenu = value;

  //背景色索引（legacy texture path; solid paper preferred）
  String get backgroundImageName => _theme.backgroundImageName;
  set backgroundImageName(String value) => _theme.backgroundImageName = value;

  PaperTheme get paperTheme => _theme.paperTheme;
  set paperTheme(PaperTheme value) => _theme.paperTheme = value;

//章节翻页标志
  bool sessionReady = false;

  /// True while TOC is being fetched (open book / 重新加载目录).
  /// UI should show text hint, not a spinner.
  bool chaptersLoading = false;

  /// Status text while [sessionReady] is false or chapters are refreshing.
  String loadingHint = '正在加载目录…';

  //点击上下页方式
  bool get tapLeftToAdvance => _chrome.tapLeftToAdvance;
  set tapLeftToAdvance(bool value) => _chrome.tapLeftToAdvance = value;

  //页面上下文

/// When false, progress persistence is disabled (e.g. user declined shelf add).
  bool get allowProgressSave => _progress.enabled;
  set allowProgressSave(bool v) => _progress.enabled = v;

  /// Sync seed when opening a book from shelf — call before first paint.
  void prepareOpen(Book b) => _lifecycle.prepareOpen(b);

  //获取本书记录
  Future<void> hydrateReadingSession() => _sessionOpener.hydrate();

  /// Surface a fatal open failure without crashing the reader route.
  Future<void> failOpen(Object error) => _lifecycle.failOpen(error);

  Future<ReadPage> _messagePage(String title, String message) =>
      _loading.messagePage(title, message);

  Future<void> _showTextLoading(String text) => _loading.show(text);

  void _hideTextLoading() => _loading.hide();

  Future openChapterAt(int idx, bool jump, {bool showLoading = true}) {
    return _window.openAt(idx, jump, showLoadingUi: showLoading);
  }

  Future<void> refreshThemePaint() => _theme.refreshPaint();

  Future<void> setBackgroundImage(Object? i) => _theme.setBackgroundImage(i);

  /// WeChat-style solid paper swatch.
  Future<void> setPaperTheme(PaperTheme theme) => _theme.setPaperTheme(theme);

  Future<List<ChapterTocEntry>?> fetchRemoteToc() async {
    final b = book;
    if (b == null) return null;
    return _toc.fetchRemote(b);
  }

  Future loadToc({bool init = false}) async {
    final b = book;
    if (b == null) return;
    final bookId = b.id;
    final updated = await _toc.load(
      book: b,
      current: chapters,
      init: init,
      isStillActive: () => book?.id == bookId,
    );
    if (updated == null) return;
    // Drop result if session switched books during the await.
    if (book?.id != bookId) return;
    chapters = updated;
    if (updated.isNotEmpty) {
      book?.latestChapter = updated.last.title;
    }
    notifyListeners();
  }

  Future<void> _ensureBookRow(Book b) async {
    try {
      await _books.ensureExists(b);
    } catch (e) {
      // UNIQUE race is benign (ConflictAlgorithm.ignore should swallow it).
      AppLog.w('Read', 'ensure book row failed', error: e);
    }
  }

  Future<ReadPage?> loadChapter(int idx) async {
    return _contentLoader.load(
      chapters: chapters,
      idx: idx,
      warm: _diskWarm.map,
      bookId: book?.id,
      bookChapterIndex: book?.chapterIndex ?? idx,
      messagePage: _messagePage,
    );
  }

  Future<void> relayoutPages() => _reloader.relayoutPages();

  void _markNeedsPaint() {
    canvasKey?.currentContext?.findRenderObject()?.markNeedsPaint();
  }

  /*菜单控制 */
  void toggleShowMenu() => _chrome.toggleShowMenu();

  /// Debounced progress save after page turns.
  void scheduleProgressSave({Duration delay = ReadingProgressStore.debounce}) =>
      _progress.schedule(book: book, chapters: chapters, delay: delay);

  /// Flush any pending debounced save immediately (call on exit / background).
  Future<void> flushProgressSave() =>
      _progress.flush(book: book, chapters: chapters);

  /*状态保存 */
  Future<void> saveData() => _progress.save(book: book, chapters: chapters);

  /*页面点击事件（兼容旧入口） */
  void tapPage(BuildContext context, TapUpDetails details) {
    tapPageAt(details.localPosition, MediaQuery.of(context).size);
  }

  /// Zone tap using local coordinates of the reader canvas.
  /// Returns `true` if a page-turn was started (not for menu-only).
  bool tapPageAt(Offset localPos, Size size) => _input.tapAt(localPos, size);

  /// Returns true if a turn was started.
  bool turnByDirection(int f, Offset detail) => _input.turnByDirection(f);

  /// True when reader uses vertical page-stack scroll (mode 3).
  bool get isScrollMode => _scroll.isScrollMode;

  /// True after [hydrateReadingSession] finished hydrating and current chapter is ready.
  /// Scroll surface must wait for this — [sessionReady] alone is true during prepareOpen.
  bool get contentReady =>
      _progress.ready &&
      book != null &&
      chapters.isNotEmpty &&
      curPage != null &&
      curPage!.pages.isNotEmpty &&
      curPage!.chapterName != '加载中';

  /// Switch page-turn / scroll mode.
  /// 0 none / 1 simulation / 2 cover / 3 vertical scroll.
  void setAnimationMode(int mode) => _scroll.setAnimationMode(mode);

  static String animationModeLabel(int mode) =>
      ReaderScrollController.animationModeLabel(mode);

  /// Update progress from scroll list visible page.
  void applyScrollProgress(int chapterIdx, int pageIdx) =>
      _scroll.applyScrollProgress(chapterIdx, pageIdx);

  /// Registered by [ScrollContentReader] so lifecycle/exit can force-sync the
  /// currently visible page into [book] before flushing progress to disk.
  VoidCallback? scrollProgressSync;

  /// Pull latest visible scroll page into model indices (no-op off scroll mode).
  void syncScrollProgress() {
    final sync = scrollProgressSync;
    if (sync != null) {
      sync();
      return;
    }
  }

  /// Content-only picture for vertical scroll (no title/time/page chrome).
  ui.Picture? scrollPagePicture(
          int chapterIdx, int pageIdx, ReadPage readPage) =>
      _scroll.scrollPagePicture(chapterIdx, pageIdx, readPage);

  /// Natural height of a scroll tile (content only + tiny pad).
  double scrollPageHeight(ReadPage readPage, int pageIdx) =>
      _scroll.scrollPageHeight(readPage, pageIdx);

  /// Paint body lines only into a tight-height picture for continuous scroll.
  ui.Picture drawScrollContent(ReadPage readPage, int pageIdx) =>
      _scroll.drawScrollContent(readPage, pageIdx);

  /// Load a chapter for the scroll window (skips sentinel empty pages).
  Future<ReadPage?> loadScrollChapter(int idx) =>
      _scroll.loadScrollChapter(idx);

  ui.Picture? resolveCurrentPicture({bool firstInit = false}) =>
      _pictures.resolveCurrent(firstInit: firstInit);

  void preloadNeighborPictures() => _pictures.preloadNeighbors();

  ui.Picture? paintPreviousPicture() => _pictures.paintPrevious();

  ui.Picture? paintCurrentPicture() => _pictures.paintCurrent();

  ui.Picture? paintNextPicture() => _pictures.paintNext();

  Future<ui.Image> loadAssetImage(String asset, {int? width, int? height}) =>
      _theme.loadAssetImage(asset, width: width, height: height);

  /// Paint one page picture.
  ///
  /// [chrome]: when true (page-turn), bake chapter title + time/page.
  /// When false (vertical scroll), body only — chrome is a sticky overlay.
  ui.Picture drawContent(ReadPage readPage, int i, {bool chrome = true}) {
    _theme.syncPaperTheme();
    return _painter.drawContent(
      readPage,
      i,
      chrome: chrome,
      paperTheme: paperTheme,
    );
  }

  /// Caller must flush progress first (ReadBook.dispose / lifecycle).
  Future<void> clear() {
    scrollProgressSync = null;
    return _lifecycle.clear();
  }

  Future<void> reloadChapters() => _reloader.reloadChapters();

  Future<void> reloadCurrentPage() => _reloader.reloadCurrentPage();

  void resetPages() {
    prePage = null;
    curPage = null;
    nextPage = null;
  }

  Future<void> downloadAll(int start) => _source.downloadAll(start);

  Future<String> fetchChapterBody(String id, {int? idx}) =>
      _source.fetchChapterBody(id, idx: idx);

  /// Switch active source for the current book, remap progress, reload toc.
  Future<bool> switchSource(BookSource source, SearchBook hit) =>
      _source.switchSource(source, hit);

  void toggleTapLeftToAdvance() => _chrome.toggleTapLeftToAdvance();

  void commitPageTurn(Object? offsetDifference) {
    _pageTurn.commit(offsetDifference);
  }

  /// Drop in-memory pictures outside the nearby chapter window / hard cap.
  void _prunePictureCache() {
    final b = book;
    if (b == null) return;
    pictureCache.prune(bookId: b.id, centerChapter: b.chapterIndex);
  }

  /// Scroll-mode window moved — prune pictures around [centerChapter].
  void pruneScrollPictures({int? centerChapter}) {
    final b = book;
    if (b == null) return;
    pictureCache.prune(
      bookId: b.id,
      centerChapter: centerChapter ?? b.chapterIndex,
    );
  }

  bool canTurnNext() => _input.canTurnNext();

  bool canTurnPrevious() => _input.canTurnPrevious();

  Future<void> reloadBackgroundImage() => _theme.reloadBackgroundImage();
}
