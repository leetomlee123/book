import 'dart:async';
import 'dart:ui' as ui;

import 'package:battery_plus/battery_plus.dart';
import 'package:book/common/chapter_cache.dart';
import 'package:book/common/read_setting.dart';
import 'package:book/common/screen.dart';
import 'package:book/common/app_log.dart';
import 'package:book/common/book_pager.dart';
import 'package:book/common/common.dart';
import 'package:book/common/text_composition.dart';
import 'package:book/data/repositories/book_repository.dart';
import 'package:book/data/repositories/chapter_repository.dart';
import 'package:book/entity/book.dart';
import 'package:book/entity/chapter_node.dart';
import 'package:book/entity/chapter_toc_entry.dart';
import 'package:book/entity/read_page.dart';
import 'package:book/entity/text_line.dart';
import 'package:book/entity/text_page.dart';
import 'package:book/model/source_model.dart';
import 'package:book/model/reader/reader_painter.dart';
import 'package:book/model/reader/text_paginator.dart';
import 'package:book/source/engine/book_source_engine.dart';
import 'package:book/source/engine/progress_mapper.dart';
import 'package:book/source/model/book_source.dart';
import 'package:book/source/model/search_book.dart';
import 'package:book/source/util/book_id.dart';
import 'package:book/view/page_turn/novel_page_painter.dart';
import 'package:book/view/page_turn/reader_page_manager.dart';
import 'package:bot_toast/bot_toast.dart';
import 'package:book/common/local_store.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ReadModel with ChangeNotifier {
  Color darkFont = Color(0x7FFFFFFF);
  NovelPagePainter? mPainter;
  TextComposition? textComposition;
  Map<String, ui.Picture> widgets = {};
  Stack? stackContent;
  Paint bgPaint = Paint();
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
  BookSource? _activeSource;

  /// In-memory warm cache of disk chapter body + page layout (cur±1).
  final Map<String, ({String body, String? pagesJson, String? layoutFp})>
      _diskChapterWarm = {};

  var currentPageValue = 0.0;

  bool isDark() => SpUtil.getBool("dark");

  double get electricQuantity => _painter.electricQuantity;
  set electricQuantity(double value) => _painter.electricQuantity = value;

  //本书记录
  ReadPage? prePage;
  ReadPage? curPage;
  ReadPage? nextPage;

  double percent = 0;

  //缓存批量提交大小
  int batchNum = 100;
  bool refresh = true;

  /// Debounced progress persist after page turns.
  Timer? _progressSaveTimer;
  static const _progressSaveDebounce = Duration(milliseconds: 800);

  /// Soft cap for in-memory page pictures (disk holds TextPage JSON).
  static const int _maxPictureCache = 24;

  /// False until [hydrateReadingSession] finishes hydrating progress from DB.
  /// Prevents lifecycle/dispose from writing route-stale zeros over durable progress.
  bool _progressReady = false;

  //显示上层 设置
  bool showMenu = false;

  //背景色索引（legacy texture path; solid paper preferred）
  String bgPath =
      SpUtil.getString(Common.bgIdx, defValue: ReadSetting.bgImg.first);

  PaperTheme paperTheme = ReadSetting.getPaperTheme();

//章节翻页标志
  bool loadOk = false;

  /// True while TOC is being fetched (open book / 重新加载目录).
  /// UI should show text hint, not a spinner.
  bool chaptersLoading = false;

  /// Status text while [loadOk] is false or chapters are refreshing.
  String loadingHint = '正在加载目录…';

  //页面宽高

  bool jump = true;

  //阅读方式
  // bool isPage = false;
  // bool isPage = SpUtil.getBool("isPage", defValue: true);

  //点击上下页方式
  bool leftClickNext = SpUtil.getBool("leftClickNext", defValue: false);

  //页面上下文

