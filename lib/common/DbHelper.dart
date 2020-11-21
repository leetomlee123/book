import 'dart:io';

import 'package:book/entity/Book.dart';
import 'package:book/entity/BookTag.dart';
import 'package:book/entity/Chapter.dart';
import 'package:book/entity/ChapterNode.dart';
import 'package:book/entity/MRecords.dart';
import 'package:flustars/flustars.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DbHelper {
  static DbHelper _dbHelper = new DbHelper();
  static DbHelper instance = _dbHelper;
  final String _tableName = "chapters";
  final String _tableName1 = "books";
  final String _tableName2 = "movies";
  final String _tableName3 = "cord";

  static Database _db;
  static Database _db1;
  static Database _db2;
  static Database _db3;
  Future<Database> get db async {
    if (_db != null) {
      return _db;
    }
    _db = await _initDb();

    return _db;
  }

  Future<Database> get db1 async {
    if (_db1 != null) return _db1;
    _db1 = await _initDb1();
    return _db1;
  }

  Future<Database> get db2 async {
    if (_db2 != null) return _db2;
    _db2 = await _initDb2();
    return _db2;
  }

  Future<Database> get db3 async {
    if (_db3 != null) return _db3;
    _db3 = await _initDb3();
    return _db3;
  }

  //初始化数据库
  _initDb1() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();

    String path = documentsDirectory.path + "/books.db";
    var db = await openDatabase(path, version: 1, onCreate: _onCreate1);
    return db;
  }

