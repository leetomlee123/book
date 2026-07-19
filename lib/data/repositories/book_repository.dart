import 'package:book/common/local_store.dart';
import 'package:book/data/db/reader_database.dart';
import 'package:book/entity/Book.dart';
import 'package:sqflite/sqflite.dart';

/// Shelf + reading progress persistence.
class BookRepository {
  BookRepository({ReaderDatabase? db}) : _db = db ?? ReaderDatabase.instance;

  final ReaderDatabase _db;

  static final BookRepository instance = BookRepository();

  Future<Database> get _database => _db.database;

  Future<List<Book>> getAll() async {
    final db = await _database;
    final rows = await db.query('books', orderBy: 'sort_time DESC');
    return rows.map(_fromRow).toList();
  }

  Future<Book?> getById(String id) async {
    final db = await _database;
    final rows = await db.query('books', where: 'id = ?', whereArgs: [id]);
    if (rows.isEmpty) return null;
    return _fromRow(rows.first);
  }

  Future<bool> exists(String id) async {
    final db = await _database;
    final rows = await db.rawQuery(
      'SELECT 1 AS ok FROM books WHERE id = ? LIMIT 1',
      [id],
    );
    return rows.isNotEmpty;
  }

  Future<void> upsert(Book book) async {
    final db = await _database;
    await db.insert(
      'books',
      _toRow(book),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> upsertAll(List<Book> books) async {
    if (books.isEmpty) return;
    final db = await _database;
    final batch = db.batch();
    for (final b in books) {
      batch.insert(
        'books',
        _toRow(b),
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    await batch.commit(noResult: true);
  }

  /// Insert only if missing (first open / race).
  Future<void> ensureExists(Book book) async {
    if (await exists(book.id)) return;
    final db = await _database;
    await db.insert(
      'books',
      _toRow(book),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );
  }

  Future<int> saveProgress({
    required String bookId,
    required int chapterIndex,
    required int pageIndex,
    double scrollOffset = 0,
    String? readingChapter,
  }) async {
    final db = await _database;
    final values = <String, Object?>{
      'chapter_index': chapterIndex,
      'page_index': pageIndex,
      'scroll_offset': scrollOffset,
    };
    if (readingChapter != null) {
      values['reading_chapter'] = readingChapter;
    }
    return db.update('books', values, where: 'id = ?', whereArgs: [bookId]);
  }

  Future<void> updateSource({
    required String bookId,
    required String sourceUrl,
    required String bookUrl,
    required String originName,
    required String tocUrl,
  }) async {
    final db = await _database;
    await db.update(
      'books',
      {
        'source_url': sourceUrl,
        'book_url': bookUrl,
        'origin_name': originName,
        'toc_url': tocUrl,
      },
      where: 'id = ?',
      whereArgs: [bookId],
    );
  }

  Future<void> updateLatestChapter({
    required String bookId,
    String? latestChapter,
    int? hasUpdate,
    String? updatedAt,
    String? coverUrl,
  }) async {
    final db = await _database;
    final values = <String, Object?>{};
    if (latestChapter != null) values['latest_chapter'] = latestChapter;
    if (hasUpdate != null) values['has_update'] = hasUpdate;
    if (updatedAt != null) values['updated_at'] = updatedAt;
    if (coverUrl != null) values['cover_url'] = coverUrl;
    if (values.isEmpty) return;
    await db.update(
      'books',
      values,
      where: 'id = ?',
      whereArgs: [bookId],
    );
  }

  Future<void> setHasUpdate(String bookId, int hasUpdate) async {
    final db = await _database;
    await db.update(
      'books',
      {'has_update': hasUpdate},
      where: 'id = ?',
      whereArgs: [bookId],
    );
  }

  Future<void> touchSortTime(String bookId) async {
    final db = await _database;
    await db.update(
      'books',
      {
        'sort_time': DateUtil.getNowDateMs(),
        'has_update': 0,
      },
      where: 'id = ?',
      whereArgs: [bookId],
    );
  }

  Future<void> delete(String bookId) async {
    final db = await _database;
    // chapters cascade via FK if enabled; also explicit for safety.
    await db.delete('chapters', where: 'book_id = ?', whereArgs: [bookId]);
    await db.delete('books', where: 'id = ?', whereArgs: [bookId]);
  }

  Book _fromRow(Map<String, Object?> row) {
    String s(Object? v) {
      if (v == null) return '';
      final t = v.toString();
      return t == 'null' ? '' : t;
    }

    final latest = s(row['latest_chapter']);
    final reading = s(row['reading_chapter']);
    return Book(
      id: s(row['id']),
      name: s(row['name']),
      author: s(row['author']),
      coverUrl: s(row['cover_url']),
      category: s(row['category']),
      description: s(row['description']),
      readingChapter: reading.isNotEmpty ? reading : latest,
      latestChapter: latest,
      chapterIndex: row['chapter_index'] as int? ?? 0,
      pageIndex: row['page_index'] as int? ?? 0,
      scrollOffset: (row['scroll_offset'] as num?)?.toDouble() ?? 0,
      sortTime: row['sort_time'] as int? ?? 0,
      hasUpdate: row['has_update'] as int? ?? 0,
      updatedAt: s(row['updated_at']),
      sourceUrl: s(row['source_url']),
      bookUrl: s(row['book_url']),
      originName: s(row['origin_name']),
      tocUrl: s(row['toc_url']),
    );
  }

  Map<String, Object?> _toRow(Book book) {
    return {
      'id': book.id,
      'name': book.name,
      'author': book.author,
      'cover_url': book.coverUrl,
      'category': book.category,
      'description': book.description,
      'source_url': book.sourceUrl,
      'book_url': book.bookUrl,
      'origin_name': book.originName,
      'toc_url': book.tocUrl,
      'chapter_index': book.chapterIndex,
      'page_index': book.pageIndex,
      'scroll_offset': book.scrollOffset,
      'reading_chapter': book.readingChapter,
      'latest_chapter': book.latestChapter.isNotEmpty
          ? book.latestChapter
          : book.readingChapter,
      'sort_time':
          book.sortTime == 0 ? DateUtil.getNowDateMs() : book.sortTime,
      'has_update': book.hasUpdate,
      'updated_at': book.updatedAt,
    };
  }
}
