import 'package:book/entity/book.dart';
import 'package:book/entity/chapter_toc_entry.dart';
import 'package:book/model/reader/chapter_download_service.dart';
import 'package:book/model/reader/source_switch_service.dart';
import 'package:book/model/source_model.dart';
import 'package:book/source/model/book_source.dart';
import 'package:book/source/model/search_book.dart';
import 'package:bot_toast/bot_toast.dart';

/// Active book source resolution + download / switch orchestration.
class ReaderSourceCoordinator {
  ReaderSourceCoordinator({
    required this.downloads,
    required this.sourceSwitch,
    required this.bookOf,
    required this.chaptersOf,
    required this.setChapters,
    required this.clearDiskWarm,
    required this.resetPages,
    required this.clearPictures,
    required this.openChapterAt,
    required this.showLoading,
    required this.hideLoading,
    required this.loadToc,
    required this.notify,
  });

  final ChapterDownloadService downloads;
  final SourceSwitchService sourceSwitch;
  final Book? Function() bookOf;
  final List<ChapterTocEntry> Function() chaptersOf;
  final void Function(List<ChapterTocEntry> chapters) setChapters;
  final void Function() clearDiskWarm;
  final void Function() resetPages;
  final void Function() clearPictures;
  final Future Function(int idx, bool jump, {bool showLoading}) openChapterAt;
  final Future<void> Function(String text) showLoading;
  final void Function() hideLoading;
  final Future Function({bool init}) loadToc;
  final void Function() notify;

  BookSource? activeSource;

  Future<void> ensureSource() async {
    final b = bookOf();
    if (b == null) return;
    if (activeSource != null &&
        activeSource!.bookSourceUrl == b.sourceUrl) {
      return;
    }
    activeSource = await SourceModel().findByUrl(b.sourceUrl);
  }

  Future<String> fetchChapterBody(String id, {int? idx}) async {
    if (bookOf() == null) return '';
    await ensureSource();
    return downloads.fetchBody(
      source: activeSource,
      toc: chaptersOf(),
      chapterId: id,
      idx: idx,
    );
  }

  Future<void> downloadAll(int start) async {
    if (chaptersOf().isEmpty) {
      await loadToc(init: true);
    }
    await ensureSource();
    await downloads.downloadFrom(
      toc: chaptersOf(),
      start: start,
      source: activeSource,
      bookName: bookOf()?.name ?? '',
      batchSize: 100,
    );
  }

  /// Switch active source for the current book, remap progress, reload toc.
  ///
  /// When there is no active reading session (e.g. book detail page), only
  /// rewrites book metadata / TOC in DB — does not open a chapter window.
  Future<bool> switchSource(BookSource source, SearchBook hit) async {
    final b = bookOf();
    if (b == null) return false;
    final chapters = chaptersOf();
    final oldName = (b.chapterIndex >= 0 && b.chapterIndex < chapters.length)
        ? chapters[b.chapterIndex].title
        : b.readingChapter;
    final oldIndex = b.chapterIndex;
    // Detail page sets book without hydrating a session — skip chapter open.
    final hasSession = chapters.isNotEmpty;

    await showLoading('正在换源…');
    try {
      final result = await sourceSwitch.switchTo(
        book: b,
        source: source,
        hit: hit,
        oldChapterName: oldName,
        oldChapterIndex: oldIndex,
      );
      if (result == null) return false;

      activeSource = result.source;
      setChapters(result.chapters);
      clearDiskWarm();
      resetPages();
      clearPictures();
      if (hasSession) {
        await openChapterAt(b.chapterIndex, true);
        final mapped = result.mappedChapterIndex;
        final updated = chaptersOf();
        final name = (mapped >= 0 && mapped < updated.length)
            ? updated[mapped].title
            : '';
        BotToast.showText(
          text: '已切换至「${source.bookSourceName}」，定位到：$name',
        );
      } else {
        BotToast.showText(
          text: '已切换至「${source.bookSourceName}」',
        );
      }
      notify();
      return true;
    } finally {
      hideLoading();
    }
  }
}
