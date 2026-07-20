import 'package:book/common/app_log.dart';
import 'package:book/data/repositories/book_repository.dart';
import 'package:book/data/repositories/chapter_repository.dart';
import 'package:book/entity/book.dart';
import 'package:book/entity/chapter_toc_entry.dart';
import 'package:book/source/engine/book_source_engine.dart';
import 'package:book/source/engine/progress_mapper.dart';
import 'package:book/source/model/book_source.dart';
import 'package:book/source/model/search_book.dart';
import 'package:book/source/util/book_id.dart';
import 'package:bot_toast/bot_toast.dart';

/// Result of a successful source switch (caller reloads pages).
class SourceSwitchResult {
  SourceSwitchResult({
    required this.chapters,
    required this.mappedChapterIndex,
    required this.source,
  });

  final List<ChapterTocEntry> chapters;
  final int mappedChapterIndex;
  final BookSource source;
}

/// Switches the active book source, remaps progress, and rewrites TOC rows.
class SourceSwitchService {
  SourceSwitchService({
    required this.engine,
    required this.books,
    required this.chapters,
    required this.ensureBookRow,
  });

  final BookSourceEngine engine;
  final BookRepository books;
  final ChapterRepository chapters;
  final Future<void> Function(Book book) ensureBookRow;

  /// Applies source switch to [book] in place. Returns null on failure.
  Future<SourceSwitchResult?> switchTo({
    required Book book,
    required BookSource source,
    required SearchBook hit,
    required String oldChapterName,
    required int oldChapterIndex,
  }) async {
    try {
      final info = await engine.bookInfo(source, hit.bookUrl, seed: hit);
      final tocUrl = info.tocUrl.isNotEmpty ? info.tocUrl : hit.bookUrl;
      final toc = await engine.toc(source, tocUrl);
      if (toc.isEmpty) {
        BotToast.showText(text: '目标书源目录为空');
        return null;
      }
      final mapped = ProgressMapper.map(
        oldName: oldChapterName,
        oldIndex: oldChapterIndex,
        newChapters: toc,
      );

      book.sourceUrl = source.bookSourceUrl;
      book.bookUrl = hit.bookUrl;
      book.originName = source.bookSourceName;
      book.tocUrl = tocUrl;
      book.name = info.name.isNotEmpty ? info.name : book.name;
      book.author = info.author.isNotEmpty ? info.author : book.author;
      book.coverUrl = info.coverUrl.isNotEmpty ? info.coverUrl : book.coverUrl;
      book.description =
          info.description.isNotEmpty ? info.description : book.description;
      book.latestChapter = toc.last.name;
      book.chapterIndex = mapped;
      book.pageIndex = 0;
      book.scrollOffset = 0;

      await chapters.clearBook(book.id);

      final tocEntries = toc
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

      await ensureBookRow(book);
      await chapters.replaceToc(
        tocEntries,
        book.id,
        sourceUrl: book.sourceUrl,
      );
      await books.updateSource(
        bookId: book.id,
        sourceUrl: book.sourceUrl,
        bookUrl: book.bookUrl,
        originName: book.originName,
        tocUrl: book.tocUrl,
      );
      final readName =
          (book.chapterIndex >= 0 && book.chapterIndex < tocEntries.length)
              ? tocEntries[book.chapterIndex].title
              : book.readingChapter;
      book.readingChapter = readName;
      await books.saveProgress(
        bookId: book.id,
        chapterIndex: book.chapterIndex,
        pageIndex: book.pageIndex,
        scrollOffset: book.scrollOffset,
        readingChapter: readName,
      );

      AppLog.i(
        'Read',
        'source switched to ${source.bookSourceName} mapped=$mapped',
      );
      return SourceSwitchResult(
        chapters: tocEntries,
        mappedChapterIndex: mapped,
        source: source,
      );
    } catch (e, st) {
      AppLog.e('Read', 'switchSource failed', error: e, stackTrace: st);
      BotToast.showText(text: '换源失败：$e');
      return null;
    }
  }
}