//初始化数据库
  _initDb2() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();

    String path = documentsDirectory.path + "/movies.db";
    var db = await openDatabase(path, version: 1, onCreate: _onCreate2);
    return db;
  }

  //初始化数据库
  _initDb3() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();

    String path = documentsDirectory.path + "/cord.db";
    var db = await openDatabase(path, version: 1, onCreate: _onCreate3);
    return db;
  }

  //初始化数据库
  _initDb() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();

    String path = documentsDirectory.path + "/chapters.db";
    var db = await openDatabase(path, version: 1, onCreate: _onCreate);
    return db;
  }

  // When creating the db, create the table
  void _onCreate(Database db, int version) async {
    if (!SpUtil.haveKey(_tableName)) {
      await db.execute("CREATE TABLE IF NOT EXISTS $_tableName("
          "id INTEGER PRIMARY KEY AUTOINCREMENT,"
          "chapter_id TEXT,"
          "name TEXT,"
          "content TEXT,"
          "book_id TEXT,"
          "hasContent INTEGER)");
      await db.execute("CREATE INDEX book_id_idx ON $_tableName (book_id);");
      await db
          .execute("CREATE INDEX chapter_id_idx ON $_tableName (chapter_id);");
      SpUtil.putString(_tableName, "");
    }
  }

  void _onCreate1(Database db, int version) async {
    if (!SpUtil.haveKey(_tableName1)) {
      await db.execute("CREATE TABLE IF NOT EXISTS $_tableName1("
          "id INTEGER   PRIMARY KEY AUTOINCREMENT,"
          "book_id TEXT,"
          "name TEXT,"
          "cname TEXT,"
          "author TEXT,"
          "utime TEXT,"
          "img TEXT,"
          "intro TEXT,"
          "cur INTEGER,"
          "newChapter INTEGER,"
          "idx INTEGER,"
          "lastChapter TEXT)");
      await db.execute("CREATE INDEX book_id_idx ON $_tableName1 (book_id);");
      SpUtil.putString(_tableName1, "");
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

  Future<Null> addCords(String key, List<String> contents) async {
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

  Future<Null> delContents(String key) async {
    var dbClient = await db3;
    await dbClient.rawDelete("delete from $_tableName3 where key=?", [key]);
  }

  Future<Null> addMovies(List<MRecords> ms) async {
    var dbClient = await db2;
    var batch = dbClient.batch();
    for (MRecords mRecords in ms) {
      batch.rawInsert(
          "insert into  $_tableName2 (cover,name,cid,cname,mcids) values(?,?,?,?,?)",
          [
            mRecords.cover,
            mRecords.name,
            mRecords.cid,
            mRecords.cname,
            mRecords.mcids
          ]);
    }
    await batch.commit(noResult: true);
    // await close();
  }

  Future<List<MRecords>> getMovies() async {
    var dbClient = await db2;
    List<MRecords> movies = [];
    var list = await dbClient
        .rawQuery("select * from $_tableName2 order by id asc", []);
    for (var i in list) {
      movies.add(
          MRecords(i['cover'], i['name'], i['cid'], i['cname'], i['mcids']));
    }
    // await close();
    return movies;
  }

  Future<int> containBook(String bookId) async {
    var dbClient = await db1;
    var list = await dbClient.rawQuery(
        "select count(*) as cnt from $_tableName1  where book_id=?", [bookId]);
    // await close();
    return list[0]['cnt'];
  }

  Future<Null> updBookStatus(String bookId, int s) async {
    var dbClient = await db1;
    dbClient.rawUpdate(
        "update $_tableName1 set newChapter=? where book_id=?", [s, bookId]);
    // await close();
  }

  Future<Null> updBook(
      String lastChapter, int newStatus, String utime, String bookId) async {
    var dbClient = await db1;
    dbClient.rawUpdate(
        "update $_tableName1 set lastChapter=?,newChapter=?,utime=? where book_id=?",
        [lastChapter, newStatus, utime, bookId]);
  }

  Future<Null> delBookAndCps(String bookId) async {
    var dbClient = await db1;
    dbClient.rawDelete("delete from $_tableName1  where book_id=?", [bookId]);
    var dbClient1 = await db;
    dbClient1.rawDelete("delete from $_tableName where book_id=?", [bookId]);
  }

  Future<List<Book>> getBooks() async {
    var dbClient = await db1;
    List<Book> bks = [];
    var list = await dbClient
        .rawQuery("select * from $_tableName1 order by id desc", []);
    for (var i in list) {
      bks.add(Book.fromSql(
          i['book_id'],
          i['name'],
          i['cname'],
          i['author'],
          i['utime'],
          i['img'],
          i['intro'],
          i['cur'],
          i['idx'],
          i['newChapter'],
          i['lastChapter']));
    }
    return bks;
  }

  Future<Book> getBook(String bookId) async {
    var dbClient = await db1;
    Book bk;
    var list = await dbClient
        .rawQuery("select * from $_tableName1 where book_id=?", [bookId]);
    for (var i in list) {
      bk = Book.fromSql(
          i['book_id'],
          i['name'],
          i['cname'],
          i['author'],
          i['utime'],
          i['img'],
          i['intro'],
          i['cur'] ?? 0,
          i['idx'] ?? 0,
          i['newChapter'],
          i['lastChapter']);
    }
    return bk;
  }

  Future<Null> delBook(String bookId) async {
    var dbClient = await db1;

    await dbClient
        .rawDelete('delete from $_tableName1 where book_id=?', [bookId]);
  }

  Future<Null> addBooks(List<Book> bks) async {
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
        "idx": book.index,
        "newChapter": 0,
        "lastChapter": book.LastChapter
      });
    }
    await batch.commit(noResult: true);
  }

  Future<Null> updBookProcess(int cur, int idx, String bookId) async {
    var dbClient = await db1;

    await dbClient.rawUpdate(
        "update $_tableName1 set cur=?,idx=? where book_id=?",
        [cur, idx, bookId]);
  }

  Future<BookTag> getBookProcess(String bookId, String name) async {
    var dbClient = await db1;

    var list = await dbClient.rawQuery(
        "select cur,idx,name from $_tableName1 where book_id=?", [bookId]);
    if (list.length == 0) {
      return BookTag(0, 0, name, 0.0);
    }
    var i = list[0];

    return BookTag(i['cur'] ?? 0, i['idx'] ?? 0, i['name'], 0.0);
  }

  /// 添加章节
  Future<Null> addChapters(List<Chapter> cps, String bookId) async {
    var dbClient = await db;
    var batch = dbClient.batch();
    for (var i = 0; i < cps.length; i++) {
      Chapter chapter = cps[i];
      batch.rawInsert(
          'insert into $_tableName (chapter_id,name,content,book_id,hasContent) values(?,?,?,?,?)',
          [chapter.id, chapter.name, "", bookId, chapter.hasContent]);
    }

    await batch.commit(noResult: true);
  }

  Future<int> getChaptersLen(String bookId) async {
    var dbClient = await db;
    var list = await dbClient.rawQuery(
        "select count(*) as cnt from $_tableName where book_id=?", [bookId]);
    return list[0]['cnt'];
  }

  Future<List<Chapter>> getChapters(String bookId) async {
    var dbClient = await db;
    var list = await dbClient.rawQuery(
        "select hasContent,chapter_id,name from $_tableName where book_id=?",
        [bookId]);
    List<Chapter> cps = [];
    for (var i in list) {
      cps.add(Chapter(i['hasContent'], i['chapter_id'], i['name']));
    }
    return cps;
  }

  /// 添加章节
  Future<Null> clearChapters(String bookId) async {
    var dbClient = await db;
    await dbClient
        .rawDelete("delete from $_tableName where book_id=?", [bookId]);
  }

  Future<String> getContent(String chapterId) async {
    var dbClient = await db;
    var list = await dbClient.rawQuery(
        "select content from $_tableName where chapter_id=?", [chapterId]);
    return list[0]['content'];
  }

  Future<bool> getHasContent(String chapterId) async {
    var dbClient = await db;
    var list = await dbClient.rawQuery(
        "select hasContent from $_tableName where chapter_id=?", [chapterId]);
    return 2 == list[0]['hasContent'];
  }

  Future<Null> udpChapter(List<ChapterNode> cpnodes) async {
    var dbClient = await db;
    var batch = dbClient.batch();
    cpnodes.forEach((cpnode) {
      batch.rawUpdate(
          "update $_tableName set content=?,hasContent=2 where chapter_id=?",
          [cpnode.content, cpnode.id]);
    });

    await batch.commit(noResult: true);
  }

  //  关闭
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
