import 'package:battery_plus/battery_plus.dart';
import 'package:book/common/app_log.dart';
import 'package:book/data/repositories/book_repository.dart';
import 'package:book/data/repositories/chapter_repository.dart';
import 'package:book/entity/book.dart';
import 'package:book/entity/chapter_toc_entry.dart';
import 'package:book/entity/read_page.dart';
import 'package:book/source/model/book_source.dart';
import 'package:bot_toast/bot_toast.dart';

/// Opens / hydrates a reading session: DB progress, TOC, first chapter.
class ReadingSessionOpener {
  ReadingSessionOpener({
    required this.books,
    required this.chapters,
    required this.ensureSource,
    required this.activeSourceOf,
    required this.loadToc,
    required this.openChapterAt,
    required this.hasPageCache,
    required this.restorePageIndex,
    required this.messagePage,
    required this.showLoading,
    required this.bookOf,
    required this.setBook,
    required this.chaptersOf,
    required this.setChapters,
    required this.curPageOf,
    required this.setCurPage,
    required this.setElectricQuantity,
    required this.setShowMenu,
    required this.setChaptersLoading,
    required this.setLoadingHint,
    required this.loadingHintOf,
    required this.setAllowProgressSave,
    required this.setSessionReady,
    required this.setProgressReady,
    required this.notify,
  });

  final BookRepository books;
  final ChapterRepository chapters;
  final Future<void> Function() ensureSource;
  final BookSource? Function() activeSourceOf;
  final Future Function({bool init}) loadToc;
  final Future Function(int idx, bool jump, {bool showLoading}) openChapterAt;
  final Future<bool> Function(int idx) hasPageCache;
  final void Function(int savedIndex) restorePageIndex;
  final Future<ReadPage> Function(String title, String message) messagePage;
  final Future<void> Function(String text) showLoading;
  final Book? Function() bookOf;
  final void Function(Book? book) setBook;
  final List<ChapterTocEntry> Function() chaptersOf;
  final void Function(List<ChapterTocEntry> chapters) setChapters;
  final ReadPage? Function() curPageOf;
  final void Function(ReadPage? page) setCurPage;
  final void Function(double value) setElectricQuantity;
  final void Function(bool value) setShowMenu;
  final void Function(bool value) setChaptersLoading;
  final void Function(String value) setLoadingHint;
  final String Function() loadingHintOf;
  final void Function(bool value) setAllowProgressSave;
  final void Function(bool value) setSessionReady;
  final void Function(bool value) setProgressReady;
  final void Function() notify;

  Future<void> hydrate() async {
    try {
      setElectricQuantity((await Battery().batteryLevel) / 100);
    } catch (e) {
      AppLog.w('Read', 'batteryLevel failed', error: e);
      setElectricQuantity(1.0);
    }
    setShowMenu(false);
    setChaptersLoading(true);
    final hint = loadingHintOf();
    setLoadingHint(hint.isEmpty ? '正在加载…' : hint);
    setAllowProgressSave(true);

    final b = bookOf();
    if (b == null) {
      AppLog.w('Read', 'hydrateReadingSession: book is null');
      setChaptersLoading(false);
      return;
    }

    var savedCur = b.chapterIndex;
    var savedIndex = b.pageIndex;
    try {
      final dbBook = await books.getById(b.id);
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

    if (curPageOf() == null || curPageOf()!.chapterName != '加载中') {
      setCurPage(await messagePage('加载中', loadingHintOf()));
      notify();
    }

    AppLog.i(
      'Read',
      'open id=${b.id} name=${b.name} cur=$savedCur index=$savedIndex '
          'source=${b.originName} sourceUrl=${b.sourceUrl} bookUrl=${b.bookUrl}',
    );

    if (b.sourceUrl.isEmpty || b.bookUrl.isEmpty) {
      AppLog.w('Read', 'missing sourceUrl/bookUrl for ${b.id}');
      BotToast.showText(text: '旧版云端书籍无法继续阅读，请重新搜索添加');
      setCurPage(await messagePage(
        '无法阅读',
        '旧版云端书籍缺少书源信息，请重新搜索添加后再阅读。',
      ));
      b.chapterIndex = savedCur < 0 ? 0 : savedCur;
      b.pageIndex = savedIndex < 0 ? 0 : savedIndex;
      setSessionReady(true);
      setChaptersLoading(false);
      setProgressReady(false);
      notify();
      return;
    }

    await showLoading('正在准备书源…');
    b.chapterIndex = savedCur;
    b.pageIndex = savedIndex;
    await ensureSource();
    if (activeSourceOf() == null) {
      AppLog.e('Read', 'source not found: ${b.sourceUrl} (${b.originName})');
      BotToast.showText(text: '书源不存在：${b.originName}');
      setCurPage(await messagePage(
        '书源不可用',
        '未找到书源「${b.originName}」，请在书源管理中导入对应书源，或在阅读菜单中换源。',
      ));
      b.chapterIndex = savedCur < 0 ? 0 : savedCur;
      b.pageIndex = savedIndex < 0 ? 0 : savedIndex;
      setSessionReady(true);
      setChaptersLoading(false);
      setProgressReady(false);
      notify();
      return;
    }

    await showLoading('正在读取本地目录…');
    b.chapterIndex = savedCur;
    b.pageIndex = savedIndex;
    final localToc = await chapters.getToc(b.id);
    setChapters(localToc);
    AppLog.i('Read', 'local chapters=${localToc.length}');

    if (localToc.isNotEmpty) {
      loadToc();
      if (savedCur < 0 || savedCur >= localToc.length) {
        AppLog.w(
          'Read',
          'clamp cur $savedCur -> 0 (len=${localToc.length})',
        );
        b.chapterIndex = 0;
      } else {
        b.chapterIndex = savedCur;
      }
      b.pageIndex = savedIndex < 0 ? 0 : savedIndex;
      final canSkipLoading = await hasPageCache(b.chapterIndex);
      await openChapterAt(
        b.chapterIndex,
        false,
        showLoading: !canSkipLoading,
      );
      restorePageIndex(savedIndex);
      setSessionReady(true);
      setChaptersLoading(false);
      setProgressReady(true);
      AppLog.i(
        'Read',
        'ready cur=${b.chapterIndex} index=${b.pageIndex} '
            'pages=${curPageOf()?.pageOffsets} '
            'contentLen=${curPageOf()?.chapterContent.length}',
      );
      notify();
    } else {
      await showLoading('正在获取章节目录…');
      b.chapterIndex = savedCur;
      b.pageIndex = savedIndex;
      await loadToc(init: true);
      final toc = chaptersOf();
      AppLog.i('Read', 'fetched toc chapters=${toc.length}');
      if (toc.isEmpty) {
        AppLog.e('Read', 'toc empty after fetch for ${b.bookUrl}');
        setCurPage(await messagePage(
          '目录为空',
          '未能获取章节目录，请检查书源规则、网络，或尝试换源。',
        ));
        b.chapterIndex = savedCur < 0 ? 0 : savedCur;
        b.pageIndex = savedIndex < 0 ? 0 : savedIndex;
      } else {
        if (savedCur < 0 || savedCur >= toc.length) {
          b.chapterIndex = 0;
        } else {
          b.chapterIndex = savedCur;
        }
        b.pageIndex = savedIndex < 0 ? 0 : savedIndex;
        await openChapterAt(b.chapterIndex, false, showLoading: true);
        restorePageIndex(savedIndex);
      }
      setSessionReady(true);
      setChaptersLoading(false);
      setProgressReady(true);
      notify();
    }
  }
}
