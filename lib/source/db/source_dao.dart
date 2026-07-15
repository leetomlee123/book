import 'dart:convert';

import 'package:book/source/model/book_source.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

class SourceDao {
  static final SourceDao instance = SourceDao._();
  SourceDao._();

  Database? _db;
  static const _table = 'sources';

  Future<Database> get db async {
    if (_db != null) return _db!;
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/sources.db';
    _db = await openDatabase(
      path,
      version: 1,
      onCreate: (db, v) async {
        await db.execute('''
CREATE TABLE IF NOT EXISTS $_table(
  book_source_url TEXT PRIMARY KEY,
  book_source_name TEXT NOT NULL,
  book_source_group TEXT,
  book_source_type INTEGER DEFAULT 0,
  enabled INTEGER DEFAULT 1,
  custom_order INTEGER DEFAULT 0,
  weight INTEGER DEFAULT 0,
  search_url TEXT,
  explore_url TEXT,
  header TEXT,
  raw_json TEXT NOT NULL,
  last_update_time INTEGER,
  respond_time INTEGER,
  last_check_time INTEGER
)''');
        await db.execute(
            'CREATE INDEX IF NOT EXISTS sources_order_idx ON $_table(custom_order)');
      },
    );
    return _db!;
  }

  Future<List<BookSource>> getAll() async {
    final d = await db;
    final rows =
        await d.query(_table, orderBy: 'custom_order ASC, book_source_name ASC');
    return rows.map(_fromRow).toList();
  }

  Future<List<BookSource>> getEnabled() async {
    final d = await db;
    final rows = await d.query(
      _table,
      where: 'enabled=1',
      orderBy: 'custom_order ASC, weight DESC',
    );
    return rows.map(_fromRow).toList();
  }

  Future<BookSource?> getByUrl(String url) async {
    final d = await db;
    final rows =
        await d.query(_table, where: 'book_source_url=?', whereArgs: [url]);
    if (rows.isEmpty) return null;
    return _fromRow(rows.first);
  }

  Future<void> upsert(BookSource s) async {
    final d = await db;
    await d.insert(
      _table,
      _toRow(s),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> upsertAll(List<BookSource> list) async {
    final d = await db;
    final batch = d.batch();
    for (final s in list) {
      batch.insert(
        _table,
        _toRow(s),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> setEnabled(String url, bool enabled) async {
    final d = await db;
    await d.update(
      _table,
      {'enabled': enabled ? 1 : 0},
      where: 'book_source_url=?',
      whereArgs: [url],
    );
  }

  Future<void> updateOrder(String url, int order) async {
    final d = await db;
    await d.update(
      _table,
      {'custom_order': order},
      where: 'book_source_url=?',
      whereArgs: [url],
    );
  }

  Future<void> delete(String url) async {
    final d = await db;
    await d.delete(_table, where: 'book_source_url=?', whereArgs: [url]);
  }

  Future<void> clear() async {
    final d = await db;
    await d.delete(_table);
  }

  Future<int> count() async {
    final d = await db;
    final r = await d.rawQuery('SELECT COUNT(*) AS c FROM $_table');
    return Sqflite.firstIntValue(r) ?? 0;
  }

  BookSource _fromRow(Map<String, Object?> row) {
    final raw = (row['raw_json'] as String?) ?? '{}';
    Map<String, dynamic> jsonMap = {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        jsonMap = Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}

    final BookSource s = jsonMap.isNotEmpty
        ? BookSource.fromLegadoJson(jsonMap)
        : BookSource(
            bookSourceUrl: row['book_source_url'] as String? ?? '',
            bookSourceName: row['book_source_name'] as String? ?? '',
            bookSourceGroup: row['book_source_group'] as String? ?? '',
            bookSourceType: row['book_source_type'] as int? ?? 0,
            searchUrl: row['search_url'] as String? ?? '',
            exploreUrl: row['explore_url'] as String? ?? '',
            header: row['header'] as String? ?? '',
          );

    s.enabled = (row['enabled'] as int? ?? 1) == 1;
    s.customOrder = row['custom_order'] as int? ?? 0;
    s.weight = row['weight'] as int? ?? 0;
    s.lastUpdateTime = row['last_update_time'] as int? ?? 0;
    s.respondTime = row['respond_time'] as int? ?? 0;
    s.rawJson = raw;
    s.bookSourceUrl = row['book_source_url'] as String? ?? s.bookSourceUrl;
    s.bookSourceName = row['book_source_name'] as String? ?? s.bookSourceName;
    final searchUrl = row['search_url'] as String? ?? '';
    if (searchUrl.isNotEmpty) s.searchUrl = searchUrl;
    final header = row['header'] as String? ?? '';
    if (header.isNotEmpty) s.header = header;
    return s;
  }

  Map<String, Object?> _toRow(BookSource s) {
    final raw =
        s.rawJson.isNotEmpty ? s.rawJson : jsonEncode(s.toLegadoJson());
    return {
      'book_source_url': s.bookSourceUrl,
      'book_source_name': s.bookSourceName,
      'book_source_group': s.bookSourceGroup,
      'book_source_type': s.bookSourceType,
      'enabled': s.enabled ? 1 : 0,
      'custom_order': s.customOrder,
      'weight': s.weight,
      'search_url': s.searchUrl,
      'explore_url': s.exploreUrl,
      'header': s.header,
      'raw_json': raw,
      'last_update_time': s.lastUpdateTime,
      'respond_time': s.respondTime,
      'last_check_time': 0,
    };
  }
}
