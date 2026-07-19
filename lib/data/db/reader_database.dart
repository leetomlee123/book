import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// Single SQLite database for the novel reader.
///
/// Holds shelf (`books`), chapter cache (`chapters`), and book sources
/// (`sources`). No forward migration from legacy multi-file DBs — those are
/// deleted on boot (see [wipeLegacyDatabases]).
class ReaderDatabase {
  ReaderDatabase._();
  static final ReaderDatabase instance = ReaderDatabase._();

  /// Schema version. Bumped when tables change; no upgrade path — wipe+recreate.
  static const int version = 2;
  static const String fileName = 'reader.db';

  Database? _db;

  Future<Database> get database async {
    final existing = _db;
    if (existing != null) return existing;
    _db = await _open();
    return _db!;
  }

  Future<Database> _open() async {
    final dir = await getApplicationDocumentsDirectory();
    final path = p.join(dir.path, fileName);
    return openDatabase(
      path,
      version: version,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await _createBooks(db);
    await _createChapters(db);
    await _createSources(db);
  }

  /// No data migration — rebuild tables when schema version jumps.
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    await db.execute('DROP TABLE IF EXISTS chapters');
    await db.execute('DROP TABLE IF EXISTS books');
    await db.execute('DROP TABLE IF EXISTS sources');
    await _onCreate(db, newVersion);
  }

  Future<void> _createBooks(Database db) async {
    await db.execute('''
CREATE TABLE books (
  id TEXT PRIMARY KEY NOT NULL,
  name TEXT NOT NULL DEFAULT '',
  author TEXT NOT NULL DEFAULT '',
  cover_url TEXT NOT NULL DEFAULT '',
  category TEXT NOT NULL DEFAULT '',
  description TEXT NOT NULL DEFAULT '',
  source_url TEXT NOT NULL DEFAULT '',
  book_url TEXT NOT NULL DEFAULT '',
  origin_name TEXT NOT NULL DEFAULT '',
  toc_url TEXT NOT NULL DEFAULT '',
  chapter_index INTEGER NOT NULL DEFAULT 0,
  page_index INTEGER NOT NULL DEFAULT 0,
  scroll_offset REAL NOT NULL DEFAULT 0,
  reading_chapter TEXT NOT NULL DEFAULT '',
  latest_chapter TEXT NOT NULL DEFAULT '',
  sort_time INTEGER NOT NULL DEFAULT 0,
  has_update INTEGER NOT NULL DEFAULT 0,
  updated_at TEXT NOT NULL DEFAULT ''
)''');
    await db.execute(
      'CREATE INDEX idx_books_sort ON books (sort_time DESC)',
    );
  }

  Future<void> _createChapters(Database db) async {
    await db.execute('''
CREATE TABLE chapters (
  id TEXT PRIMARY KEY NOT NULL,
  book_id TEXT NOT NULL,
  title TEXT NOT NULL DEFAULT '',
  url TEXT NOT NULL DEFAULT '',
  source_url TEXT NOT NULL DEFAULT '',
  ord INTEGER NOT NULL DEFAULT 0,
  body TEXT NOT NULL DEFAULT '',
  has_body INTEGER NOT NULL DEFAULT 0,
  content_len INTEGER NOT NULL DEFAULT 0,
  pages_json TEXT,
  layout_fp TEXT,
  pages_cached_at INTEGER NOT NULL DEFAULT 0,
  FOREIGN KEY (book_id) REFERENCES books (id) ON DELETE CASCADE
)''');
    await db.execute(
      'CREATE INDEX idx_chapters_book ON chapters (book_id)',
    );
    await db.execute(
      'CREATE UNIQUE INDEX idx_chapters_book_ord ON chapters (book_id, ord)',
    );
    await db.execute(
      'CREATE INDEX idx_chapters_url ON chapters (url)',
    );
  }

  Future<void> _createSources(Database db) async {
    await db.execute('''
CREATE TABLE sources (
  book_source_url TEXT PRIMARY KEY NOT NULL,
  book_source_name TEXT NOT NULL DEFAULT '',
  book_source_group TEXT NOT NULL DEFAULT '',
  book_source_type INTEGER NOT NULL DEFAULT 0,
  enabled INTEGER NOT NULL DEFAULT 1,
  custom_order INTEGER NOT NULL DEFAULT 0,
  weight INTEGER NOT NULL DEFAULT 0,
  search_url TEXT NOT NULL DEFAULT '',
  explore_url TEXT NOT NULL DEFAULT '',
  header TEXT NOT NULL DEFAULT '',
  raw_json TEXT NOT NULL DEFAULT '',
  last_update_time INTEGER NOT NULL DEFAULT 0,
  respond_time INTEGER NOT NULL DEFAULT 0,
  last_check_time INTEGER NOT NULL DEFAULT 0
)''');
    await db.execute(
      'CREATE INDEX idx_sources_order ON sources (custom_order ASC)',
    );
  }

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  /// Delete legacy multi-file DBs (no data migration).
  ///
  /// Also drops standalone `sources.db` — sources now live in [fileName].
  static Future<void> wipeLegacyDatabases() async {
    final dir = await getApplicationDocumentsDirectory();
    for (final name in [
      'books.db',
      'chapters.db',
      'sources.db',
      'movies.db',
      'cord.db',
      'voice.db',
      'books.db-journal',
      'chapters.db-journal',
      'sources.db-journal',
      'books.db-wal',
      'chapters.db-wal',
      'sources.db-wal',
      'books.db-shm',
      'chapters.db-shm',
      'sources.db-shm',
    ]) {
      final f = File(p.join(dir.path, name));
      if (await f.exists()) {
        try {
          await f.delete();
        } catch (_) {}
      }
    }
  }
}
