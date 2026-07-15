import 'dart:io';

import 'package:book/entity/Book.dart';
import 'package:book/entity/ChapterNode.dart';
import 'package:book/entity/LocalChapter.dart';
import 'package:book/common/local_store.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DbHelper {
  static DbHelper _dbHelper = DbHelper();
  static DbHelper instance = _dbHelper;
  final String _tableName = "chapters";
  final String _tableName1 = "books";
  final String _tableName2 = "movies";
  final String _tableName3 = "cord";
  final String _tableName4 = "voice";

  static Database? _db;
  static Database? _db1;
  static Database? _db2;
  static Database? _db3;
  static Database? _db4;
  int version = 4;

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

  Future<Database> get db2 async {
    if (_db2 != null) return _db2!;
    _db2 = await _initDb2();
    return _db2!;
  }

  Future<Database> get db3 async {
    if (_db3 != null) return _db3!;
    _db3 = await _initDb3();
    return _db3!;
  }

  Future<Database> get db4 async {
    if (_db4 != null) return _db4!;
    _db4 = await _initDb4();
    return _db4!;
  }

  _initDb1() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();

    String path = documentsDirectory.path + "/books.db";
    var db = await openDatabase(path,
        version: version, onCreate: _onCreate1, onUpgrade: _onUpgradeBooks);
    return db;
  }

  _initDb2() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();

    String path = documentsDirectory.path + "/movies.db";
    var db = await openDatabase(path, version: version, onCreate: _onCreate2);
    return db;
  }

  _initDb3() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();

    String path = documentsDirectory.path + "/cord.db";
    var db = await openDatabase(path, version: version, onCreate: _onCreate3);
    return db;
  }

  _initDb4() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();

    String path = documentsDirectory.path + "/voice.db";
    var db = await openDatabase(path, version: version, onCreate: _onCreate4);
    return db;
  }

  _initDb() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();

    String path = documentsDirectory.path + "/chapters.db";
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
        "book_key TEXT)");
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
        "toc_url TEXT)");
    SpUtil.putString(_tableName1, "");
  }

  Future<void> _onUpgradeBooks(Database db, int oldV, int newV) async {
    if (oldV < 4) {
      await _tryAddColumn(db, _tableName1, 'source_url', 'TEXT');
      await _tryAddColumn(db, _tableName1, 'book_url', 'TEXT');
      await _tryAddColumn(db, _tableName1, 'origin_name', 'TEXT');
      await _tryAddColumn(db, _tableName1, 'toc_url', 'TEXT');
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

  void _onCreate2(Database db, int version) async {
    if (!SpUtil.haveKey(_tableName2)) {
      await db.execute("CREATE TABLE IF NOT EXISTS $_tableName2("
          "id INTEGER   PRIMARY KEY AUTOINCREMENT,"
          "cover TEXT,"
          "name TEXT,"
          "cid TEXT,"
          "mcids TEXT,"
          "cname TEXT)");
      SpUtil.putString(_tableName2, "");
    }
  }

  void _onCreate3(Database db, int version) async {
    if (!SpUtil.haveKey(_tableName3)) {
      await db.execute("CREATE TABLE IF NOT EXISTS $_tableName3("
          "id INTEGER   PRIMARY KEY AUTOINCREMENT,"
          "key TEXT,"
          "content TEXT)");
      await db.execute("CREATE INDEX key_idx ON $_tableName3 (key);");
      SpUtil.putString(_tableName3, "");
    }
  }

  void _onCreate4(Database db, int version) async {
    if (!SpUtil.haveKey(_tableName4)) {
      await db.execute("CREATE TABLE IF NOT EXISTS $_tableName4("
          "id INTEGER   PRIMARY KEY AUTOINCREMENT,"
          "title TEXT,"
          "cover TEXT,"
          "author TEXT,"
          "chapter TEXT,"
          "position INTEGER,"
          "idx INTEGER,"
          "tm INTEGER,"
          "key TEXT)");
      await db.execute("CREATE INDEX key_idx ON $_tableName4 (key);");
      SpUtil.putString(_tableName4, "");
    }
  }

  Future<Map<String, int>> getVoiceRecord(String key, int idx) async {
    var dbClient = await db4;
    List list = await dbClient.rawQuery(
        "select * from $_tableName4 where key=? and idx=?", [key, idx]);
    if (list.isEmpty) {
      return {'idx': -1, 'position': 1};
    } else {
      return {
        'idx': list[0]['idx'] as int? ?? 0,
        'position': list[0]['position'] as int? ?? 0
      };
    }
  }

  Future<int> saveVoiceRecord(String key, String cover, String title,
      String author, int position, int idx, String chapter) async {
    var dbClient = await db4;
    var list = await dbClient.rawQuery(
        "select count(*) as cnt from $_tableName4 where key=?", [key]);
    int cnt = list[0]['cnt'] as int;
    if (cnt > 0) {
      return await dbClient.rawUpdate(
          "update $_tableName4 set position=? , tm=? ,chapter=? ,idx=? where key=?",
          [position, DateUtil.getNowDateMs(), chapter, idx, key]);
    } else {
      return await dbClient.rawInsert(
          "insert into $_tableName4(title,key,cover,author,position,idx,tm,chapter) values(?,?,?,?,?,?,?,?)",
          [
            title,
            key,
            cover,
            author,
            position,
            idx,
            DateUtil.getNowDateMs(),
            chapter
          ]);
    }
  }

  Future<void> addCords(String key, List<String> contents) async {
    var dbClient = await db3;
    var batch = dbClient.batch();
    for (String content in contents) {
      batch.rawInsert("insert into  $_tableName3 (key,content) values(?,?)",
          [key, content]);
    }
    await batch.commit(noResult: true);
  }

  Future<List<String>> getContents(String key) async {
    var dbClient = await db3;
    List<String> contents = [];
    var list = await dbClient
        .rawQuery("select content from $_tableName3 where key=?", [key]);
    for (var i in list) {
      contents.add(i['content'].toString());
    }
    return contents;
  }

  Future<bool> hasContents(String key) async {
    var dbClient = await db3;
    List list = await dbClient
        .rawQuery("select id from $_tableName3 where key=?", [key]);
    return list.length > 0;
  }

  Future<void> delContents(String key) async {
    var dbClient = await db3;
    await dbClient.rawDelete("delete from $_tableName3 where key=?", [key]);
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
    return Book.fromSql(
      i['book_id'] as String,
      i['name'] as String? ?? '',
      i['cname'] as String? ?? '',
      i['author'] as String? ?? '',
      i['utime'] as String? ?? '',
      i['img'] as String? ?? '',
      i['intro'] as String? ?? '',
      i['cur'] as int? ?? 0,
      i['sortTime'] as int? ?? 0,
      i['idx'] as int? ?? 0,
      (i['position'] as num?)?.toDouble() ?? 0.0,
      i['newChapter'] as int? ?? 0,
      i['lastChapter'] as String? ?? '',
      sourceUrl: i['source_url'] as String? ?? '',
      bookUrl: i['book_url'] as String? ?? '',
      originName: i['origin_name'] as String? ?? '',
      tocUrl: i['toc_url'] as String? ?? '',
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
      batch.insert("$_tableName1", {
        "book_id": book.Id,
        "name": book.Name,
        "cname": book.CName,
        "author": book.Author,
        "img": book.Img,
        "intro": book.Desc,
        "utime": book.UTime,
        "cur": book.cur,
        "sortTime": book.sortTime,
        "idx": book.index,
        "position": book.position,
        "newChapter": 0,
        "lastChapter": book.LastChapter,
        "source_url": book.sourceUrl,
        "book_url": book.bookUrl,
        "origin_name": book.originName,
        "toc_url": book.tocUrl,
      });
    }
    await batch.commit(noResult: true);
  }

  Future<void> updBookProcess(
      int cur, int idx, double position, String bookId) async {
    var dbClient = await db1;

    await dbClient.rawUpdate(
        "update $_tableName1 set cur=?,idx=?,position=? where book_id=?", [
      cur,
      idx,
      position,
      bookId,
    ]);
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
    cpnodes.forEach((cpnode) {
      batch.rawUpdate(
          "update $_tableName set content=?,hasContent=? where chapter_id=?",
          [cpnode.content, '2', cpnode.id]);
    });

    await batch.commit();
  }

  Future closeChapter() async {
    await _db?.close();
    _db = null;
  }

  Future closeBook() async {
    await _db1?.close();
    _db1 = null;
  }

  Future closeMovie() async {
    await _db2?.close();
    _db2 = null;
  }
}
