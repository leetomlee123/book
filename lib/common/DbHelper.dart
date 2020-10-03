import 'dart:io';

import 'package:book/entity/Book.dart';
import 'package:book/entity/BookTag.dart';
import 'package:book/entity/Chapter.dart';
import 'package:book/entity/MRecords.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class DbHelper {
  final String _tableName = "chapters";
  final String _tableName1 = "books";
  final String _tableName2 = "movies";

  Database _db;
  Database _db1;
  Database _db2;

  Future<Database> get db async {
    if (_db != null) return _db;
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
  _initDb() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();

    String path = documentsDirectory.path + "/chapters.db";
    var db = await openDatabase(path, version: 1, onCreate: _onCreate);
    return db;
  }

  // When creating the db, create the table
  void _onCreate(Database db, int version) async {
    await db.execute("CREATE TABLE IF NOT EXISTS $_tableName("
        "id INTEGER   PRIMARY KEY AUTOINCREMENT,"
        "chapter_id TEXT,"
        "name TEXT,"
        "content TEXT,"
        "book_id TEXT,"
        "hasContent INTEGER)");
    await db.execute("CREATE INDEX book_id_idx ON $_tableName (book_id);");
    await db
        .execute("CREATE INDEX chapter_id_idx ON $_tableName (chapter_id);");
  }

  void _onCreate1(Database db, int version) async {
    await db.execute("CREATE TABLE IF NOT EXISTS $_tableName1("
        "id INTEGER   PRIMARY KEY AUTOINCREMENT,"
        "book_id TEXT,"
        "name TEXT,"
        "cname TEXT,"
        "author TEXT,"
        "utime TEXT,"
        "img TEXT,"
        "cur INTEGER,"
        "newChapter INTEGER,"
        "idx INTEGER,"
        "lastChapter TEXT)");
    await db.execute("CREATE INDEX book_id_idx ON $_tableName1 (book_id);");
  }

  void _onCreate2(Database db, int version) async {
    await db.execute("CREATE TABLE IF NOT EXISTS $_tableName2("
        "id INTEGER   PRIMARY KEY AUTOINCREMENT,"
        "cover TEXT,"
        "name TEXT,"
        "cid TEXT,"
        "mcids TEXT,"
        "cname TEXT)");
  }

  Future<Null> addMovies(List<MRecords> ms) async {
    var dbClient = await db2;

    for (MRecords mRecords in ms) {
      await dbClient.rawInsert(
          "insert into  $_tableName2 (cover,name,cid,cname,mcids) values(?,?,?,?,?)",
          [
            mRecords.cover,
            mRecords.name,
            mRecords.cid,
            mRecords.cname,
            mRecords.mcids
          ]);
    }
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
    return movies;
  }

  Future<int> containBook(String bookId) async {
    var dbClient = await db1;
    var list = await dbClient.rawQuery(
        "select count(*) as cnt from $_tableName1  where book_id=?", [bookId]);
    return list[0]['cnt'];
  }

  Future<Null> updBookStatus(String bookId, int s) async {
    var dbClient = await db1;
    dbClient.rawUpdate(
        "update $_tableName1 set newChapter=? where book_id=?", [s, bookId]);
  }

  Future<Null> updBook(
      String lastChapter, int newStatus, String utime, String bookId) async {
    var dbClient = await db1;
    dbClient.rawUpdate(
        "update $_tableName1 set lastChapter=?,newChapter=?,utime=? where book_id=?",
        [lastChapter, newStatus, utime, bookId]);
  }

  Future<Null> delBook(String bookId) async {
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
          i['cur'],
          i['idx'],
          i['newChapter'],
          i['lastChapter']));
    }
    return bks;
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
        "utime": book.UTime,
        "cur": 0,
        "idx": 0,
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

  Future<BookTag> getBookProcess(String bookId) async {
    var dbClient = await db1;

    var list = await dbClient.rawQuery(
        "select cur,idx,name from $_tableName1 where book_id=?", [bookId]);
    var i = list[0];
    return BookTag(i['cur'], i['idx'], i['name'], 0.0);
  }

  /// 添加章节
  Future<Null> addChapters(List<Chapter> cps, String bookId) async {
    print('add book $bookId');
    var dbClient = await db;
    var batch = dbClient.batch();
    for (Chapter chapter in cps) {
      // batch.rawInsert("$_tableName", {
      //   "chapter_id": chapter.id,
      //   "name": chapter.name,
      //   "content": "",
      //   "book_id": bookId,
      //   "hasContent": chapter.hasContent
      // });
      batch.rawInsert(
          'insert into $_tableName (chapter_id,name,content,book_id,hasContent) values(?,?,?,?,?)',
          [chapter.id, chapter.name, "", bookId, chapter.hasContent]);
    }
    await batch.commit(noResult: true);
    print("save cps success");
  }

  Future<List<Chapter>> getChapters(String bookId) async {
    print('get book $bookId');
    var dbClient = await db;
    var list = await dbClient
        .rawQuery("select * from $_tableName where book_id=?", [bookId]);
    List<Chapter> cps = [];
    for (var i in list) {
      cps.add(Chapter(i['hasContent'], i['chapter_id'], i['name']));
    }
    // await closeBook();

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

  Future<Null> udpChapter(String content, String cid) async {
    var dbClient = await db;
    dbClient.rawUpdate(
        "update $_tableName set content=?,hasContent=2 where chapter_id=?",
        [content, cid]);
  }

  /// 添加书籍到书架
  Future<int> addBookshelfItem(BookshelfBean item) async {
    print("addBookshelfItem = ${item.bookId}");
    var dbClient = await db;
    int res = await dbClient.insert("$_tableName", item.toMap());
    return res;
  }

  /// 根据 id 查询判断书籍是否存在书架
  Future<BookshelfBean> queryBooks(String bookId) async {
    var dbClient = await db;
    var result = await dbClient
        .query(_tableName, where: "bookId = ?", whereArgs: [bookId]);
    if (result != null && result.length > 0) {
      return BookshelfBean.fromMap(result[0]);
    }
    return null;
  }

  /// 查询加入书架的所有书籍
  Future<List> getTotalList() async {
    var dbClient = await db;
    var result = await dbClient.rawQuery("SELECT * FROM $_tableName");
    return result.toList();
  }

  /// 更新书籍进度
  Future<int> updateBooks(BookshelfBean user) async {
    var dbClient = await db;
    return await dbClient.update(_tableName, user.toMap(),
        where: "bookId = ?", whereArgs: [user.bookId]);
  }

  //  关闭
  Future close() async {
    await _db?.close();
    await _db1?.close();
    await _db2?.close();
  }

  //  关闭
  Future closeBook() async {
    var dbClient = await db1;
    return dbClient.close();
  }

  //  关闭
  Future closeMovies() async {
    var dbClient = await db2;
    return dbClient.close();
  }
}

class BookshelfBean {
  BookshelfBean(this.title, this.image, this.readProgress, this.bookUrl,
      this.bookId, this.offset, this.isReversed, this.chaptersIndex);

  /// 书名
  String title;
  String image;
  String readProgress;
  String bookUrl;
  String bookId;
  double offset;

  /// 1是倒序
  int isReversed;
  int chaptersIndex;

  BookshelfBean.fromMap(Map<String, dynamic> map) {
    title = map["title"] as String;
    image = map["image"] as String;
    readProgress = map["readProgress"] as String;
    bookUrl = map["bookUrl"] as String;
    bookId = map["bookId"] as String;
    offset = map["offset"] as double;
    isReversed = map["isReversed"] as int;
    chaptersIndex = map["chaptersIndex"] as int;
  }

  Map<String, dynamic> toMap() {
    var map = <String, dynamic>{
      "title": title,
      "image": image,
      "readProgress": readProgress,
      "bookUrl": bookUrl,
      "bookId": bookId,
      "offset": offset,
      "isReversed": isReversed,
      "chaptersIndex": chaptersIndex,
    };
    return map;
  }
}
