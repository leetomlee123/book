import 'dart:async';
import 'dart:ui' as ui;

import 'package:battery_plus/battery_plus.dart';
import 'package:book/common/read_setting.dart';
import 'package:book/common/screen.dart';
import 'package:book/common/app_log.dart';
import 'package:book/common/common.dart';
import 'package:book/data/repositories/book_repository.dart';
import 'package:book/data/repositories/chapter_repository.dart';
import 'package:book/entity/book.dart';
import 'package:book/entity/chapter_node.dart';
import 'package:book/entity/chapter_toc_entry.dart';
import 'package:book/entity/read_page.dart';
import 'package:book/entity/text_line.dart';
import 'package:book/entity/text_page.dart';
import 'package:book/model/source_model.dart';
import 'package:book/model/reader/chapter_content_loader.dart';
import 'package:book/model/reader/chapter_download_service.dart';
import 'package:book/model/reader/chapter_window_controller.dart';
import 'package:book/model/reader/page_picture_cache.dart';
import 'package:book/model/reader/page_picture_resolver.dart';
import 'package:book/model/reader/page_turn_committer.dart';
import 'package:book/model/reader/reading_progress_store.dart';
import 'package:book/model/reader/reading_session_opener.dart';
import 'package:book/model/reader/source_switch_service.dart';
import 'package:book/model/reader/toc_service.dart';
import 'package:book/model/reader/reader_painter.dart';
import 'package:book/model/reader/text_paginator.dart';
import 'package:book/source/engine/book_source_engine.dart';
import 'package:book/source/model/book_source.dart';
import 'package:book/source/model/search_book.dart';
import 'package:book/view/page_turn/novel_page_painter.dart';
import 'package:book/view/page_turn/reader_page_manager.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:book/common/local_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
    markNeedsPaint: () {
      canvasKey?.currentContext?.findRenderObject()?.markNeedsPaint();
    },
    refreshBattery: _refreshBattery,
    activeBookId: () => book?.id,
  );
  GlobalKey? canvasKey;
  final ReaderPainter _painter = ReaderPainter();

  ui.Image? get bgUI => _painter.bgUI;
  set bgUI(ui.Image? value) => _painter.bgUI = value;

  /// 翻页/阅读模式：0 无动画 / 1 仿真 / 2 覆盖 / 3 滚动（见 [ReaderPageManager]）
  int currentAnimationMode = () {
    final m = ReadSetting.getPageTurnMode();
    // Legacy unused slide id mapped to static none.
    if (m == 3) return ReaderPageManager.TYPE_ANIMATION_SLIDE_TURN;
    return m.clamp(0, 3);
  }();

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
  late final ChapterDownloadService _downloads = ChapterDownloadService(
    engine: _engine,
    chapters: _chapters,
  );
  late final ChapterWindowController _window = ChapterWindowController(
    bookOf: () => book,
    chaptersLength: () => chapters.length,
    loadChapter: loadChapter,
    warmDiskCaches: _warmDiskChapterCaches,
    messagePage: _messagePage,
    showLoading: _showTextLoading,
    hideLoading: _hideTextLoading,
    setCurPage: (page) => curPage = page,
    setPrePage: (page) => prePage = page,
    setNextPage: (page) => nextPage = page,
    clearPictures: pictureCache.clear,
    restorePageIndex: _restorePageIndex,
    markNeedsPaint: () {
      canvasKey?.currentContext?.findRenderObject()?.markNeedsPaint();
    },
    notify: notifyListeners,
  );
  BookSource? _activeSource;

  /// In-memory warm cache of disk chapter body + page layout (cur±1).
  final Map<String, ({String body, String? pagesJson, String? layoutFp})>
      _diskChapterWarm = {};

  bool isDark() => SpUtil.getBool(PrefsKeys.dark);

  double get electricQuantity => _painter.electricQuantity;
  set electricQuantity(double value) => _painter.electricQuantity = value;

  //本书记录
  ReadPage? prePage;
  ReadPage? curPage;
  ReadPage? nextPage;

  //缓存批量提交大小
  int downloadBatchSize = 100;

  late final ReadingProgressStore _progress = ReadingProgressStore(
    books: _books,
    chapters: _chapters,
    ensureBookRow: _ensureBookRow,
  );
  late final SourceSwitchService _sourceSwitch = SourceSwitchService(
    engine: _engine,
    books: _books,
    chapters: _chapters,
    ensureBookRow: _ensureBookRow,
  );
  late final TocService _toc = TocService(
    engine: _engine,
    chapters: _chapters,
    ensureBookRow: _ensureBookRow,
    resolveSource: (b) async {
      book = b;
      await _ensureSource();
      return _activeSource;
    },
  );
  late final ReadingSessionOpener _sessionOpener = ReadingSessionOpener(
    books: _books,
    chapters: _chapters,
    ensureSource: _ensureSource,
    activeSourceOf: () => _activeSource,
    loadToc: ({bool init = false}) => loadToc(init: init),
    openChapterAt: (idx, jump, {bool showLoading = true}) =>
        openChapterAt(idx, jump, showLoading: showLoading),
    hasPageCache: _hasPageCache,
    restorePageIndex: _restorePageIndex,
    messagePage: _messagePage,
    showLoading: _showTextLoading,
    bookOf: () => book,
    setBook: (b) => book = b,
    chaptersOf: () => chapters,
    setChapters: (c) => chapters = c,
    curPageOf: () => curPage,
    setCurPage: (page) => curPage = page,
    setElectricQuantity: (v) => electricQuantity = v,
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
  bool showMenu = false;

  //背景色索引（legacy texture path; solid paper preferred）
  String backgroundImageName =
      SpUtil.getString(PrefsKeys.bgIdx, defValue: ReadSetting.bgImg.first);

  PaperTheme paperTheme = ReadSetting.getPaperTheme();

//章节翻页标志
  bool sessionReady = false;

  /// True while TOC is being fetched (open book / 重新加载目录).
  /// UI should show text hint, not a spinner.
  bool chaptersLoading = false;

  /// Status text while [sessionReady] is false or chapters are refreshing.
  String loadingHint = '正在加载目录…';

  //点击上下页方式
  bool tapLeftToAdvance = SpUtil.getBool(PrefsKeys.leftClickNext, defValue: false);

  //页面上下文

/// When false, progress persistence is disabled (e.g. user declined shelf add).
  bool get allowProgressSave => _progress.enabled;
  set allowProgressSave(bool v) => _progress.enabled = v;

  /// Sync seed when opening a book from shelf — call before first paint.
  /// Clears previous book state and plants a centered loading page so the
  /// transition does not flash the last book or a blank scaffold.
  void prepareOpen(Book b) {
    _hideTextLoading();
    showMenu = false;
    chaptersLoading = true;
    loadingHint = '正在加载…';
    allowProgressSave = true;
    _progress.ready = false;
    _progress.cancel();
    pictureCache.clear();
    prePage = null;
    nextPage = null;
    pagePainter = null;
    canvasKey = null;
    chapters = [];
    book = b;
    // Lightweight sync placeholder (no paginator / isolate).
    final page = ReadPage.kong();
    page.chapterName = '加载中';
    page.chapterContent = loadingHint;
    page.pages = [
      TextPage([TextLine(loadingHint, 0, 0, 0)], 24),
    ];
    curPage = page;
    b.pageIndex = b.pageIndex < 0 ? 0 : b.pageIndex;
    sessionReady = true;
    // Do not notifyListeners here: the upcoming ReadBook build will watch us.
  }

  //获取本书记录
  Future<void> hydrateReadingSession() => _sessionOpener.hydrate();

    /// Restore in-chapter page index after pagination.
  /// Prefer last page over page 0 when layout shrank (font/size change).
  void _restorePageIndex(int savedIndex) {
    final b = book;
    if (b == null) return;
    final pages = curPage?.pageOffsets ?? 0;
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
    curPage = await _messagePage('打开失败', '阅读页初始化异常：$error');
    // Do not zero progress or mark ready — avoid wiping DB on open failure.
    sessionReady = true;
    chaptersLoading = false;
    _progress.ready = false;
    notifyListeners();
  }

  /// Build a single-page ReadPage with a readable error/hint message.
  Future<ReadPage> _messagePage(String title, String message) async {
    final page = ReadPage.kong();
    page.chapterName = title;
    page.chapterContent = message;
    try {
      page.pages = await _paginator.paginate(page);
    } catch (_) {
      page.pages = const [];
    }
    if (page.pages.isEmpty) {
      // Absolute fallback so drawContent never paints a blank canvas.
      page.pages = [
        TextPage([
          TextLine(message, 16, 0, 0),
        ], 24),
      ];
    }
    return page;
  }

  Future<void> _ensureSource() async {
    final b = book;
    if (b == null) return;
    if (_activeSource != null &&
        _activeSource!.bookSourceUrl == b.sourceUrl) {
      return;
    }
    _activeSource = await SourceModel().findByUrl(b.sourceUrl);
  }

  /// In-page loading (drawn as a normal ReadPage). No BotToast overlay.
  int _loadingToken = 0;

  Future<void> _showTextLoading(String text) async {
    loadingHint = text;
    final token = ++_loadingToken;
    final page = await _messagePage('加载中', text);
    if (token != _loadingToken) return; // superseded
    curPage = page;
    // Do NOT touch book.index — loading is a 1-page placeholder only.
    // Mutating index here used to wipe restored progress (DB idx → 0).
    pictureCache.clear();
    final ro = canvasKey?.currentContext?.findRenderObject();
    ro?.markNeedsPaint();
    notifyListeners();
  }

  void _hideTextLoading() {
    // Content replacement (openChapterAt / chapter load) clears the hint page.
    // Bump token so any in-flight _showTextLoading paint is ignored.
    _loadingToken++;
  }

  Future openChapterAt(int idx, bool jump, {bool showLoading = true}) {
    return _window.openAt(idx, jump, showLoadingUi: showLoading);
  }

    Future<void> refreshThemePaint() async {
    await reloadBackgroundImage();
    pictureCache.clear();

    final ro = canvasKey?.currentContext?.findRenderObject();
    if (ro != null) {
      ro.markNeedsPaint();
    }
  }

  Future<void> setBackgroundImage(Object? i) async {
    // Legacy texture path.
    final path = i?.toString() ?? backgroundImageName;
    backgroundImageName = path;
    SpUtil.putString(PrefsKeys.bgIdx, path);
    ReadSetting.setUseSolidPaper(false);
    await refreshThemePaint();
    notifyListeners();
  }

  /// WeChat-style solid paper swatch.
  Future<void> setPaperTheme(PaperTheme theme) async {
    paperTheme = theme;
    ReadSetting.setPaperTheme(theme);
    ReadSetting.setUseSolidPaper(true);
    pictureCache.clear();
    bgUI = null; // solid fill only
    await refreshThemePaint();
    notifyListeners();
  }

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
    chapters = updated;
    if (updated.isNotEmpty) {
      book?.latestChapter = updated.last.title;
    }
    notifyListeners();
  }

  Future<void> _warmDiskChapterCaches(int centerIdx) async {
    if (chapters.isEmpty) return;
    final ids = <String>[];
    for (final i in [centerIdx - 1, centerIdx, centerIdx + 1]) {
      if (i < 0 || i >= chapters.length) continue;
      final id = chapters[i].id;
      if (id.isNotEmpty) ids.add(id);
    }
    if (ids.isEmpty) return;
    try {
      final map = await _chapters.getChapterCaches(ids);
      _diskChapterWarm
        ..clear()
        ..addAll(map);
    } catch (e) {
      AppLog.w('Read', 'warm disk chapter cache failed', error: e);
    }
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
      warm: _diskChapterWarm,
      bookId: book?.id,
      bookChapterIndex: book?.chapterIndex ?? idx,
      messagePage: _messagePage,
    );
  }

  /// True when chapter body + fingerprinted page layout are both on disk.
  Future<bool> _hasPageCache(int idx) async {
    if (idx < 0 || idx >= chapters.length) return false;
    final chapterId = chapters[idx].id;
    try {
      final disk = await _chapters.getChapterCache(chapterId);
      if (disk.body.isEmpty) return false;
      final layout = _paginator.layoutParams();
      final fp = _paginator.layoutFingerprint(
        layoutParams: layout,
        contentLen: disk.body.length,
        contentSig: _paginator.contentSignature(disk.body),
      );
      return disk.pagesJson != null &&
          disk.pagesJson!.isNotEmpty &&
          disk.layoutFp == fp;
    } catch (_) {
      return false;
    }
  }

  Future<void> relayoutPages() async {
    pictureCache.clear();
    // Drop fingerprinted page layouts that no longer match current metrics.
    try {
      final layout = _paginator.layoutParams();
      // contentLen/sig don't matter for bulk stale clear — wipe all non-matching.
      final keepFp = _paginator.layoutFingerprint(
        layoutParams: layout,
        contentLen: 0,
        contentSig: '',
      );
      // Clear everything: font metrics changed so no old fp is valid.
      await _chapters.clearAllPageLayouts();
      AppLog.i('Read', 'cleared page cache on layout change keepHint=$keepFp');
    } catch (e) {
      AppLog.w('Read', 'clearAllPageLayouts failed', error: e);
    }
    // 保留当前章；重分页后尽量夹紧页码，不强制回第 0 页。
    final b = book;
    final keepIndex = b?.pageIndex ?? 0;
    await openChapterAt(b?.chapterIndex ?? 0, false, showLoading: false);
    if (b != null) {
      _restorePageIndex(keepIndex);
    }
    final ro = canvasKey?.currentContext?.findRenderObject();
    if (ro != null) {
      ro.markNeedsPaint();
    }
    notifyListeners();
  }

  /*菜单控制 */
  void toggleShowMenu() {
    showMenu = !showMenu;
    notifyListeners();
  }

  /// Debounced progress save after page turns.
  void scheduleProgressSave({Duration delay = ReadingProgressStore.debounce}) {
    _progress.schedule(book: book, chapters: chapters, delay: delay);
  }

  /// Flush any pending debounced save immediately (call on exit / background).
  Future<void> flushProgressSave() {
    return _progress.flush(book: book, chapters: chapters);
  }

  /*状态保存 */
  Future<void> saveData() {
    return _progress.save(book: book, chapters: chapters);
  }

    /*页面点击事件（兼容旧入口） */
  void tapPage(BuildContext context, TapUpDetails details) {
    final size = MediaQuery.of(context).size;
    tapPageAt(details.localPosition, size);
  }

  /// Zone tap using local coordinates of the reader canvas.
  /// Middle → menu; left/right → page turn (respects [tapLeftToAdvance]).
  ///
  /// Returns `true` if a page-turn was started (not for menu-only).
  bool tapPageAt(Offset localPos, Size size) {
    if (pagePainter?.pageManager?.isBusy == true) {
      return false;
    }
    final wid = size.width;
    final hSpace = size.height / 4;
    final space = wid / 3;
    final x = localPos.dx;
    final y = localPos.dy;
    if (x > space && x < 2 * space && y < hSpace * 3) {
      toggleShowMenu();
      return false;
    }
    if (x >= 2 * space) {
      return turnByDirection(1, localPos);
    }
    if (x <= space) {
      return turnByDirection(tapLeftToAdvance ? 1 : -1, localPos);
    }
    return false;
  }

  /// Returns true if a turn was started.
  bool turnByDirection(int f, Offset detail) {
    if (pagePainter?.pageManager?.isBusy == true) {
      return false;
    }
    final mgr = pagePainter?.pageManager;
    if (mgr != null) {
      return mgr.triggerTapTurn(f);
    }
    commitPageTurn(f);
    canvasKey?.currentContext?.findRenderObject()?.markNeedsPaint();
    notifyListeners();
    return true;
  }

  /// True when reader uses vertical page-stack scroll (mode 3).
  bool get isScrollMode =>
      currentAnimationMode == ReaderPageManager.TYPE_ANIMATION_SLIDE_TURN;

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
  void setAnimationMode(int mode) {
    final m = mode.clamp(0, 3);
    if (currentAnimationMode == m) return;
    currentAnimationMode = m;
    ReadSetting.setPageTurnMode(m);
    // Drop pictures so chrome / no-chrome caches do not mix.
    pictureCache.clear();
    notifyListeners();
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
    final b = book;
    if (b == null || !_progress.ready) return;
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
  ui.Picture? scrollPagePicture(int chapterIdx, int pageIdx, ReadPage readPage) {
    return _pictures.scrollTile(
      chapterIdx,
      pageIdx,
      readPage,
      drawScrollContent,
    );
  }

  /// Natural height of a scroll tile (content only + tiny pad).
  double scrollPageHeight(ReadPage readPage, int pageIdx) =>
      _painter.scrollPageHeight(readPage, pageIdx);

  /// Paint body lines only into a tight-height picture for continuous scroll.
  ui.Picture drawScrollContent(ReadPage readPage, int pageIdx) {
    paperTheme = ReadSetting.getPaperTheme();
    return _painter.drawScrollContent(
      readPage,
      pageIdx,
      paperTheme: paperTheme,
    );
  }

  /// Load a chapter for the scroll window (skips sentinel empty pages).
  Future<ReadPage?> loadScrollChapter(int idx) async {
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

  ui.Picture? resolveCurrentPicture({bool firstInit = false}) =>
      _pictures.resolveCurrent(firstInit: firstInit);

  void preloadNeighborPictures() => _pictures.preloadNeighbors();

  ui.Picture? paintPreviousPicture() => _pictures.paintPrevious();

  ui.Picture? paintCurrentPicture() => _pictures.paintCurrent();

  ui.Picture? paintNextPicture() => _pictures.paintNext();

  Future<ui.Image> loadAssetImage(String asset, {int? width, int? height}) async {
    final data = await rootBundle.load(asset);
    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: width,
      targetHeight: height,
    );
    final fi = await codec.getNextFrame();
    return fi.image;
  }

  /// Paint one page picture.
  ///
  /// [chrome]: when true (page-turn), bake chapter title + battery/time/page.
  /// When false (vertical scroll), body only — chrome is a sticky overlay.
  ui.Picture drawContent(ReadPage readPage, int i, {bool chrome = true}) {
    paperTheme = ReadSetting.getPaperTheme();
    return _painter.drawContent(
      readPage,
      i,
      chrome: chrome,
      paperTheme: paperTheme,
    );
  }

  Future<void> clear() async {
    // Caller must flush progress first (ReadBook.dispose / lifecycle).
    // Cancel only the timer so a late debounce cannot write after clear.
    _progress.cancel();
    _progress.ready = false;
    _hideTextLoading();
    chapters = [];
    _diskChapterWarm.clear();
    sessionReady = false;
    chaptersLoading = false;
    loadingHint = '正在加载…';
    pictureCache.clear();
    // Keep a neutral loading page so the next open doesn't paint stale content
    // if prepareOpen races with a rebuild.
    final page = ReadPage.kong();
    page.chapterName = '加载中';
    page.chapterContent = loadingHint;
    page.pages = [
      TextPage([TextLine(loadingHint, 0, 0, 0)], 24),
    ];
    curPage = page;
    prePage = null;
    nextPage = null;
    book = null;
    pagePainter = null;
    canvasKey = null;
  }

  Future<void> reloadChapters() async {
    final b = book;
    if (b == null) return;
    chaptersLoading = true;
    loadingHint = '正在重新加载目录…';
    notifyListeners();

    try {
      final list = await fetchRemoteToc() ?? [];
      if (list.isEmpty) {
        BotToast.showText(text: '目录为空，请检查书源或网络');
        return;
      }

      await _ensureBookRow(b);
      // Diff-upsert preserves body/page cache for unchanged chapter ids.
      await _chapters.syncToc(list, b.id, sourceUrl: b.sourceUrl);
      chapters = await _chapters.getToc(b.id);
      if (chapters.isEmpty) chapters = list;
    } finally {
      chaptersLoading = false;
      notifyListeners();
    }
  }

  Future<void> reloadCurrentPage() async {
    final b = book;
    if (b == null) return;
    if (chapters.isEmpty || b.chapterIndex < 0 || b.chapterIndex >= chapters.length) return;
    toggleShowMenu();
    var chapter = chapters[b.chapterIndex];
    _showTextLoading('正在刷新正文…');

    var content = "";
    try {
      content = await fetchChapterBody(chapter.id, idx: b.chapterIndex);
    } catch (e) {
      content = "章节内容加载失败，请检查书源或换源后重试";
    }

    _hideTextLoading();
    if (content.isNotEmpty) {
      var temp = [ChapterNode(content, chapter.id)];
      await _chapters.updateBodies(temp);
      chapters[b.chapterIndex].hasBody = true;

      curPage = await loadChapter(b.chapterIndex);
      notifyListeners();
      final ro = canvasKey?.currentContext?.findRenderObject();
      if (ro != null) {
        ro.markNeedsPaint();
      }
    }
  }

  void resetPages() {
    prePage = null;
    curPage = null;
    nextPage = null;
  }

  Future<void> downloadAll(int start) async {
    if (chapters.isEmpty) {
      await loadToc(init: true);
    }
    await _ensureSource();
    await _downloads.downloadFrom(
      toc: chapters,
      start: start,
      source: _activeSource,
      bookName: book?.name ?? '',
      batchSize: downloadBatchSize,
    );
  }

  Future<String> fetchChapterBody(String id, {int? idx}) async {
    if (book == null) return '';
    await _ensureSource();
    return _downloads.fetchBody(
      source: _activeSource,
      toc: chapters,
      chapterId: id,
      idx: idx,
    );
  }

    /// Switch active source for the current book, remap progress, reload toc.
  Future<bool> switchSource(BookSource source, SearchBook hit) async {
    final b = book;
    if (b == null) return false;
    final oldName = (b.chapterIndex >= 0 && b.chapterIndex < chapters.length)
        ? chapters[b.chapterIndex].title
        : b.readingChapter;
    final oldIndex = b.chapterIndex;

    await _showTextLoading('正在换源…');
    try {
      final result = await _sourceSwitch.switchTo(
        book: b,
        source: source,
        hit: hit,
        oldChapterName: oldName,
        oldChapterIndex: oldIndex,
      );
      if (result == null) return false;

      _activeSource = result.source;
      chapters = result.chapters;
      _diskChapterWarm.clear();
      resetPages();
      pictureCache.clear();
      await openChapterAt(b.chapterIndex, true);
      final mapped = result.mappedChapterIndex;
      final name = (mapped >= 0 && mapped < chapters.length)
          ? chapters[mapped].title
          : '';
      BotToast.showText(
        text: '已切换至「${source.bookSourceName}」，定位到：$name',
      );
      notifyListeners();
      return true;
    } finally {
      _hideTextLoading();
    }
  }

  void toggleTapLeftToAdvance() {
    tapLeftToAdvance = !tapLeftToAdvance;
    SpUtil.putBool(PrefsKeys.leftClickNext, tapLeftToAdvance);
    notifyListeners();
  }

  void _refreshBattery() {
    Future.delayed(const Duration(milliseconds: 500), () async {
      try {
        electricQuantity = (await Battery().batteryLevel) / 100;
      } catch (_) {
        // Desktop / unsupported platforms: keep previous value.
      }
    });
  }

  void commitPageTurn(Object? offsetDifference) {
    _pageTurn.commit(offsetDifference);
  }

  /// Drop in-memory pictures outside the nearby chapter window / hard cap.
  void _prunePictureCache() {
    final b = book;
    if (b == null) return;
    pictureCache.prune(bookId: b.id, centerChapter: b.chapterIndex);
  }

  bool canTurnNext() {
    final b = book;
    if (b == null) return false;
    // Last chapter, last page.
    if (b.chapterIndex >= chapters.length - 1 &&
        b.pageIndex >= ((curPage?.pageOffsets ?? 1) - 1)) {
      return false;
    }
    // Prefer pre-rendered picture, but allow turn if logical next exists.
    if (paintNextPicture() != null) return true;
    // Next page within chapter, or next chapter available.
    if (b.pageIndex + 1 < (curPage?.pageOffsets ?? 0)) return true;
    return b.chapterIndex + 1 < chapters.length;
  }

  bool canTurnPrevious() {
    final b = book;
    if (b == null) return false;
    if (b.chapterIndex <= 0 && b.pageIndex <= 0) return false;
    if (paintPreviousPicture() != null) return true;
    if (b.pageIndex > 0) return true;
    return b.chapterIndex > 0;
  }

  Future<void> reloadBackgroundImage() async {
    paperTheme = ReadSetting.getPaperTheme();
    // Solid paper mode: no texture image.
    if (ReadSetting.useSolidPaper()) {
      bgUI = null;
      return;
    }
    if (SpUtil.getBool(PrefsKeys.dark) || paperTheme == PaperTheme.night) {
      bgUI = await loadAssetImage("images/${ReadSetting.bgImg.last}",
          width: Screen.width.ceil(), height: Screen.height.ceil());
    } else {
      bgUI = await loadAssetImage("images/$backgroundImageName",
          width: Screen.width.ceil(), height: Screen.height.ceil());
    }
  }
}
