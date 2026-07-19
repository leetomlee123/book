import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';

/// Single SQLite database for the novel reader.
///
/// Single SQLite database for the novel reader (shelf + chapters + page cache).
///
/// No forward migration from books.db / chapters.db — those files are deleted
/// on first launch (see [wipeLegacyDatabases]). Book sources stay in
/// `sources.db` via [SourceDao] and are intentionally not wiped.
class ReaderDatabase {
  ReaderDatabase._();
  static final ReaderDatabase instance = ReaderDatabase._();

  static const int version = 1;
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
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
    );
  }

  Future<void> _onCreate(Database db, int version) async {
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

  Future<void> close() async {
    await _db?.close();
    _db = null;
  }

  /// Delete legacy multi-file DBs (no data migration).
  ///
  /// Keeps `sources.db` — still owned by [SourceDao].
  static Future<void> wipeLegacyDatabases() async {
    final dir = await getApplicationDocumentsDirectory();
    for (final name in [
      'books.db',
      'chapters.db',
      'movies.db',
      'cord.db',
      'voice.db',
      'books.db-journal',
      'chapters.db-journal',
      'books.db-wal',
      'chapters.db-wal',
      'books.db-shm',
      'chapters.db-shm',
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
