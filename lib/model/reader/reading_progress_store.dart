import 'dart:async';

import 'package:book/common/app_log.dart';
import 'package:book/data/repositories/book_repository.dart';
import 'package:book/data/repositories/chapter_repository.dart';
import 'package:book/entity/book.dart';
import 'package:book/entity/chapter_toc_entry.dart';

/// Debounced reading-progress persistence for the active book.
class ReadingProgressStore {
  ReadingProgressStore({
    required this.books,
    required this.chapters,
    required this.ensureBookRow,
  });

  final BookRepository books;
  final ChapterRepository chapters;
  final Future<void> Function(Book book) ensureBookRow;

  BookRepository get _books => books;
  ChapterRepository get _chapters => chapters;
  Future<void> Function(Book book) get _ensureBookRow => ensureBookRow;

  static const debounce = Duration(milliseconds: 800);

  Timer? _timer;

  /// When false, schedule/save become no-ops (e.g. user declined shelf add).
  bool enabled = true;

  /// Gate until hydrate finished; prevents route-stale zeros overwriting DB.
  bool ready = false;

  void cancel() {
    _timer?.cancel();
    _timer = null;
  }

  void schedule({
    required Book? book,
    required List<ChapterTocEntry> chapters,
    Duration delay = debounce,
  }) {
    if (!enabled || book == null || !ready) return;
    _timer?.cancel();
    if (delay == Duration.zero) {
      unawaited(save(book: book, chapters: chapters));
      return;
    }
    _timer = Timer(delay, () {
      unawaited(save(book: book, chapters: chapters));
    });
  }

  Future<void> flush({
    required Book? book,
    required List<ChapterTocEntry> chapters,
  }) {
    cancel();
    return save(book: book, chapters: chapters);
  }

  Future<void> save({
    required Book? book,
    required List<ChapterTocEntry> chapters,
  }) async {
    if (!enabled) return;
    if (!ready) {
      AppLog.i('Read', 'skip progress save (not hydrated yet)');
      return;
    }
    final b = book;
    if (b == null) return;
    cancel();

    final cur = b.chapterIndex;
    final idx = b.pageIndex;
    final pos = b.scrollOffset;
    final id = b.id;
    final sourceUrl = b.sourceUrl;
    final tocSnapshot = chapters.isNotEmpty
        ? List<ChapterTocEntry>.from(chapters)
        : const <ChapterTocEntry>[];
    final name = (cur >= 0 && cur < tocSnapshot.length)
        ? tocSnapshot[cur].title
        : b.readingChapter;
    if (name.isNotEmpty && name != '加载中') {
      b.readingChapter = name;
    }
    final chapterName =
        (b.readingChapter.isNotEmpty && b.readingChapter != '加载中')
            ? b.readingChapter
            : name;

    await _ensureBookRow(b);
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

    final updated = await _books.saveProgress(
      bookId: id,
      chapterIndex: cur,
      pageIndex: idx,
      scrollOffset: pos,
      readingChapter: chapterName,
    );
    if (updated == 0) {
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
}
