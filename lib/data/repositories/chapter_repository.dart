import 'dart:convert';

import 'package:book/data/db/reader_database.dart';
import 'package:book/entity/ChapterNode.dart';
import 'package:book/entity/chapter_toc_entry.dart';
import 'package:book/entity/TextPage.dart';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

/// TOC, chapter body, and page-layout cache.
class ChapterRepository {
  ChapterRepository({ReaderDatabase? db}) : _db = db ?? ReaderDatabase.instance;

  final ReaderDatabase _db;
  static final ChapterRepository instance = ChapterRepository();

  Future<Database> get _database => _db.database;

  Future<List<ChapterTocEntry>> getToc(String bookId) async {
    final db = await _database;
    final rows = await db.query(
      'chapters',
      columns: ['id', 'title', 'url', 'has_body', 'ord'],
      where: 'book_id = ?',
      whereArgs: [bookId],
      orderBy: 'ord ASC',
    );
    return rows
        .map(
          (r) => ChapterTocEntry(
            id: r['id'] as String? ?? '',
            title: r['title'] as String? ?? '',
            url: r['url'] as String? ?? '',
            hasBody: (r['has_body'] as int? ?? 0) == 1,
            ord: r['ord'] as int? ?? 0,
          ),
        )
        .toList();
  }

  Future<int> count(String bookId) async {
    final db = await _database;
    final rows = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM chapters WHERE book_id = ?',
      [bookId],
    );
    final v = rows.first['c'];
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  Future<void> replaceToc(
    List<ChapterTocEntry> chapters,
    String bookId, {
    String sourceUrl = '',
  }) async {
    final db = await _database;
    await db.delete('chapters', where: 'book_id = ?', whereArgs: [bookId]);
    if (chapters.isEmpty) return;
    final batch = db.batch();
    for (var i = 0; i < chapters.length; i++) {
      final c = chapters[i];
      batch.insert('chapters', {
        'id': c.id,
        'book_id': bookId,
        'title': c.title,
        'url': c.url,
        'source_url': sourceUrl,
        'ord': c.ord != 0 ? c.ord : i,
        'body': '',
        'has_body': 0,
        'content_len': 0,
        'pages_json': null,
        'layout_fp': null,
        'pages_cached_at': 0,
      });
    }
    await batch.commit(noResult: true);
  }

