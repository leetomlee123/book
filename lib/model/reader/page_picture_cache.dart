import 'dart:ui' as ui;

/// Bounded in-memory cache of painted page pictures.
class PagePictureCache {
  PagePictureCache({this.maxEntries = 24});

  final int maxEntries;
  final Map<String, ui.Picture> _entries = {};

  Map<String, ui.Picture> get map => _entries;

  int get length => _entries.length;
  bool get isEmpty => _entries.isEmpty;

  bool containsKey(String key) => _entries.containsKey(key);

  ui.Picture? operator [](String key) => _entries[key];

  void operator []=(String key, ui.Picture value) {
    final prev = _entries[key];
    if (prev != null && !identical(prev, value)) {
      prev.dispose();
    }
    _entries[key] = value;
    _enforceCap();
  }

  /// Insert if missing; always enforce [maxEntries] after insert.
  ui.Picture putIfAbsent(String key, ui.Picture Function() ifAbsent) {
    final existing = _entries[key];
    if (existing != null) return existing;
    final created = ifAbsent();
    _entries[key] = created;
    _enforceCap(protectKey: key);
    return created;
  }

  void clear() {
    for (final p in _entries.values) {
      p.dispose();
    }
    _entries.clear();
  }

  void remove(String key) {
    _entries.remove(key)?.dispose();
  }

  /// Drop entries outside [centerChapter]±1 for [bookId], then hard-cap size.
  ///
  /// Keys: `bookId|chapter|page` or `bookId|chapter|page|sc`
  /// (see [PagePictureResolver]).
  void prune({
    required String bookId,
    required int centerChapter,
  }) {
    if (_entries.isEmpty) return;
    final keepCur = {
      for (final c in [centerChapter - 1, centerChapter, centerChapter + 1])
        if (c >= 0) c,
    };
    final dropKeys = <String>[];
    _entries.forEach((key, _) {
      final parsed = parseKey(key);
      if (parsed == null) {
        if (!key.startsWith(bookId)) dropKeys.add(key);
        return;
      }
      if (parsed.bookId != bookId || !keepCur.contains(parsed.chapterIndex)) {
        dropKeys.add(key);
      }
    });
    for (final k in dropKeys) {
      remove(k);
    }
    _enforceCap();
  }

  void _enforceCap({String? protectKey}) {
    if (_entries.length <= maxEntries) return;
    // LinkedHashMap preserves insertion order — drop oldest first.
    final keys = _entries.keys.toList();
    for (final k in keys) {
      if (_entries.length <= maxEntries) break;
      if (protectKey != null && k == protectKey) continue;
      remove(k);
    }
  }

  /// Parse `bookId|chapter|page` or `bookId|chapter|page|sc`.
  static ({String bookId, int chapterIndex, int pageIndex, bool scroll})?
      parseKey(String key) {
    final parts = key.split('|');
    if (parts.length == 3) {
      final c = int.tryParse(parts[1]);
      final p = int.tryParse(parts[2]);
      if (c == null || p == null) return null;
      return (bookId: parts[0], chapterIndex: c, pageIndex: p, scroll: false);
    }
    if (parts.length == 4 && parts[3] == 'sc') {
      final c = int.tryParse(parts[1]);
      final p = int.tryParse(parts[2]);
      if (c == null || p == null) return null;
      return (bookId: parts[0], chapterIndex: c, pageIndex: p, scroll: true);
    }
    return null;
  }
}
