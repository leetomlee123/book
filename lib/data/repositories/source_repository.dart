import 'dart:convert';

import 'package:book/data/db/reader_database.dart';
import 'package:book/source/import/source_importer.dart';
import 'package:book/source/model/book_source.dart';
import 'package:sqflite/sqflite.dart';

/// Book-source persistence on [ReaderDatabase] (`sources` table).
///
/// List / filter APIs deliberately omit `raw_json` so sqflite does not push
/// multi‑MB MethodChannel payloads (Android 256MB heap OOM on import reload).
/// Full rule payloads are loaded only via [getByUrl] / [getByUrls].
class SourceRepository {
  SourceRepository({ReaderDatabase? db}) : _db = db ?? ReaderDatabase.instance;

  final ReaderDatabase _db;
  static final SourceRepository instance = SourceRepository();

  /// Columns needed for UI lists and searchability checks (no `raw_json`).
  static const List<String> _metaColumns = [
    'book_source_url',
    'book_source_name',
    'book_source_group',
    'book_source_type',
    'enabled',
    'custom_order',
    'weight',
    'search_url',
    'explore_url',
    'header',
    'last_update_time',
    'respond_time',
  ];

  /// Cap rows / batch ops so MethodChannel envelopes stay well under heap.
  static const int _channelChunk = 80;

  Future<Database> get _database => _db.database;

  /// Lightweight list for 书源管理 — excludes `raw_json`.
  Future<List<BookSource>> getAll() async {
    final db = await _database;
    final rows = await db.query(
      'sources',
      columns: _metaColumns,
      orderBy: 'custom_order ASC, book_source_name ASC',
    );
    return rows.map(_fromMetaRow).toList();
  }

  /// Lightweight enabled list (no rules). Hydrate with [getByUrls] before engine use.
  Future<List<BookSource>> getEnabled() async {
    final db = await _database;
    final rows = await db.query(
      'sources',
      columns: _metaColumns,
      where: 'enabled = 1',
      orderBy: 'custom_order ASC, weight DESC',
    );
    return rows.map(_fromMetaRow).toList();
  }

  Future<BookSource?> getByUrl(String url) async {
    final db = await _database;
    final rows = await db.query(
      'sources',
      where: 'book_source_url = ?',
      whereArgs: [url],
    );
    if (rows.isEmpty) return null;
    return _fromFullRow(rows.first);
  }

  /// Load full sources (with rules) for [urls], chunked to avoid channel OOM.
  Future<List<BookSource>> getByUrls(List<String> urls) async {
    if (urls.isEmpty) return [];
    final db = await _database;
    final out = <BookSource>[];
    for (var i = 0; i < urls.length; i += _channelChunk) {
      final part = urls.sublist(
        i,
        i + _channelChunk > urls.length ? urls.length : i + _channelChunk,
      );
      final placeholders = List.filled(part.length, '?').join(',');
      final rows = await db.rawQuery(
        'SELECT * FROM sources WHERE book_source_url IN ($placeholders)',
        part,
      );
      // Preserve caller order.
      final byUrl = <String, BookSource>{
        for (final r in rows) (r['book_source_url'] as String? ?? ''): _fromFullRow(r),
      };
      for (final u in part) {
        final s = byUrl[u];
        if (s != null) out.add(s);
      }
    }
    return out;
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
    await upsertAllWithStats(sources);
  }