  Future<void> appendToc(
    List<ChapterTocEntry> chapters,
    String bookId, {
    String sourceUrl = '',
  }) async {
    if (chapters.isEmpty) return;
    final db = await _database;
    final batch = db.batch();
    for (final c in chapters) {
      batch.insert(
        'chapters',
        {
          'id': c.id,
          'book_id': bookId,
          'title': c.title,
          'url': c.url,
          'source_url': sourceUrl,
          'ord': c.ord,
          'body': '',
          'has_body': 0,
          'content_len': 0,
          'pages_json': null,
          'layout_fp': null,
          'pages_cached_at': 0,
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> clearBook(String bookId) async {
    final db = await _database;
    await db.delete('chapters', where: 'book_id = ?', whereArgs: [bookId]);
  }

  Future<String> getBody(String chapterId) async {
    final cached = await getChapterCache(chapterId);
    return cached.body;
  }

  /// Single-query open path: body + page layout in one round-trip.
  Future<({String body, String? pagesJson, String? layoutFp})> getChapterCache(
    String chapterId,
  ) async {
    final db = await _database;
    final rows = await db.query(
      'chapters',
      columns: ['body', 'pages_json', 'layout_fp'],
      where: 'id = ?',
      whereArgs: [chapterId],
    );
    if (rows.isEmpty) {
      return (body: '', pagesJson: null, layoutFp: null);
    }
    final row = rows.first;
    final pages = row['pages_json'] as String?;
    final fp = row['layout_fp'] as String?;
    return (
      body: row['body'] as String? ?? '',
      pagesJson: (pages == null || pages.isEmpty) ? null : pages,
      layoutFp: fp,
    );
  }

  Future<bool> hasBody(String chapterId) async {
    final db = await _database;
    final rows = await db.query(
      'chapters',
      columns: ['has_body'],
      where: 'id = ?',
      whereArgs: [chapterId],
    );
    if (rows.isEmpty) return false;
    return (rows.first['has_body'] as int? ?? 0) == 1;
  }

  /// Cached chapter body counts for shelf/cache UI.
  Future<({int total, int withBody})> bodyStats(String bookId) async {
    final db = await _database;
    final rows = await db.rawQuery(
      'SELECT COUNT(*) AS total, '
      'SUM(CASE WHEN has_body = 1 THEN 1 ELSE 0 END) AS with_body '
      'FROM chapters WHERE book_id = ?',
      [bookId],
    );
    if (rows.isEmpty) return (total: 0, withBody: 0);
    final total = rows.first['total'];
    final withBody = rows.first['with_body'];
    int asInt(Object? v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v?.toString() ?? '') ?? 0;
    }

    return (total: asInt(total), withBody: asInt(withBody));
  }

  Future<void> updateBodies(List<ChapterNode> nodes) async {
    if (nodes.isEmpty) return;
    final db = await _database;
    final batch = db.batch();
    for (final n in nodes) {
      batch.update(
        'chapters',
        {
          'body': n.content,
          'has_body': n.content.isEmpty ? 0 : 1,
          'content_len': n.content.length,
          'pages_json': null,
          'layout_fp': null,
          'pages_cached_at': 0,
        },
        where: 'id = ?',
        whereArgs: [n.id],
      );
    }
    await batch.commit(noResult: true);
  }

  Future<({String? pagesJson, String? layoutFp})> getPageLayout(
      String chapterId) async {
    final db = await _database;
    final rows = await db.query(
      'chapters',
      columns: ['pages_json', 'layout_fp'],
      where: 'id = ?',
      whereArgs: [chapterId],
    );
    if (rows.isEmpty) return (pagesJson: null, layoutFp: null);
    final pages = rows.first['pages_json'] as String?;
    final fp = rows.first['layout_fp'] as String?;
    if (pages == null || pages.isEmpty) {
      return (pagesJson: null, layoutFp: fp);
    }
    return (pagesJson: pages, layoutFp: fp);
  }

  Future<void> savePageLayout(
    String chapterId,
    String pagesJson,
    String layoutFp,
  ) async {
    final db = await _database;
    await db.update(
      'chapters',
      {
        'pages_json': pagesJson,
        'layout_fp': layoutFp,
        'pages_cached_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [chapterId],
    );
  }

  Future<void> clearPageLayout(String chapterId) async {
    final db = await _database;
    await db.update(
      'chapters',
      {
        'pages_json': null,
        'layout_fp': null,
        'pages_cached_at': 0,
      },
      where: 'id = ?',
      whereArgs: [chapterId],
    );
  }

  /// Drop page caches whose fingerprint differs from [keepLayoutFp]
  /// (or all page caches when [keepLayoutFp] is null/empty).
  Future<int> clearAllPageLayouts({String? keepLayoutFp}) async {
    final db = await _database;
    if (keepLayoutFp == null || keepLayoutFp.isEmpty) {
      return db.rawUpdate(
        "UPDATE chapters SET pages_json=NULL, layout_fp=NULL, pages_cached_at=0 "
        "WHERE pages_json IS NOT NULL AND pages_json!=''",
      );
    }
    return db.rawUpdate(
      "UPDATE chapters SET pages_json=NULL, layout_fp=NULL, pages_cached_at=0 "
      "WHERE pages_json IS NOT NULL AND pages_json!='' "
      "AND (layout_fp IS NULL OR layout_fp!=?)",
      [keepLayoutFp],
    );
  }

  Future<int> pageCacheBytes() async {
    final db = await _database;
    final rows = await db.rawQuery(
      "SELECT IFNULL(SUM(LENGTH(pages_json)),0) AS bytes FROM chapters "
      "WHERE pages_json IS NOT NULL AND pages_json!=''",
    );
    if (rows.isEmpty) return 0;
    final v = rows.first['bytes'];
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  Future<int> evictPageCache({
    required int maxBytes,
    String? protectBookId,
    int protectCenterIdx = 0,
    int protectRadius = 30,
  }) async {
    final used = await pageCacheBytes();
    if (used <= maxBytes) return 0;

    final db = await _database;
    final rows = await db.rawQuery(
      "SELECT id, book_id, ord, IFNULL(pages_cached_at,0) AS ts, "
      "LENGTH(pages_json) AS sz FROM chapters "
      "WHERE pages_json IS NOT NULL AND pages_json!='' "
      "ORDER BY ts ASC, sz DESC",
    );

    final target = (maxBytes * 0.85).floor();
    var remaining = used;
    final toClear = <String>[];
    final lo = protectCenterIdx - protectRadius;
    final hi = protectCenterIdx + protectRadius;

    for (final row in rows) {
      if (remaining <= target) break;
      final bookId = row['book_id']?.toString() ?? '';
      final ord = row['ord'] as int? ?? -1;
      if (protectBookId != null &&
          protectBookId.isNotEmpty &&
          bookId == protectBookId &&
          ord >= lo &&
          ord <= hi) {
        continue;
      }
      final id = row['id']?.toString() ?? '';
      if (id.isEmpty) continue;
      final sz = row['sz'];
      final size = sz is int ? sz : (sz is num ? sz.toInt() : 0);
      toClear.add(id);
      remaining -= size;
    }

    if (toClear.isEmpty) return 0;
    final batch = db.batch();
    for (final id in toClear) {
      batch.update(
        'chapters',
        {
          'pages_json': null,
          'layout_fp': null,
          'pages_cached_at': 0,
        },
        where: 'id = ?',
        whereArgs: [id],
      );
    }
    await batch.commit(noResult: true);
    return toClear.length;
  }

  static Future<List<TextPage>?> decodePagesJson(String? json) async {
    if (json == null || json.isEmpty) return null;
    if (json.length < 32 * 1024) {
      return _decodePagesIsolate(json);
    }
    return compute(_decodePagesIsolate, json);
  }

  static Future<String> encodePagesJson(List<TextPage> pages) async {
    final maps = pages.map((e) => e.toJson()).toList(growable: false);
    if (maps.length < 8) {
      return _encodePagesIsolate(maps);
    }
    return compute(_encodePagesIsolate, maps);
  }
}

List<TextPage>? _decodePagesIsolate(String json) {
  try {
    final decoded = jsonDecode(json);
    if (decoded is! List || decoded.isEmpty) return null;
    return decoded
        .map((e) => TextPage.fromJson(Map<String, dynamic>.from(e as Map)))
        .toList();
  } catch (_) {
    return null;
  }
}

String _encodePagesIsolate(List<Map<String, dynamic>> maps) {
  return jsonEncode(maps);
}