//是否修改font
  bool? sSave;

  /// Sync seed when opening a book from shelf — call before first paint.
  /// Clears previous book state and plants a centered loading page so the
  /// transition does not flash the last book or a blank scaffold.
  void prepareOpen(Book b) {
    _hideTextLoading();
    showMenu = false;
    chaptersLoading = true;
    loadingHint = '正在加载…';
    sSave = true;
    _progressReady = false;
    _progressSaveTimer?.cancel();
    _progressSaveTimer = null;
    widgets.clear();
    prePage = null;
    nextPage = null;
    mPainter = null;
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
    loadOk = true;
    // Do not notifyListeners here: the upcoming ReadBook build will watch us.
  }

  //获取本书记录
  Future<void> hydrateReadingSession() async {
    try {
      electricQuantity = (await Battery().batteryLevel) / 100;
    } catch (e) {
      AppLog.w('Read', 'batteryLevel failed', error: e);
      electricQuantity = 1.0;
    }
    showMenu = false;
    chaptersLoading = true;
    loadingHint = loadingHint.isEmpty ? '正在加载…' : loadingHint;
    sSave = true;
    // book already set by prepareOpen when coming from shelf.
    book ??= null;
    final b = book;
    if (b == null) {
      AppLog.w('Read', 'hydrateReadingSession: book is null');
      chaptersLoading = false;
      return;
    }

    // Prefer durable progress from reader.db over possibly-stale route JSON.
    // Snapshot IMMEDIATELY — loading UI must never overwrite these.
    var savedCur = b.chapterIndex;
    var savedIndex = b.pageIndex;
    try {
      final dbBook = await _books.getById(b.id);
      if (dbBook != null) {
        savedCur = dbBook.chapterIndex;
        savedIndex = dbBook.pageIndex;
        b.chapterIndex = savedCur;
        b.pageIndex = savedIndex;
        b.scrollOffset = dbBook.scrollOffset;
        if (dbBook.readingChapter.isNotEmpty) {
          b.readingChapter = dbBook.readingChapter;
        }
        AppLog.i(
          'Read',
          'merged db progress cur=$savedCur index=$savedIndex '
              'name=${b.readingChapter}',
        );
      }
    } catch (e) {
      AppLog.w('Read', 'merge db progress failed', error: e);
    }

    // Ensure a loading page exists (in case prepareOpen was skipped).
    if (curPage == null || curPage!.chapterName != '加载中') {
      curPage = await _messagePage('加载中', loadingHint);
      notifyListeners();
    }

    AppLog.i(
      'Read',
      'open id=${b.id} name=${b.name} cur=$savedCur index=$savedIndex '
          'source=${b.originName} sourceUrl=${b.sourceUrl} bookUrl=${b.bookUrl}',
    );

    if (b.sourceUrl.isEmpty || b.bookUrl.isEmpty) {
      AppLog.w('Read', 'missing sourceUrl/bookUrl for ${b.id}');
      BotToast.showText(text: '旧版云端书籍无法继续阅读，请重新搜索添加');
      curPage = await _messagePage(
        '无法阅读',
        '旧版云端书籍缺少书源信息，请重新搜索添加后再阅读。',
      );
      // Restore snapshot; do not mark ready (cannot read / no page turn).
      b.chapterIndex = savedCur < 0 ? 0 : savedCur;
      b.pageIndex = savedIndex < 0 ? 0 : savedIndex;
      loadOk = true;
      chaptersLoading = false;
      _progressReady = false;
      notifyListeners();
      return;
    }

    await _showTextLoading('正在准备书源…');
    // Loading placeholder must not wipe durable progress.
    b.chapterIndex = savedCur;
    b.pageIndex = savedIndex;
    await _ensureSource();
    if (_activeSource == null) {
      AppLog.e('Read', 'source not found: ${b.sourceUrl} (${b.originName})');
      BotToast.showText(text: '书源不存在：${b.originName}');
      curPage = await _messagePage(
        '书源不可用',
        '未找到书源「${b.originName}」，请在书源管理中导入对应书源，或在阅读菜单中换源。',
      );
      b.chapterIndex = savedCur < 0 ? 0 : savedCur;
      b.pageIndex = savedIndex < 0 ? 0 : savedIndex;
      loadOk = true;
      chaptersLoading = false;
      _progressReady = false;
      notifyListeners();
      return;
    }

    await _showTextLoading('正在读取本地目录…');
    b.chapterIndex = savedCur;
    b.pageIndex = savedIndex;
    chapters = await _chapters.getToc(b.id);
    AppLog.i('Read', 'local chapters=${chapters.length}');

    if (chapters.isNotEmpty) {
      // refresh toc in background for new chapters
      getChapters();

      if (savedCur < 0 || savedCur >= chapters.length) {
        AppLog.w(
          'Read',
          'clamp cur $savedCur -> 0 (len=${chapters.length})',
        );
        b.chapterIndex = 0;
      } else {
        b.chapterIndex = savedCur;
      }
      b.pageIndex = savedIndex < 0 ? 0 : savedIndex;
      // Skip loading flash when body + page layout are already cached.
      final canSkipLoading = await _hasPageCache(b.chapterIndex);
      await initPageContent(b.chapterIndex, false, showLoading: !canSkipLoading);
      _restorePageIndex(savedIndex);
      loadOk = true;
      chaptersLoading = false;
      _progressReady = true;
      AppLog.i(
        'Read',
        'ready cur=${b.chapterIndex} index=${b.pageIndex} pages=${curPage?.pageOffsets} '
            'contentLen=${curPage?.chapterContent.length}',
      );

      notifyListeners();
    } else {
      await _showTextLoading('正在获取章节目录…');
      b.chapterIndex = savedCur;
      b.pageIndex = savedIndex;
      await getChapters(init: true);
      AppLog.i('Read', 'fetched toc chapters=${chapters.length}');
      if (chapters.isEmpty) {
        AppLog.e('Read', 'toc empty after fetch for ${b.bookUrl}');
        curPage = await _messagePage(
          '目录为空',
          '未能获取章节目录，请检查书源规则、网络，或尝试换源。',
        );
        b.chapterIndex = savedCur < 0 ? 0 : savedCur;
        b.pageIndex = savedIndex < 0 ? 0 : savedIndex;
      } else {
        if (savedCur < 0 || savedCur >= chapters.length) {
          b.chapterIndex = 0;
        } else {
          b.chapterIndex = savedCur;
        }
        b.pageIndex = savedIndex < 0 ? 0 : savedIndex;
        await initPageContent(b.chapterIndex, false, showLoading: true);
        _restorePageIndex(savedIndex);
      }
      loadOk = true;
      chaptersLoading = false;
      // Allow persist even if toc empty — chapter index is still meaningful.
      _progressReady = true;
      notifyListeners();
    }
  }

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
    loadOk = true;
    chaptersLoading = false;
    _progressReady = false;
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
    widgets.clear();
    final ro = canvasKey?.currentContext?.findRenderObject();
    ro?.markNeedsPaint();
    notifyListeners();
  }

  void _hideTextLoading() {
    // Content replacement (initPageContent / chapter load) clears the hint page.
    // Bump token so any in-flight _showTextLoading paint is ignored.
    _loadingToken++;
  }

  Future initPageContent(int idx, bool jump, {bool showLoading = true}) async {
    // Preserve in-chapter page across loading placeholder (jump still resets).
    final keepIndex = book?.pageIndex ?? 0;
    if (showLoading) {
      await _showTextLoading('正在加载…');
    }

    try {
      final b = book;
      if (b != null && chapters.isNotEmpty) {
        if (idx < 0) idx = 0;
        if (idx >= chapters.length) idx = chapters.length - 1;
        b.chapterIndex = idx;
      }

      // Warm cur±1 disk rows in one SQLite query before paginating neighbors.
      await _warmDiskChapterCaches(idx);

      curPage = await loadChapter(idx);
      curPage ??= await _messagePage(
          '加载失败',
          '当前章节内容为空，请检查书源或点击菜单刷新。',
        );

      // Drop stale page-picture cache for this book so new layout is painted.
      widgets.clear();

      loadChapter(idx + 1).then((value) => nextPage = value);
      loadChapter(idx - 1).then((value) => prePage = value);

      if (jump) {
        book?.pageIndex = 0;
      } else {
        // Re-apply saved page after loading UI; clamp to real page count.
        _restorePageIndex(keepIndex);
      }
      final ro = canvasKey?.currentContext?.findRenderObject();
      if (ro != null) {
        ro.markNeedsPaint();
      }
      notifyListeners();
    } catch (e, st) {
      AppLog.e('Read', 'initPageContent failed idx=$idx', error: e, stackTrace: st);
      curPage ??= await _messagePage('加载失败', '章节加载异常：$e');
      notifyListeners();
    } finally {
      if (showLoading) {
        _hideTextLoading();
      }
    }
  }

  Future<void> colorModelSwitch() async {
    await changeBgUI();
    widgets.clear();

    final ro = canvasKey?.currentContext?.findRenderObject();
    if (ro != null) {
      ro.markNeedsPaint();
    }
  }

  Future<void> switchBgColor(Object? i) async {
    // Legacy texture path.
    final path = i?.toString() ?? bgPath;
    bgPath = path;
    SpUtil.putString(Common.bgIdx, path);
    ReadSetting.setUseSolidPaper(false);
    await colorModelSwitch();
    notifyListeners();
  }

  /// WeChat-style solid paper swatch.
  Future<void> switchPaperTheme(PaperTheme theme) async {
    paperTheme = theme;
    ReadSetting.setPaperTheme(theme);
    ReadSetting.setUseSolidPaper(true);
    widgets.clear();
    bgUI = null; // solid fill only
    await colorModelSwitch();
    notifyListeners();
  }

  Future<List<ChapterTocEntry>?> reqChapters() async {
    final b = book;
    if (b == null) return null;
    await _ensureSource();
    final source = _activeSource;
    if (source == null) {
      BotToast.showText(text: '书源不存在：${b.originName}');
      return null;
    }
    final tocUrl =
        b.tocUrl.isNotEmpty ? b.tocUrl : (b.bookUrl.isNotEmpty ? b.bookUrl : '');
    if (tocUrl.isEmpty) return null;
    try {
      AppLog.i(
        'Read',
        'reqChapters source=${source.bookSourceName} '
            'tocUrl=$tocUrl chapterList=${source.ruleToc.chapterList}',
      );
      final list = await _engine.toc(source, tocUrl);
      AppLog.i('Read', 'reqChapters got ${list.length} chapters');
      return list
          .map((c) => ChapterTocEntry(
                id: makeChapterId(b.id, c.url),
                title: c.name,
                url: c.url,
                hasBody: false,
                ord: c.index,
              ))
          .toList();
    } catch (e, st) {
      AppLog.e('Read', 'reqChapters failed for $tocUrl', error: e, stackTrace: st);
      BotToast.showText(text: '目录加载失败：$e');
      return null;
    }
  }

  Future getChapters({bool init = false}) async {
    final b = book;
    if (b == null) return;
    // Capture id so a late network return cannot touch a different/closed book.
    final bookId = b.id;
    List<ChapterTocEntry>? list = await reqChapters();
    if (list == null || list.isEmpty) return;
    // Reader may have been closed (clear() sets book=null) while toc was in flight.
    if (book?.id != bookId) {
      AppLog.i('Read', 'getChapters drop stale toc for $bookId');
      return;
    }

    // reader.db enforces FK: chapters.book_id → books.id. Create the book
    // row first so TOC inserts never fail on first open.
    await _ensureBookRow(book!);
    if (book?.id != bookId) return;

    if (init || chapters.isEmpty) {
      chapters = list;
      // Diff-upsert keeps any already-cached bodies for matching chapter ids.
      await _chapters.syncToc(list, bookId, sourceUrl: b.sourceUrl);
      AppLog.i('Read', 'toc saved init=${list.length} id=$bookId');
    } else {
      // append only new urls
      final existing = chapters.map((e) => e.url).toSet();
      final fresh = list.where((e) => !existing.contains(e.url)).toList();
      if (fresh.isNotEmpty) {
        for (final c in fresh) {
          c.ord = chapters.length;
          chapters.add(c);
        }
        await _chapters.appendToc(fresh, bookId, sourceUrl: b.sourceUrl);
        AppLog.i('Read', 'toc append ${fresh.length} id=$bookId');
      }
    }
    if (book?.id != bookId) return;
    if (list.isNotEmpty) {
      book!.latestChapter = list.last.title;
    }
    notifyListeners();
  }

  /// Insert book row if missing. Concurrent callers may race; insert ignores PK conflict.
  /// Prefetch cur±1 chapter body/layout rows in one SQLite query.
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
    // Empty toc: never treat as "beyond last chapter" (0 == length).
    if (chapters.isEmpty) {
      return _messagePage(
        '目录为空',
        '暂无章节，请检查书源或网络后重试。',
      );
    }
    if (idx < 0) {
      final r = ReadPage.kong();
      r.chapterName = "1";
      r.chapterContent = "Fall In Love At First Sight ,Miss.Zhang";
      return r;
    }
    // Past last chapter — used as nextPage sentinel.
    if (idx >= chapters.length) {
      final r = ReadPage.kong();
      r.chapterName = "-1";
      r.chapterContent = "没有更多内容,等待作者更新";
      return null;
    }
    var chapter = chapters[idx];
    final r = ReadPage.kong();
    r.chapterName = chapter.title;
    String chapterId = chapter.id;

    // Single SQLite round-trip: body + page layout (prefer warm cache).
    var contentSource = 'empty';
    String? cachedPagesJson;
    String? cachedLayoutFp;
    try {
      final disk = _diskChapterWarm.remove(chapterId) ??
          await _chapters.getChapterCache(chapterId);
      r.chapterContent = disk.body;
      cachedPagesJson = disk.pagesJson;
      cachedLayoutFp = disk.layoutFp;
      if (r.chapterContent.isNotEmpty) contentSource = 'db';
    } catch (e) {
      r.chapterContent = '';
    }

    // Re-fetch if cache is empty or looks truncated (common after a bad source rule).
    final cached = r.chapterContent;
    final cacheLooksBad = cached.isEmpty ||
        (cached.length < 120 &&
            !cached.startsWith('章节内容加载失败') &&
            !cached.startsWith('书源不存在') &&
            !cached.startsWith('章节地址为空') &&
            !cached.startsWith('内容为空'));
    if (cacheLooksBad) {
      final fresh = await getChapterContent(chapterId, idx: idx);
      if (fresh.isNotEmpty &&
          !fresh.startsWith('章节内容加载失败') &&
          !fresh.startsWith('书源不存在') &&
          !fresh.startsWith('章节地址为空') &&
          fresh.length > cached.length) {
        r.chapterContent = fresh;
        contentSource = 'network';
        cachedPagesJson = null;
        cachedLayoutFp = null;
        var temp = [ChapterNode(r.chapterContent, chapterId)];
        // updateBodies also clears stale pages_json for this chapter.
        await _chapters.updateBodies(temp);
        chapters[idx].hasBody = true;
      } else if (r.chapterContent.isEmpty) {
        r.chapterContent = fresh.isNotEmpty
            ? fresh
            : '章节内容加载失败，请检查书源或换源后重试';
        contentSource = fresh.isNotEmpty ? 'network-error-text' : 'fail';
      }
    }

    // --- CONTENT DIAG (区分「正文本身一行」vs「分页坏了」) ---
    _logContentDiag(idx, r.chapterName, r.chapterContent, contentSource);

    final b = book;

    // Try disk page-layout cache before re-paginating.
    final layout = _paginator.layoutParams();
    final contentSig = _paginator.contentSignature(r.chapterContent);
    final fp = _paginator.layoutFingerprint(
      layoutParams: layout,
      contentLen: r.chapterContent.length,
      contentSig: contentSig,
    );

    List<TextPage>? cachedPages;
    try {
      if (cachedPagesJson != null &&
          cachedPagesJson.isNotEmpty &&
          cachedLayoutFp == fp) {
        cachedPages =
            await ChapterRepository.decodePagesJson(cachedPagesJson);
        if (cachedPages != null && cachedPages.isNotEmpty) {
          AppLog.i(
            'Read',
            'page cache HIT idx=$idx id=$chapterId pages=${cachedPages.length}',
          );
        }
      } else if (cachedPagesJson != null && cachedPagesJson.isNotEmpty) {
        AppLog.i(
          'Read',
          'page cache STALE idx=$idx fp=$cachedLayoutFp want=$fp',
        );
      }
    } catch (e) {
      AppLog.w('Read', 'page cache read failed idx=$idx', error: e);
    }

    if (cachedPages != null && cachedPages.isNotEmpty) {
      r.pages = cachedPages;
      // Cache hit skips re-layout — still report which engine is available now.
      debugPrint(
        '[PagerEngine] CACHE_HIT idx=$idx pages=${cachedPages.length} '
        'nativeAvailable=${BookPager.isAvailable} '
        '(layout not re-run; open a new chapter or change font to force paginate)',
      );
      AppLog.i(
        'Pager',
        'CACHE_HIT idx=$idx pages=${cachedPages.length} '
            'native=${BookPager.isAvailable}',
      );
    } else {
      // Always re-paginate with current layout metrics (Rust / Dart).
      try {
        r.pages = await _paginator.paginate(r);
      } catch (e, st) {
        AppLog.e('Read', 'parseContentAsync failed idx=$idx',
            error: e, stackTrace: st);
        r.pages = const [];
      }

      if (r.pages.isEmpty) {
        try {
          r.pages = await _paginator.paginate(r);
        } catch (e, st) {
          AppLog.e('Read', 'parseContentAsync retry failed idx=$idx',
              error: e, stackTrace: st);
        }
        if (r.pages.isEmpty) {
          r.pages = _fallbackPages(r.chapterContent);
        }
      }

      // Persist layout async so UI is not blocked by JSON encode + SQLite.
      if (r.pages.isNotEmpty &&
          contentSource != 'fail' &&
          contentSource != 'network-error-text' &&
          !r.chapterContent.startsWith('章节内容加载失败')) {
        final pagesToSave = r.pages;
        final saveId = chapterId;
        final saveFp = fp;
        final bookId = b?.id;
        final cur = b?.chapterIndex ?? idx;
        unawaited(() async {
          try {
            final json =
                await ChapterRepository.encodePagesJson(pagesToSave);
            // Skip pathological multi-MB pages for a single chapter.
            if (json.length > 2 * 1024 * 1024) {
              AppLog.w(
                'Read',
                'skip page cache write idx=$idx size=${json.length}',
              );
              return;
            }
            await _chapters.savePageLayout(saveId, json, saveFp);
            await ChapterCache.maybeEvict(
              activeBookId: bookId,
              activeCur: cur,
            );
          } catch (e) {
            AppLog.w('Read', 'page cache write failed idx=$idx', error: e);
          }
        }());
      }
    }

    // --- PAGE DIAG ---
    _logPageDiag(idx, r);

    return r;
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

  /// 打印正文形态：长度 / 换行数 / 最长一行 / 预览。
  void _logContentDiag(
    int idx,
    String name,
    String content,
    String source,
  ) {
    final text = content;
    final len = text.length;
    final nl = '\n'.allMatches(text).length;
    final crlf = '\r\n'.allMatches(text).length;
    final br = RegExp(r'<br\s*/?>', caseSensitive: false).allMatches(text).length;
    final pTag = RegExp(r'</p>', caseSensitive: false).allMatches(text).length;
    final lines = text.split('\n');
    var maxLine = 0;
    for (final l in lines) {
      if (l.length > maxLine) maxLine = l.length;
    }
    final preview = text.length <= 120
        ? text.replaceAll('\n', r'\n')
        : '${text.substring(0, 120).replaceAll('\n', r'\n')}…';
    final verdict = (len > 80 && nl == 0 && br == 0 && pTag == 0)
        ? 'CONTENT_ONE_BLOB' // 正文几乎无换行 → 源/清洗问题或需强制按字宽切
        : (len <= 40 ? 'CONTENT_SHORT' : 'CONTENT_HAS_BREAKS');
    AppLog.i(
      'ReadDiag',
      'CONTENT idx=$idx name=$name src=$source '
          'len=$len newlines=$nl crlf=$crlf br=$br pTag=$pTag '
          'splitLines=${lines.length} maxLineLen=$maxLine '
          'verdict=$verdict preview="$preview"',
    );
  }

  /// 打印分页结果：页数 / 首页行数 / 单行是否过长。
  void _logPageDiag(int idx, ReadPage r) {
    final pages = r.pages;
    final totalLines =
        pages.fold<int>(0, (n, p) => n + p.lines.length);
    final lines0 = pages.isEmpty ? 0 : pages.first.lines.length;
    final firstLine = (pages.isEmpty || pages.first.lines.isEmpty)
        ? ''
        : pages.first.lines.first.text;
    final firstLineLen = firstLine.characters.length;
    var maxLineChars = 0;
    for (final p in pages) {
      for (final l in p.lines) {
        final c = l.text.characters.length;
        if (c > maxLineChars) maxLineChars = c;
      }
    }
    final contentLen = r.chapterContent.length;
    String verdict;
    if (contentLen > 80 && totalLines <= 1) {
      verdict = 'PAGE_BROKEN_ONE_LINE'; // 正文不短但分页只 1 行 → 分页错误
    } else if (contentLen > 80 && maxLineChars > 80) {
      verdict = 'PAGE_OVERLONG_LINE'; // 有行过长 → 软换行失败
    } else if (contentLen <= 40) {
      verdict = 'PAGE_OK_SHORT_CONTENT';
    } else {
      verdict = 'PAGE_OK';
    }
    AppLog.i(
      'ReadDiag',
      'PAGE idx=$idx name=${r.chapterName} contentLen=$contentLen '
          'pages=${pages.length} totalLines=$totalLines lines0=$lines0 '
          'firstLineLen=$firstLineLen maxLineChars=$maxLineChars '
          'verdict=$verdict firstLine="${firstLine.length > 60 ? '${firstLine.substring(0, 60)}…' : firstLine}"',
    );
  }

  /// Wrap plain text into simple pages when the normal pager failed.
  List<TextPage> _fallbackPages(String content) {
    final text = content.trim();
    if (text.isEmpty) {
      return [TextPage([TextLine('内容为空', 16, 0, 0)], 24)];
    }
    try {
      final pages = _paginator.paginateSync(
        ReadPage(text, '', 0, const []),
      );
      if (pages.isNotEmpty && pages.any((p) => p.lines.isNotEmpty)) {
        return pages;
      }
    } catch (_) {}
    // Character-chunk wrap so paint still shows multiple lines.
    const charsPerLine = 18;
    const linesPerPage = 20;
    final lines = <TextLine>[];
    final pages = <TextPage>[];
    var dy = 0.0;
    final lineH = ReadSetting.getFontSize() * ReadSetting.getLineHeight();
    for (var i = 0; i < text.length; i += charsPerLine) {
      final end = (i + charsPerLine > text.length) ? text.length : i + charsPerLine;
      lines.add(TextLine(text.substring(i, end), 16, dy, 0));
      dy += lineH;
      if (lines.length >= linesPerPage) {
        pages.add(TextPage(List<TextLine>.from(lines), dy));
        lines.clear();
        dy = 0;
      }
    }
    if (lines.isNotEmpty) {
      pages.add(TextPage(lines, dy));
    }
    return pages.isEmpty
        ? [TextPage([TextLine(text, 16, 0, 0)], 24)]
        : pages;
  }

  /*
   * 页面配置修改（字号/行距等）：静默重分页，完成后刷新，不弹 loading。
   */
  Future<void> updPage() async {
    widgets.clear();
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
    await initPageContent(b?.chapterIndex ?? 0, false, showLoading: false);
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
  void scheduleProgressSave(
      {Duration delay = _progressSaveDebounce}) {
    if (sSave != true || book == null || !_progressReady) return;
    _progressSaveTimer?.cancel();
    if (delay == Duration.zero) {
      unawaited(saveData());
      return;
    }
    _progressSaveTimer = Timer(delay, () {
      unawaited(saveData());
    });
  }

  /// Flush any pending debounced save immediately (call on exit / background).
  Future<void> flushProgressSave() {
    _progressSaveTimer?.cancel();
    _progressSaveTimer = null;
    return saveData();
  }

  /*状态保存 */
  Future<void> saveData() async {
    if (sSave != true) return;
    // Skip until open path has merged DB progress + restored page index.
    // Otherwise lifecycle/dispose can overwrite durable progress with route defaults.
    if (!_progressReady) {
      AppLog.i('Read', 'skip progress save (not hydrated yet)');
      return;
    }
    final b = book;
    if (b == null) return;
    _progressSaveTimer?.cancel();
    _progressSaveTimer = null;

    // Snapshot before any await so dispose/clear cannot race.
    final cur = b.chapterIndex;
    final idx = b.pageIndex;
    final pos = b.scrollOffset;
    final id = b.id;
    final sourceUrl = b.sourceUrl;
    final tocSnapshot =
        chapters.isNotEmpty ? List<ChapterTocEntry>.from(chapters) : const <ChapterTocEntry>[];
    final name = (cur >= 0 && cur < tocSnapshot.length)
        ? tocSnapshot[cur].title
        : b.readingChapter;
    // Avoid wiping a real chapter title with empty/loading placeholder.
    if (name.isNotEmpty && name != '加载中') {
      b.readingChapter = name;
    }
    final chapterName = (b.readingChapter.isNotEmpty && b.readingChapter != '加载中')
        ? b.readingChapter
        : name;

    // Ensure book row first — reader.db FK requires books.id before chapters.
    await _ensureBookRow(b);
    // Persist TOC if missing (first open may not have flushed yet).
    if (tocSnapshot.isNotEmpty) {
      try {
        final len = await _chapters.count(id);
        if (len == 0) {
          await _chapters.syncToc(tocSnapshot, id, sourceUrl: sourceUrl);
          AppLog.i('Read', 'toc saved on exit count=${tocSnapshot.length}');
        }
      } catch (e) {
        AppLog.w('Read', 'toc save on exit failed', error: e);
      }
    }
    // Upsert progress (UPDATE may hit 0 rows on race).
    final updated = await _books.saveProgress(
      bookId: id,
      chapterIndex: cur,
      pageIndex: idx,
      scrollOffset: pos,
      readingChapter: chapterName,
    );
    if (updated == 0) {
      // Row missing (first open race) — insert then update.
      try {
        await _books.upsertAll([b]);
        await _books.saveProgress(
          bookId: id,
          chapterIndex: cur,
          pageIndex: idx,
          scrollOffset: pos,
          readingChapter: chapterName,
        );
      } catch (e) {
        AppLog.w('Read', 'progress upsert fallback failed', error: e);
      }
    }
    AppLog.i(
      'Read',
      'progress save id=$id cur=$cur idx=$idx name=$chapterName rows=$updated',
    );
  }

  /*页面点击事件（兼容旧入口） */
  void tapPage(BuildContext context, TapUpDetails details) {
    final size = MediaQuery.of(context).size;
    tapPageAt(details.localPosition, size);
  }

  /// Zone tap using local coordinates of the reader canvas.
  /// Middle → menu; left/right → page turn (respects [leftClickNext]).
  ///
  /// Returns `true` if a page-turn was started (not for menu-only).
  bool tapPageAt(Offset localPos, Size size) {
    if (mPainter?.pageManager?.isBusy == true) {
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
      return clickPage(1, localPos);
    }
    if (x <= space) {
      return clickPage(leftClickNext ? 1 : -1, localPos);
    }
    return false;
  }

  /// Returns true if a turn was started.
  bool clickPage(int f, Offset detail) {
    if (mPainter?.pageManager?.isBusy == true) {
      return false;
    }
    final mgr = mPainter?.pageManager;
    if (mgr != null) {
      return mgr.triggerTapTurn(f);
    }
    changeCoverPage(f);
    canvasKey?.currentContext?.findRenderObject()?.markNeedsPaint();
    notifyListeners();
    return true;
  }

  /// True when reader uses vertical page-stack scroll (mode 3).
  bool get isScrollMode =>
      currentAnimationMode == ReaderPageManager.TYPE_ANIMATION_SLIDE_TURN;

  /// True after [hydrateReadingSession] finished hydrating and current chapter is ready.
  /// Scroll surface must wait for this — [loadOk] alone is true during prepareOpen.
  bool get contentReady =>
      _progressReady &&
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
    widgets.clear();
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
    if (b == null || !_progressReady) return;
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
  /// Canvas height hugs body lines so stacked pages join without gaps.
  ui.Picture? scrollPagePicture(int chapterIdx, int pageIdx, ReadPage readPage) {
    final b = book;
    if (b == null) return null;
    if (pageIdx < 0 || pageIdx >= readPage.pages.length) return null;
    final key = '${b.id}$chapterIdx${pageIdx}sc';
    if (widgets.containsKey(key)) return widgets[key];
    final pic = drawScrollContent(readPage, pageIdx);
    return widgets.putIfAbsent(key, () => pic);
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

  ui.Picture? getPage({bool firstInit = false}) {
    final b = book;
    if (b == null) return null;
    var key = b.id.toString() + b.chapterIndex.toString() + b.pageIndex.toString();

    if (widgets.containsKey(key)) {
      return widgets[key];
    }
    var widget = cur();
    if (widget != null) {
      widgets.putIfAbsent(key, () => widget);
    }
    if (firstInit) {
      Future.delayed(Duration(milliseconds: 200), () => preLoadWidget());
    }
    return widget;
  }

  void preLoadWidget() {
    final b = book;
    if (b == null || curPage == null) return;

    // Previous / next page pictures; null neighbors are handled inside pre/next.
    if (prePage != null || b.pageIndex > 0) {
      pre();
    }
    if (nextPage != null || b.pageIndex + 1 < curPage!.pageOffsets) {
      next();
    }
  }

  ui.Picture? pre() {
    final b = book;
    final current = curPage;
    if (b == null || current == null) return null;
    final i = b.pageIndex - 1;
    final key = b.id.toString() + b.chapterIndex.toString() + i.toString();

    if (widgets.containsKey(key)) {
      return widgets[key];
    }

    final ui.Picture pic;
    if (i < 0) {
      final previous = prePage;
      if (previous == null || previous.pages.isEmpty) return null;
      pic = drawContent(previous, previous.pageOffsets - 1);
    } else {
      pic = drawContent(current, i);
    }
    return widgets.putIfAbsent(key, () => pic);
  }

  ui.Picture? cur() {
    final b = book;
    final current = curPage;
    if (b == null || current == null) return null;
    // Clamp for paint only — never mutate durable progress during draw.
    // Loading placeholders are 1 page; writing b.index=0 here wiped restores.
    if (current.pages.isEmpty) return null;
    var pageIdx = b.pageIndex;
    if (pageIdx < 0) pageIdx = 0;
    if (pageIdx >= current.pageOffsets) {
      pageIdx = current.pageOffsets - 1;
    }
    final key = b.id.toString() + b.chapterIndex.toString() + pageIdx.toString();

    if (widgets.containsKey(key)) {
      return widgets[key];
    }
    Future.delayed(const Duration(milliseconds: 200), () {
      // Skip if reader already left this book.
      if (book?.id == b.id) preLoadWidget();
    });
    final pic = drawContent(current, pageIdx);
    return widgets.putIfAbsent(key, () => pic);
  }

  ui.Picture? next() {
    final b = book;
    final current = curPage;
    if (b == null || current == null) return null;
    final i = b.pageIndex + 1;
    final key = b.id.toString() + b.chapterIndex.toString() + i.toString();

    if (widgets.containsKey(key)) {
      return widgets[key];
    }

    final ui.Picture pic;
    if (i >= current.pageOffsets) {
      final following = nextPage;
      if (following == null) {
        // Kick off async load; do not force-unwrap a null next chapter.
        loadChapter(b.chapterIndex + 1).then((value) {
          if (book?.id == b.id) nextPage = value;
        });
        return null;
      }
      if (following.pages.isEmpty) return null;
      pic = drawContent(following, 0);
    } else {
      pic = drawContent(current, i);
    }
    return widgets.putIfAbsent(key, () => pic);
  }

  Future<ui.Image> getAssetImage(String asset, {int? width, int? height}) async {
    ByteData data = await rootBundle.load(asset);
    ui.Codec codec = await ui.instantiateImageCodec(data.buffer.asUint8List(),
        targetWidth: width, targetHeight: height);
    ui.FrameInfo fi = await codec.getNextFrame();
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
    _progressSaveTimer?.cancel();
    _progressSaveTimer = null;
    _progressReady = false;
    _hideTextLoading();
    chapters = [];
    _diskChapterWarm.clear();
    loadOk = false;
    chaptersLoading = false;
    loadingHint = '正在加载…';
    widgets.clear();
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
    mPainter = null;
    canvasKey = null;
  }

  Future<void> reloadChapters() async {
    final b = book;
    if (b == null) return;
    chaptersLoading = true;
    loadingHint = '正在重新加载目录…';
    notifyListeners();

    try {
      final list = await reqChapters() ?? [];
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
      content = await getChapterContent(chapter.id, idx: b.chapterIndex);
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

  void reSetPages() {
    prePage = null;
    curPage = null;
    nextPage = null;
  }

  Future<void> downloadAll(int start) async {
    List<ChapterTocEntry> temp = chapters;
    if (temp.isEmpty) {
      await getChapters(init: true);
      temp = chapters;
    }
    List<ChapterNode> cpNodes = [];
    for (var i = start; i < temp.length; i++) {
      ChapterTocEntry chapter = temp[i];
      var id = chapter.id;
      if (chapter.hasBody == false) {
        String content = await getChapterContent(id, idx: i);
        if (content.isNotEmpty) {
          cpNodes.add(ChapterNode(content, id));
          chapter.hasBody = true;
        }
      }
      if (cpNodes.length % batchNum == 0) {
        await _chapters.updateBodies(cpNodes);
        cpNodes.clear();
      }
    }
    if (cpNodes.isNotEmpty) {
      await _chapters.updateBodies(cpNodes);
      cpNodes.clear();
    }
    BotToast.showText(text: "${book?.name ?? ""}下载完成");
  }

  Future<String> getChapterContent(String id, {int? idx}) async {
    final b = book;
    if (b == null) return '';
    await _ensureSource();
    final source = _activeSource;
    if (source == null) {
      return '书源不存在，请重新搜索添加或换源';
    }
    String chapterUrl = '';
    if (idx != null && idx >= 0 && idx < chapters.length) {
      chapterUrl = chapters[idx].url;
    } else {
      for (final c in chapters) {
        if (c.id == id) {
          chapterUrl = c.url;
          break;
        }
      }
    }
    if (chapterUrl.isEmpty) {
      return '章节地址为空，请重新加载目录';
    }
    try {
      AppLog.d('Read', 'fetch content idx=$idx url=$chapterUrl');
      final content = await _engine.content(source, chapterUrl);
      if (content.isEmpty) {
        AppLog.w('Read', 'empty content idx=$idx url=$chapterUrl');
        return '章节内容加载失败，请检查书源或换源后重试';
      }
      AppLog.d('Read', 'content ok idx=$idx len=${content.length}');
      return content;
    } catch (e, st) {
      AppLog.e('Read', 'content failed idx=$idx url=$chapterUrl',
          error: e, stackTrace: st);
      return '章节内容加载失败，请检查书源或换源后重试\n$e';
    }
  }

  /// Switch active source for the current book, remap progress, reload toc.
  Future<bool> switchSource(BookSource source, SearchBook hit) async {
    final b = book;
    if (b == null) return false;
    final oldName =
        (b.chapterIndex >= 0 && b.chapterIndex < chapters.length) ? chapters[b.chapterIndex].title : b.readingChapter;
    final oldIndex = b.chapterIndex;

    _showTextLoading('正在换源…');
    try {
      final info = await _engine.bookInfo(source, hit.bookUrl, seed: hit);
      final tocUrl = info.tocUrl.isNotEmpty ? info.tocUrl : hit.bookUrl;
      final toc = await _engine.toc(source, tocUrl);
      if (toc.isEmpty) {
        BotToast.showText(text: '目标书源目录为空');
        return false;
      }
      final mapped = ProgressMapper.map(
        oldName: oldName,
        oldIndex: oldIndex,
        newChapters: toc,
      );

      // Keep stable shelf id; only rebind source urls.
      b.sourceUrl = source.bookSourceUrl;
      b.bookUrl = hit.bookUrl;
      b.originName = source.bookSourceName;
      b.tocUrl = tocUrl;
      b.name = info.name.isNotEmpty ? info.name : b.name;
      b.author = info.author.isNotEmpty ? info.author : b.author;
      b.coverUrl = info.coverUrl.isNotEmpty ? info.coverUrl : b.coverUrl;
      b.description =
          info.description.isNotEmpty ? info.description : b.description;
      b.latestChapter = toc.last.name;
      b.chapterIndex = mapped;
      b.pageIndex = 0;
      b.scrollOffset = 0;
      _activeSource = source;

      // wipe chapter cache + page caches
      await _chapters.clearBook(b.id);
      _diskChapterWarm.clear();

      chapters = toc
          .map((c) => ChapterTocEntry(
                id: makeChapterId(b.id, c.url),
                title: c.name,
                url: c.url,
                hasBody: false,
                ord: c.index,
              ))
          .toList();
      // Always keep books/chapters in sync after source switch (FK-safe).
      await _ensureBookRow(b);
      await _chapters.replaceToc(chapters, b.id, sourceUrl: b.sourceUrl);
      await _books.updateSource(
        bookId: b.id,
        sourceUrl: b.sourceUrl,
        bookUrl: b.bookUrl,
        originName: b.originName,
        tocUrl: b.tocUrl,
      );
      final readName = (b.chapterIndex >= 0 && b.chapterIndex < chapters.length)
          ? chapters[b.chapterIndex].title
          : b.readingChapter;
      b.readingChapter = readName;
      await _books.saveProgress(
        bookId: b.id,
        chapterIndex: b.chapterIndex,
        pageIndex: b.pageIndex,
        scrollOffset: b.scrollOffset,
        readingChapter: readName,
      );

      reSetPages();
      widgets.clear();
      await initPageContent(b.chapterIndex, true);
      final name =
          (mapped >= 0 && mapped < chapters.length) ? chapters[mapped].title : '';
      BotToast.showText(text: '已切换至「${source.bookSourceName}」，定位到：$name');
      notifyListeners();
      return true;
    } catch (e) {
      BotToast.showText(text: '换源失败：$e');
      return false;
    } finally {
      _hideTextLoading();
    }
  }

  void switchClickNextPage() {
    leftClickNext = !leftClickNext;
    SpUtil.putBool("leftClickNext", leftClickNext);
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

  void changeCoverPage(Object? offsetDifference) {
    final b = book;
    if (b == null) return;
    final dir = (offsetDifference is num)
        ? offsetDifference.toDouble()
        : double.tryParse(offsetDifference?.toString() ?? '') ?? 0;
    final beforeCur = b.chapterIndex;
    final beforeIdx = b.pageIndex;
    int idx = b.pageIndex;

    int curLen = (curPage?.pageOffsets ?? 0);
    if (idx == curLen - 1 && dir > 0) {
      _refreshBattery();
      int tempCur = b.chapterIndex + 1;
      if (tempCur >= chapters.length) {
        BotToast.showText(text: "最后一页");
        return;
      }

      b.chapterIndex += 1;
      prePage = curPage;
      final following = nextPage;
      if (following == null || following.chapterName == "-1") {
        // Next chapter not ready yet — load it synchronously path.
        _showTextLoading('正在加载下一章…');
        loadChapter(b.chapterIndex).then((value) {
          if (book?.id == b.id) {
            curPage = value;
            final ro = canvasKey?.currentContext?.findRenderObject();
            ro?.markNeedsPaint();
            notifyListeners();
          }
          _hideTextLoading();
        });
      } else {
        curPage = following;
      }
      b.pageIndex = 0;
      nextPage = null;
      if (kDebugMode) {
        debugPrint(
          '[ReadModel] changeCoverPage +chapter '
          '$beforeCur:$beforeIdx → ${b.chapterIndex}:${b.pageIndex} '
          'dir=$offsetDifference pages=$curLen',
        );
      }
      _prunePictureCache();
      scheduleProgressSave();
      Future.delayed(const Duration(milliseconds: 500), () {
        if (book?.id == b.id) {
          loadChapter(b.chapterIndex + 1).then((value) {
            if (book?.id == b.id) nextPage = value;
          });
        }
      });
      return;
    }
    if (idx == 0 && dir < 0) {
      _refreshBattery();
      int tempCur = b.chapterIndex - 1;
      if (tempCur < 0) {
        BotToast.showText(text: "第一页");
        return;
      }
      final previous = prePage;
      if (previous == null) {
        // Previous chapter not ready — load it.
        _showTextLoading('正在加载上一章…');
        loadChapter(tempCur).then((value) {
          if (book?.id != b.id) {
            _hideTextLoading();
            return;
          }
          nextPage = curPage;
          curPage = value;
          b.chapterIndex = tempCur;
          b.pageIndex = (curPage?.pageOffsets ?? 1) - 1;
          prePage = null;
          final ro = canvasKey?.currentContext?.findRenderObject();
          ro?.markNeedsPaint();
          notifyListeners();
          _hideTextLoading();
          _prunePictureCache();
          scheduleProgressSave();
          loadChapter(b.chapterIndex - 1).then((v) {
            if (book?.id == b.id) prePage = v;
          });
        });
        return;
      }
      nextPage = curPage;
      curPage = previous;
      b.chapterIndex -= 1;
      b.pageIndex = (curPage?.pageOffsets ?? 1) - 1;
      notifyListeners();
      prePage = null;
      if (kDebugMode) {
        debugPrint(
          '[ReadModel] changeCoverPage -chapter '
          '$beforeCur:$beforeIdx → ${b.chapterIndex}:${b.pageIndex} '
          'dir=$offsetDifference',
        );
      }
      _prunePictureCache();
      scheduleProgressSave();
      Future.delayed(const Duration(milliseconds: 500), () {
        if (book?.id == b.id) {
          loadChapter(b.chapterIndex - 1).then((value) {
            if (book?.id == b.id) prePage = value;
          });
        }
      });
      return;
    }
    if (dir > 0) {
      b.pageIndex += 1;
    } else {
      b.pageIndex -= 1;
    }
    if (kDebugMode) {
      debugPrint(
        '[ReadModel] changeCoverPage page '
        '$beforeCur:$beforeIdx → ${b.chapterIndex}:${b.pageIndex} '
        'dir=$offsetDifference pages=$curLen',
      );
    }
    // Within-chapter page change: refresh picture + UI.
    canvasKey?.currentContext?.findRenderObject()?.markNeedsPaint();
    notifyListeners();
    scheduleProgressSave();
  }

  /// Drop in-memory pictures outside the nearby chapter window / hard cap.
  void _prunePictureCache() {
    final b = book;
    if (b == null || widgets.isEmpty) return;
    final id = b.id.toString();
    final keepCur = {b.chapterIndex - 1, b.chapterIndex, b.chapterIndex + 1};
    widgets.removeWhere((key, _) {
      if (!key.startsWith(id)) return true;
      // key = id + cur + pageIndex (concatenated ints, ambiguous but best-effort)
      final rest = key.substring(id.length);
      // Prefer keeping anything that starts with nearby cur as prefix digits.
      for (final c in keepCur) {
        if (c < 0) continue;
        if (rest.startsWith('$c')) return false;
      }
      return true;
    });
    if (widgets.length > _maxPictureCache) {
      final keys = widgets.keys.toList();
      final drop = keys.length - _maxPictureCache;
      for (var i = 0; i < drop; i++) {
        widgets.remove(keys[i]);
      }
    }
  }

  bool isCanGoNext() {
    final b = book;
    if (b == null) return false;
    // Last chapter, last page.
    if (b.chapterIndex >= chapters.length - 1 &&
        b.pageIndex >= ((curPage?.pageOffsets ?? 1) - 1)) {
      return false;
    }
    // Prefer pre-rendered picture, but allow turn if logical next exists.
    if (next() != null) return true;
    // Next page within chapter, or next chapter available.
    if (b.pageIndex + 1 < (curPage?.pageOffsets ?? 0)) return true;
    return b.chapterIndex + 1 < chapters.length;
  }

  bool isCanGoPre() {
    final b = book;
    if (b == null) return false;
    if (b.chapterIndex <= 0 && b.pageIndex <= 0) return false;
    if (pre() != null) return true;
    if (b.pageIndex > 0) return true;
    return b.chapterIndex > 0;
  }

  Future<void> changeBgUI() async {
    paperTheme = ReadSetting.getPaperTheme();
    // Solid paper mode: no texture image.
    if (ReadSetting.useSolidPaper()) {
      bgUI = null;
      return;
    }
    if (SpUtil.getBool("dark") || paperTheme == PaperTheme.night) {
      bgUI = await getAssetImage("images/${ReadSetting.bgImg.last}",
          width: Screen.width.ceil(), height: Screen.height.ceil());
    } else {
      bgUI = await getAssetImage("images/$bgPath",
          width: Screen.width.ceil(), height: Screen.height.ceil());
    }
  }
}