  /// Upsert sources and report how many rows were newly inserted vs replaced.
  ///
  /// Existing `enabled` flags are preserved on update so re-importing a source
  /// the user disabled does not re-enable it.
  ///
  /// Writes are committed in chunks so large imports do not assemble one giant
  /// MethodChannel argument list.
  Future<SourceUpsertStats> upsertAllWithStats(List<BookSource> sources) async {
    if (sources.isEmpty) {
      return const SourceUpsertStats(inserted: 0, updated: 0);
    }
    final db = await _database;
    final urls = sources.map((s) => s.bookSourceUrl).toList();
    final existingEnabled = <String, bool>{};
    for (var i = 0; i < urls.length; i += _channelChunk) {
      final part = urls.sublist(
        i,
        i + _channelChunk > urls.length ? urls.length : i + _channelChunk,
      );
      final placeholders = List.filled(part.length, '?').join(',');
      final rows = await db.rawQuery(
        'SELECT book_source_url, enabled FROM sources '
        'WHERE book_source_url IN ($placeholders)',
        part,
      );
      for (final r in rows) {
        final u = r['book_source_url'] as String? ?? '';
        if (u.isEmpty) continue;
        existingEnabled[u] = (r['enabled'] as int? ?? 1) == 1;
      }
    }

    var inserted = 0;
    var updated = 0;
    for (var i = 0; i < sources.length; i += _channelChunk) {
      final part = sources.sublist(
        i,
        i + _channelChunk > sources.length ? sources.length : i + _channelChunk,
      );
      final batch = db.batch();
      for (final s in part) {
        if (existingEnabled.containsKey(s.bookSourceUrl)) {
          s.enabled = existingEnabled[s.bookSourceUrl]!;
          updated++;
        } else {
          inserted++;
        }
        batch.insert(
          'sources',
          _toRow(s),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      }
      await batch.commit(noResult: true);
    }
    return SourceUpsertStats(inserted: inserted, updated: updated);
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

  Future<void> setEnabledMany(List<String> urls, bool enabled) async {
    if (urls.isEmpty) return;
    final db = await _database;
    for (var i = 0; i < urls.length; i += _channelChunk) {
      final part = urls.sublist(
        i,
        i + _channelChunk > urls.length ? urls.length : i + _channelChunk,
      );
      final batch = db.batch();
      for (final url in part) {
        batch.update(
          'sources',
          {'enabled': enabled ? 1 : 0},
          where: 'book_source_url = ?',
          whereArgs: [url],
        );
      }
      await batch.commit(noResult: true);
    }
  }

  Future<void> deleteMany(List<String> urls) async {
    if (urls.isEmpty) return;
    final db = await _database;
    for (var i = 0; i < urls.length; i += _channelChunk) {
      final part = urls.sublist(
        i,
        i + _channelChunk > urls.length ? urls.length : i + _channelChunk,
      );
      final batch = db.batch();
      for (final url in part) {
        batch.delete(
          'sources',
          where: 'book_source_url = ?',
          whereArgs: [url],
        );
      }
      await batch.commit(noResult: true);
    }
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

  Future<int> countEnabled() async {
    final db = await _database;
    final rows = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM sources WHERE enabled = 1',
    );
    return Sqflite.firstIntValue(rows) ?? 0;
  }

  /// Stream raw JSON blobs for export without holding the full table in one
  /// MethodChannel response.
  Future<List<dynamic>> loadAllRawJsonMaps() async {
    final db = await _database;
    final countRows = await db.rawQuery('SELECT COUNT(*) AS c FROM sources');
    final total = Sqflite.firstIntValue(countRows) ?? 0;
    final list = <dynamic>[];
    for (var offset = 0; offset < total; offset += _channelChunk) {
      final rows = await db.query(
        'sources',
        columns: ['raw_json', 'book_source_url', 'book_source_name'],
        orderBy: 'custom_order ASC, book_source_name ASC',
        limit: _channelChunk,
        offset: offset,
      );
      for (final row in rows) {
        final raw = (row['raw_json'] as String?) ?? '';
        if (raw.isNotEmpty) {
          try {
            list.add(jsonDecode(raw));
            continue;
          } catch (_) {}
        }
        // Fallback: rebuild minimal object from columns if raw missing.
        list.add({
          'bookSourceUrl': row['book_source_url'] ?? '',
          'bookSourceName': row['book_source_name'] ?? '',
        });
      }
    }
    return list;
  }

  BookSource _fromMetaRow(Map<String, Object?> row) {
    return BookSource(
      bookSourceUrl: row['book_source_url'] as String? ?? '',
      bookSourceName: row['book_source_name'] as String? ?? '',
      bookSourceGroup: row['book_source_group'] as String? ?? '',
      bookSourceType: row['book_source_type'] as int? ?? 0,
      enabled: (row['enabled'] as int? ?? 1) == 1,
      customOrder: row['custom_order'] as int? ?? 0,
      weight: row['weight'] as int? ?? 0,
      searchUrl: row['search_url'] as String? ?? '',
      exploreUrl: row['explore_url'] as String? ?? '',
      header: row['header'] as String? ?? '',
      lastUpdateTime: row['last_update_time'] as int? ?? 0,
      respondTime: row['respond_time'] as int? ?? 0,
      rawJson: '',
    );
  }

  BookSource _fromFullRow(Map<String, Object?> row) {
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
    final exploreUrl = row['explore_url'] as String? ?? '';
    if (exploreUrl.isNotEmpty) source.exploreUrl = exploreUrl;
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
