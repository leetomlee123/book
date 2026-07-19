import 'dart:io';

import 'package:book/entity/Book.dart';
import 'package:book/entity/ChapterNode.dart';
import 'package:book/entity/LocalChapter.dart';
import 'package:book/common/local_store.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DbHelper {
  static final DbHelper _dbHelper = DbHelper();
  static DbHelper instance = _dbHelper;
  final String _tableName = "chapters";
  final String _tableName1 = "books";

  static Database? _db;
  static Database? _db1;
  int version = 5;

  Future<Database> get db async {
    if (_db != null) {
      return _db!;
    }
    _db = await _initDb();

    return _db!;
  }

  Future<Database> get db1 async {
    if (_db1 != null) return _db1!;
    _db1 = await _initDb1();
    return _db1!;
  }

  Future<Database> _initDb1() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();

    String path = "${documentsDirectory.path}/books.db";
    var db = await openDatabase(path,
        version: version, onCreate: _onCreate1, onUpgrade: _onUpgradeBooks);
    return db;
  }

  Future<Database> _initDb() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();

    String path = "${documentsDirectory.path}/chapters.db";
    var db = await openDatabase(path,
        version: version, onCreate: _onCreate, onUpgrade: _onUpgradeChapters);
    return db;
  }

  void _onCreate(Database db, int version) async {
    await db.execute("CREATE TABLE IF NOT EXISTS $_tableName("
        "id INTEGER PRIMARY KEY AUTOINCREMENT,"
        "chapter_id TEXT,"
        "name TEXT,"
        "content TEXT,"
        "book_id TEXT,"
        "hasContent INTEGER,"
        "url TEXT,"
        "source_url TEXT,"
        "idx INTEGER,"
        "book_key TEXT,"
        "pages_json TEXT,"
        "layout_fp TEXT,"
        "pages_cached_at INTEGER,"
        "content_len INTEGER)");
    await db.execute("CREATE INDEX IF NOT EXISTS book_id_idx ON $_tableName (book_id);");
    await db
        .execute("CREATE INDEX IF NOT EXISTS chapter_id_idx ON $_tableName (chapter_id);");
    await db.execute("CREATE INDEX IF NOT EXISTS chapters_url_idx ON $_tableName (url);");
    SpUtil.putString(_tableName, "");
  }

  Future<void> _onUpgradeChapters(Database db, int oldV, int newV) async {
    if (oldV < 4) {
      await _tryAddColumn(db, _tableName, 'url', 'TEXT');
      await _tryAddColumn(db, _tableName, 'source_url', 'TEXT');
      await _tryAddColumn(db, _tableName, 'idx', 'INTEGER');
      await _tryAddColumn(db, _tableName, 'book_key', 'TEXT');
      await db.execute(
          "CREATE INDEX IF NOT EXISTS chapters_url_idx ON $_tableName (url)");
    }
    if (oldV < 5) {
      await _tryAddColumn(db, _tableName, 'pages_json', 'TEXT');
      await _tryAddColumn(db, _tableName, 'layout_fp', 'TEXT');
      await _tryAddColumn(db, _tableName, 'pages_cached_at', 'INTEGER');
      await _tryAddColumn(db, _tableName, 'content_len', 'INTEGER');
      // Best-effort size backfill for existing bodies (no pages yet).
      try {
        await db.execute(
          "UPDATE $_tableName SET content_len=LENGTH(content) "
          "WHERE content IS NOT NULL AND content!='' "
          "AND (content_len IS NULL OR content_len=0)",
        );
      } catch (_) {}
    }
  }

  void _onCreate1(Database db, int version) async {
    await db.execute("CREATE TABLE IF NOT EXISTS $_tableName1("
        "book_id TEXT PRIMARY KEY,"
        "name TEXT,"
        "cname TEXT,"
        "author TEXT,"
        "utime TEXT,"
        "img TEXT,"
        "intro TEXT,"
        "position REAL,"
        "cur INTEGER,"
        "sortTime INTEGER,"
        "newChapter INTEGER,"
        "idx INTEGER,"
        "lastChapter TEXT,"
        "source_url TEXT,"
        "book_url TEXT,"
        "origin_name TEXT,"
        "toc_url TEXT,"
        "reading_chapter TEXT)");
    SpUtil.putString(_tableName1, "");
  }

  Future<void> _onUpgradeBooks(Database db, int oldV, int newV) async {
    if (oldV < 4) {
      await _tryAddColumn(db, _tableName1, 'source_url', 'TEXT');
      await _tryAddColumn(db, _tableName1, 'book_url', 'TEXT');
      await _tryAddColumn(db, _tableName1, 'origin_name', 'TEXT');
      await _tryAddColumn(db, _tableName1, 'toc_url', 'TEXT');
    }
    if (oldV < 5) {
      await _tryAddColumn(db, _tableName1, 'reading_chapter', 'TEXT');
    }
  }

  Future<void> _tryAddColumn(
      Database db, String table, String col, String type) async {
    try {
      await db.execute('ALTER TABLE $table ADD COLUMN $col $type');
    } catch (_) {
      // column may already exist
    }
  }

  Future<void> updBookStatus(String bookId, int s) async {
    var dbClient = await db1;
    dbClient.rawUpdate(
        "update $_tableName1 set newChapter=? where book_id=?", [s, bookId]);
  }

  Future<void> updBook(String lastChapter, int newStatus, String utime,
      String img, String bookId) async {
    var dbClient = await db1;
    dbClient.rawUpdate(
        "update $_tableName1 set lastChapter=?,newChapter=?,utime=?,img=? where book_id=?",
        [lastChapter, newStatus, utime, img, bookId]);
  }

  Future<void> updBookSource(
      String sourceUrl, String bookUrl, String originName, String tocUrl,
      String bookId) async {
    var dbClient = await db1;
    await dbClient.rawUpdate(
        "update $_tableName1 set source_url=?,book_url=?,origin_name=?,toc_url=? where book_id=?",
        [sourceUrl, bookUrl, originName, tocUrl, bookId]);
  }

  Future<void> delBookAndCps(String bookId) async {
    var dbClient = await db1;
    await dbClient
        .rawDelete("delete from $_tableName1  where book_id=?", [bookId]);
    var dbClient1 = await db;
    await dbClient1
        .rawDelete("delete from $_tableName where book_id=?", [bookId]);
  }

  Book _bookFromRow(Map<String, Object?> i) {
    String s(Object? v) {
      if (v == null) return '';
      final t = v.toString();
      return t == 'null' ? '' : t;
    }

    final lastChapter = s(i['lastChapter']);
    return Book.fromSql(
      s(i['book_id']),
      s(i['name']),
      s(i['cname']),
      s(i['author']),
      s(i['utime']),
      s(i['img']),
      s(i['intro']),
      i['cur'] as int? ?? 0,
      i['sortTime'] as int? ?? 0,
      i['idx'] as int? ?? 0,
      (i['position'] as num?)?.toDouble() ?? 0.0,
      i['newChapter'] as int? ?? 0,
      lastChapter,
      sourceUrl: s(i['source_url']),
      bookUrl: s(i['book_url']),
      originName: s(i['origin_name']),
      tocUrl: s(i['toc_url']),
      readingChapter: s(i['reading_chapter']),
    );
  }

  Future<List<Book>> getBooks() async {
    var dbClient = await db1;
    List<Book> bks = [];
    var list = await dbClient
        .rawQuery("select * from $_tableName1 order by sortTime desc", []);
    for (var i in list) {
      bks.add(_bookFromRow(i));
    }
    return bks;
  }

  Future<Book?> getBook(String bookId) async {
    var dbClient = await db1;
    Book? bk;
    var list = await dbClient
        .rawQuery("select * from $_tableName1 where book_id=?", [bookId]);
    for (var i in list) {
      bk = _bookFromRow(i);
    }
    return bk;
  }

  Future<void> delBook(String bookId) async {
    var dbClient = await db1;

    await dbClient
        .rawDelete('delete from $_tableName1 where book_id=?', [bookId]);
  }

  Future<void> sortBook(String bookId) async {
    var dbClient = await db1;

    await dbClient.rawUpdate(
        'update  $_tableName1 set sortTime=${DateUtil.getNowDateMs()},newChapter=0 where book_id=?',
        [bookId]);
  }

  Future<void> addBooks(List<Book> bks) async {
    var dbClient = await db1;

    var batch = dbClient.batch();

    for (Book book in bks) {
      // Ignore if book_id already exists (first-open / shelf race).
      batch.insert(
        _tableName1,
        {
          "book_id": book.Id,
          "name": book.Name,
          "cname": book.CName,
          "author": book.Author.isEmpty ? '' : book.Author,
          "img": book.Img,
          "intro": book.Desc,
          "utime": book.UTime,
          "cur": book.cur,
          "sortTime": book.sortTime,
          "idx": book.index,
          "position": book.position,
          "newChapter": 0,
          "lastChapter": book.LastChapter.isNotEmpty
              ? book.LastChapter
              : book.ChapterName,
          "source_url": book.sourceUrl,
          "book_url": book.bookUrl,
          "origin_name": book.originName,
          "toc_url": book.tocUrl,
          "reading_chapter": book.ChapterName,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    await batch.commit(noResult: true);
  }

  /// Returns number of rows updated (0 if book row is missing).
  Future<int> updBookProcess(
      int cur, int idx, double position, String bookId,
      {String? readingChapter}) async {
    var dbClient = await db1;

    if (readingChapter != null) {
      return await dbClient.rawUpdate(
          "update $_tableName1 set cur=?,idx=?,position=?,reading_chapter=? where book_id=?",
          [cur, idx, position, readingChapter, bookId]);
    }
    return await dbClient.rawUpdate(
        "update $_tableName1 set cur=?,idx=?,position=? where book_id=?",
        [cur, idx, position, bookId]);
  }

  Future<void> addChapters(List<LocalChapter> cps, String bookId,
      {String sourceUrl = ''}) async {
    var dbClient = await db;
    var batch = dbClient.batch();
    for (var i = 0; i < cps.length; i++) {
      LocalChapter chapter = cps[i];
      batch.rawInsert(
          'insert into $_tableName (chapter_id,name,content,book_id,hasContent,url,source_url,idx,book_key) values(?,?,?,?,?,?,?,?,?)',
          [
            chapter.chapterId,
            chapter.chapterName,
            "",
            bookId,
            chapter.hasContent,
            chapter.url,
            sourceUrl,
            chapter.index,
            bookId,
          ]);
    }

    await batch.commit(noResult: true);
  }

  Future<int> getChaptersLen(String bookId) async {
    var dbClient = await db;
    var list = await dbClient.rawQuery(
        "select count(*) as cnt from $_tableName where book_id=?", [bookId]);
    return list[0]['cnt'] as int;
  }

  Future<List<LocalChapter>> getChapters(String bookId) async {
    var dbClient = await db;
    var list = await dbClient.rawQuery(
        "select hasContent,chapter_id,name,url,idx from $_tableName where book_id=? order by idx ASC, id ASC",
        [bookId]);
    List<LocalChapter> cps = [];
    var i = 0;
    for (var row in list) {
      cps.add(LocalChapter(
        chapterId: row['chapter_id'] as String? ?? '',
        chapterName: row['name'] as String? ?? '',
        url: row['url'] as String? ?? '',
        hasContent: row['hasContent']?.toString() ?? '0',
        index: (row['idx'] as int?) ?? i,
      ));
      i++;
    }
    return cps;
  }

  Future<void> clearChapters(String bookId) async {
    var dbClient = await db;
    await dbClient
        .rawDelete("delete from $_tableName where book_id=?", [bookId]);
  }

  Future<String> getContent(String chapterId) async {
    var dbClient = await db;
    List list = await dbClient.rawQuery(
        "select content from $_tableName where chapter_id=?", [chapterId]);
    if (list.isEmpty) return '';
    return list.first['content'] as String? ?? '';
  }

  Future<bool> getHasContent(String chapterId) async {
    var dbClient = await db;
    List list = await dbClient.rawQuery(
        "select hasContent from $_tableName where chapter_id=?", [chapterId]);
    if (list.isEmpty) return false;
    return '2' == list.first['hasContent']?.toString();
  }

  Future<void> udpChapter(List<ChapterNode> cpnodes) async {
    var dbClient = await db;
    var batch = dbClient.batch();
    for (final cpnode in cpnodes) {
      // Content rewrite invalidates page layout for this chapter.
      batch.rawUpdate(
          "update $_tableName set content=?,hasContent=?,content_len=?,"
          "pages_json=NULL,layout_fp=NULL,pages_cached_at=0 "
          "where chapter_id=?",
          [cpnode.content, '2', cpnode.content.length, cpnode.id]);
    }

    await batch.commit();
  }

  /// Read cached pagination JSON + layout fingerprint for [chapterId].
  Future<({String? pagesJson, String? layoutFp})> getChapterPages(
      String chapterId) async {
    var dbClient = await db;
    final list = await dbClient.rawQuery(
        "select pages_json,layout_fp from $_tableName where chapter_id=?",
        [chapterId]);
    if (list.isEmpty) {
      return (pagesJson: null, layoutFp: null);
    }
    final row = list.first;
    final pages = row['pages_json'] as String?;
    final fp = row['layout_fp'] as String?;
    if (pages == null || pages.isEmpty) {
      return (pagesJson: null, layoutFp: fp);
    }
    return (pagesJson: pages, layoutFp: fp);
  }

  /// Persist pagination result (body stays in [content]).
  Future<void> saveChapterPages(
      String chapterId, String pagesJson, String layoutFp) async {
    var dbClient = await db;
    await dbClient.rawUpdate(
        "update $_tableName set pages_json=?,layout_fp=?,pages_cached_at=? "
        "where chapter_id=?",
        [pagesJson, layoutFp, DateUtil.getNowDateMs(), chapterId]);
  }

  /// Clear page layout for one chapter (e.g. after forced re-fetch).
  Future<void> clearChapterPages(String chapterId) async {
    var dbClient = await db;
    await dbClient.rawUpdate(
        "update $_tableName set pages_json=NULL,layout_fp=NULL,pages_cached_at=0 "
        "where chapter_id=?",
        [chapterId]);
  }

  /// Drop page caches whose fingerprint differs from [keepLayoutFp]
  /// (or all page caches when [keepLayoutFp] is null).
  Future<int> clearStalePageCache({String? keepLayoutFp}) async {
    var dbClient = await db;
    if (keepLayoutFp == null || keepLayoutFp.isEmpty) {
      return await dbClient.rawUpdate(
          "update $_tableName set pages_json=NULL,layout_fp=NULL,pages_cached_at=0 "
          "where pages_json IS NOT NULL AND pages_json!=''");
    }
    return await dbClient.rawUpdate(
        "update $_tableName set pages_json=NULL,layout_fp=NULL,pages_cached_at=0 "
        "where pages_json IS NOT NULL AND pages_json!='' "
        "AND (layout_fp IS NULL OR layout_fp!=?)",
        [keepLayoutFp]);
  }

  /// Approximate total size of stored page JSON.
  Future<int> pageCacheBytes() async {
    var dbClient = await db;
    final list = await dbClient.rawQuery(
        "select IFNULL(SUM(LENGTH(pages_json)),0) as bytes from $_tableName "
        "where pages_json IS NOT NULL AND pages_json!=''");
    if (list.isEmpty) return 0;
    final v = list.first['bytes'];
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  /// Evict oldest page caches until under [maxBytes], keeping a window around
  /// the active book/chapter. TOC rows and body content are preserved.
  Future<int> evictPageCache({
    required int maxBytes,
    String? protectBookId,
    int protectCenterIdx = 0,
    int protectRadius = 30,
  }) async {
    final used = await pageCacheBytes();
    if (used <= maxBytes) return 0;

    var dbClient = await db;
    final rows = await dbClient.rawQuery(
        "select chapter_id,book_id,idx,IFNULL(pages_cached_at,0) as ts,"
        "LENGTH(pages_json) as sz from $_tableName "
        "where pages_json IS NOT NULL AND pages_json!='' "
        "order by ts ASC, sz DESC");

    final target = (maxBytes * 0.85).floor();
    var remaining = used;
    final toClear = <String>[];
    final lo = protectCenterIdx - protectRadius;
    final hi = protectCenterIdx + protectRadius;

    for (final row in rows) {
      if (remaining <= target) break;
      final bookId = row['book_id']?.toString() ?? '';
      final idx = row['idx'] as int? ?? -1;
      if (protectBookId != null &&
          protectBookId.isNotEmpty &&
          bookId == protectBookId &&
          idx >= lo &&
          idx <= hi) {
        continue;
      }
      final id = row['chapter_id']?.toString() ?? '';
      if (id.isEmpty) continue;
      final sz = row['sz'];
      final size = sz is int ? sz : (sz is num ? sz.toInt() : 0);
      toClear.add(id);
      remaining -= size;
    }

    if (toClear.isEmpty) return 0;
    final batch = dbClient.batch();
    for (final id in toClear) {
      batch.rawUpdate(
          "update $_tableName set pages_json=NULL,layout_fp=NULL,pages_cached_at=0 "
          "where chapter_id=?",
          [id]);
    }
    await batch.commit(noResult: true);
    return toClear.length;
  }

  Future closeChapter() async {
    await _db?.close();
    _db = null;
  }

  Future closeBook() async {
    await _db1?.close();
    _db1 = null;
  }

}
