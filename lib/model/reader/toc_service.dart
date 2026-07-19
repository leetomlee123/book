import 'package:book/common/app_log.dart';
import 'package:book/data/repositories/chapter_repository.dart';
import 'package:book/entity/book.dart';
import 'package:book/entity/chapter_toc_entry.dart';
import 'package:book/source/engine/book_source_engine.dart';
import 'package:book/source/model/book_source.dart';
import 'package:book/source/util/book_id.dart';
import 'package:bot_toast/bot_toast.dart';

/// Remote TOC fetch + local catalog persistence for the active book.
class TocService {
  TocService({
    required this.engine,
    required this.chapters,
    required this.ensureBookRow,
    required this.resolveSource,
  });

  final BookSourceEngine engine;
  final ChapterRepository chapters;
  final Future<void> Function(Book book) ensureBookRow;
  final Future<BookSource?> Function(Book book) resolveSource;

  /// Fetch TOC from the active book source.
  Future<List<ChapterTocEntry>?> fetchRemote(Book book) async {
    final source = await resolveSource(book);
    if (source == null) {
      BotToast.showText(text: '书源不存在：${book.originName}');
      return null;
    }
    final tocUrl = book.tocUrl.isNotEmpty
        ? book.tocUrl
        : (book.bookUrl.isNotEmpty ? book.bookUrl : '');
    if (tocUrl.isEmpty) return null;
    try {
      AppLog.i(
        'Read',
        'fetchRemoteToc source=${source.bookSourceName} '
            'tocUrl=$tocUrl chapterList=${source.ruleToc.chapterList}',
      );
      final list = await engine.toc(source, tocUrl);
      AppLog.i('Read', 'fetchRemoteToc got ${list.length} chapters');
      return list
          .map(
            (c) => ChapterTocEntry(
              id: makeChapterId(book.id, c.url),
              title: c.name,
              url: c.url,
              hasBody: false,
              ord: c.index,
            ),
          )
          .toList();
    } catch (e, st) {
      AppLog.e(
        'Read',
        'fetchRemoteToc failed for $tocUrl',
        error: e,
        stackTrace: st,
      );
      BotToast.showText(text: '目录加载失败：$e');
      return null;
    }
  }

  /// Merge remote TOC into local state + DB.
  ///
  /// Returns the updated in-memory chapter list, or null if nothing changed /
  /// fetch failed / stale book.
  Future<List<ChapterTocEntry>?> load({
    required Book book,
    required List<ChapterTocEntry> current,
    required bool init,
    required bool Function() isStillActive,
  }) async {
    final bookId = book.id;
    final list = await fetchRemote(book);
    if (list == null || list.isEmpty) return null;
    if (!isStillActive()) {
      AppLog.i('Read', 'loadToc drop stale toc for $bookId');
      return null;
    }

    await ensureBookRow(book);
    if (!isStillActive()) return null;

    if (init || current.isEmpty) {
      await chapters.syncToc(list, bookId, sourceUrl: book.sourceUrl);
      AppLog.i('Read', 'toc saved init=${list.length} id=$bookId');
      return list;
    }

    final existing = current.map((e) => e.url).toSet();
    final fresh = list.where((e) => !existing.contains(e.url)).toList();
    if (fresh.isEmpty) return current;
    for (final c in fresh) {
      c.ord = current.length;
      current.add(c);
    }
    await chapters.appendToc(fresh, bookId, sourceUrl: book.sourceUrl);
    AppLog.i('Read', 'toc append ${fresh.length} id=$bookId');
    return current;
  }
}
