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
  }

  ui.Picture putIfAbsent(String key, ui.Picture Function() ifAbsent) {
    final existing = _entries[key];
    if (existing != null) return existing;
    final created = ifAbsent();
    _entries[key] = created;
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

  /// Drop pictures outside [centerChapter]±1 for [bookId], then hard-cap size.
  void prune({
    required String bookId,
    required int centerChapter,
  }) {
    if (_entries.isEmpty) return;
    final id = bookId;
    final keepCur = {centerChapter - 1, centerChapter, centerChapter + 1};
    final dropKeys = <String>[];
    _entries.forEach((key, _) {
      if (!key.startsWith(id)) {
        dropKeys.add(key);
        return;
      }
      final rest = key.substring(id.length);
      for (final c in keepCur) {
        if (c < 0) continue;
        if (rest.startsWith('$c')) return;
      }
      dropKeys.add(key);
    });
    for (final k in dropKeys) {
      remove(k);
    }
    if (_entries.length > maxEntries) {
      final keys = _entries.keys.toList();
      final drop = keys.length - maxEntries;
      for (var i = 0; i < drop; i++) {
        remove(keys[i]);
      }
    }
  }
}
