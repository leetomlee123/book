import 'package:book/data/repositories/book_repository.dart';
import 'package:book/data/repositories/chapter_repository.dart';
import 'package:book/entity/Book.dart';
import 'package:book/entity/ChapterNode.dart';
import 'package:book/entity/LocalChapter.dart';

/// Compatibility facade over [BookRepository] / [ChapterRepository].
///
/// Prefer repositories for new code. This class keeps existing call sites
/// working while the architecture migrates off dual-file SQLite.
class DbHelper {
  DbHelper._();
  static final DbHelper instance = DbHelper._();

  final BookRepository _books = BookRepository.instance;
  final ChapterRepository _chapters = ChapterRepository.instance;

  Future<List<Book>> getBooks() => _books.getAll();

  Future<Book?> getBook(String bookId) => _books.getById(bookId);

  Future<void> addBooks(List<Book> books) => _books.upsertAll(books);

  Future<void> delBook(String bookId) => _books.delete(bookId);

  Future<void> delBookAndCps(String bookId) => _books.delete(bookId);

  Future<void> sortBook(String bookId) => _books.touchSortTime(bookId);

  Future<int> updBookProcess(
    int cur,
    int idx,
    double position,
    String bookId, {
    String? readingChapter,
  }) {
    return _books.saveProgress(
      bookId: bookId,
      chapterIndex: cur,
      pageIndex: idx,
      scrollOffset: position,
      readingChapter: readingChapter,
    );
  }

  Future<void> updBookSource(
    String sourceUrl,
    String bookUrl,
    String originName,
    String tocUrl,
    String bookId,
  ) {
    return _books.updateSource(
      bookId: bookId,
      sourceUrl: sourceUrl,
      bookUrl: bookUrl,
      originName: originName,
      tocUrl: tocUrl,
    );
  }

  Future<void> updBook(
    String lastChapter,
    int newStatus,
    String utime,
    String img,
    String bookId,
  ) {
    return _books.updateLatestChapter(
      bookId: bookId,
      latestChapter: lastChapter,
      hasUpdate: newStatus,
      updatedAt: utime,
      coverUrl: img,
    );
  }

  Future<void> updBookStatus(String bookId, int s) {
    return _books.setHasUpdate(bookId, s);
  }

  Future<List<LocalChapter>> getChapters(String bookId) =>
      _chapters.getToc(bookId);

  Future<int> getChaptersLen(String bookId) => _chapters.count(bookId);

  Future<void> clearChapters(String bookId) => _chapters.clearBook(bookId);

  Future<void> addChapters(
    List<LocalChapter> chapters,
    String bookId, {
    String sourceUrl = '',
  }) async {
    final len = await _chapters.count(bookId);
    if (len == 0) {
      await _chapters.replaceToc(chapters, bookId, sourceUrl: sourceUrl);
    } else {
      await _chapters.appendToc(chapters, bookId, sourceUrl: sourceUrl);
    }
  }

  Future<String> getContent(String chapterId) => _chapters.getBody(chapterId);

  Future<bool> getHasContent(String chapterId) => _chapters.hasBody(chapterId);

  Future<void> udpChapter(List<ChapterNode> nodes) =>
      _chapters.updateBodies(nodes);

  Future<({String? pagesJson, String? layoutFp})> getChapterPages(
          String chapterId) =>
      _chapters.getPageLayout(chapterId);

  Future<void> saveChapterPages(
    String chapterId,
    String pagesJson,
    String layoutFp,
  ) =>
      _chapters.savePageLayout(chapterId, pagesJson, layoutFp);

  Future<void> clearChapterPages(String chapterId) =>
      _chapters.clearPageLayout(chapterId);

  Future<int> clearStalePageCache({String? keepLayoutFp}) =>
      _chapters.clearAllPageLayouts(keepLayoutFp: keepLayoutFp);

  Future<int> pageCacheBytes() => _chapters.pageCacheBytes();

  Future<int> evictPageCache({
    required int maxBytes,
    String? protectBookId,
    int protectCenterIdx = 0,
    int protectRadius = 30,
  }) {
    return _chapters.evictPageCache(
      maxBytes: maxBytes,
      protectBookId: protectBookId,
      protectCenterIdx: protectCenterIdx,
      protectRadius: protectRadius,
    );
  }

  Future closeChapter() async {}
  Future closeBook() async {}
}
