import 'dart:convert';

import 'package:book/data/db/reader_database.dart';
import 'package:book/source/model/book_source.dart';
import 'package:sqflite/sqflite.dart';

/// Book-source persistence on [ReaderDatabase] (`sources` table).
class SourceRepository {
  SourceRepository({ReaderDatabase? db}) : _db = db ?? ReaderDatabase.instance;

  final ReaderDatabase _db;
  static final SourceRepository instance = SourceRepository();

  Future<Database> get _database => _db.database;

  Future<List<BookSource>> getAll() async {
    final db = await _database;
    final rows = await db.query(
      'sources',
      orderBy: 'custom_order ASC, book_source_name ASC',
    );
    return rows.map(_fromRow).toList();
  }

  Future<List<BookSource>> getEnabled() async {
    final db = await _database;
    final rows = await db.query(
      'sources',
      where: 'enabled = 1',
      orderBy: 'custom_order ASC, weight DESC',
    );
    return rows.map(_fromRow).toList();
  }

  Future<BookSource?> getByUrl(String url) async {
    final db = await _database;
    final rows = await db.query(
      'sources',
      where: 'book_source_url = ?',
      whereArgs: [url],
    );
    if (rows.isEmpty) return null;
    return _fromRow(rows.first);
  }

  Future<void> upsert(BookSource source) async {
    final db = await _database;
    await db.insert(
      'sources',
      _toRow(source),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> upsertAll(List<BookSource> sources) async {
    if (sources.isEmpty) return;
    final db = await _database;
    final batch = db.batch();
    for (final s in sources) {
      batch.insert(
        'sources',
        _toRow(s),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }

  Future<void> setEnabled(String url, bool enabled) async {
    final db = await _database;
    await db.update(
      'sources',
      {'enabled': enabled ? 1 : 0},
      where: 'book_source_url = ?',
      whereArgs: [url],
    );
  }

  Future<void> updateOrder(String url, int order) async {
    final db = await _database;
    await db.update(
      'sources',
      {'custom_order': order},
      where: 'book_source_url = ?',
      whereArgs: [url],
    );
  }

  Future<void> delete(String url) async {
    final db = await _database;
    await db.delete(
      'sources',
      where: 'book_source_url = ?',
      whereArgs: [url],
    );
  }

  Future<void> clear() async {
    final db = await _database;
    await db.delete('sources');
  }

  Future<int> count() async {
    final db = await _database;
    final rows = await db.rawQuery('SELECT COUNT(*) AS c FROM sources');
    return Sqflite.firstIntValue(rows) ?? 0;
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

    final BookSource source = jsonMap.isNotEmpty
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

    source.enabled = (row['enabled'] as int? ?? 1) == 1;
    source.customOrder = row['custom_order'] as int? ?? 0;
    source.weight = row['weight'] as int? ?? 0;
    source.lastUpdateTime = row['last_update_time'] as int? ?? 0;
    source.respondTime = row['respond_time'] as int? ?? 0;
    source.rawJson = raw;
    source.bookSourceUrl =
        row['book_source_url'] as String? ?? source.bookSourceUrl;
    source.bookSourceName =
        row['book_source_name'] as String? ?? source.bookSourceName;
    final searchUrl = row['search_url'] as String? ?? '';
    if (searchUrl.isNotEmpty) source.searchUrl = searchUrl;
    final header = row['header'] as String? ?? '';
    if (header.isNotEmpty) source.header = header;
    return source;
  }

  Map<String, Object?> _toRow(BookSource source) {
    final raw = source.rawJson.isNotEmpty
        ? source.rawJson
        : jsonEncode(source.toLegadoJson());
    return {
      'book_source_url': source.bookSourceUrl,
      'book_source_name': source.bookSourceName,
      'book_source_group': source.bookSourceGroup,
      'book_source_type': source.bookSourceType,
      'enabled': source.enabled ? 1 : 0,
      'custom_order': source.customOrder,
      'weight': source.weight,
      'search_url': source.searchUrl,
      'explore_url': source.exploreUrl,
      'header': source.header,
      'raw_json': raw,
      'last_update_time': source.lastUpdateTime,
      'respond_time': source.respondTime,
      'last_check_time': 0,
    };
  }
}
