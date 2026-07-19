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
    _entries[key] = value;
  }

  ui.Picture putIfAbsent(String key, ui.Picture Function() ifAbsent) {
    return _entries.putIfAbsent(key, ifAbsent);
  }

  void clear() => _entries.clear();

  void remove(String key) => _entries.remove(key);

  /// Drop pictures outside [centerChapter]±1 for [bookId], then hard-cap size.
  void prune({
    required String bookId,
    required int centerChapter,
  }) {
    if (_entries.isEmpty) return;
    final id = bookId;
    final keepCur = {centerChapter - 1, centerChapter, centerChapter + 1};
    _entries.removeWhere((key, _) {
      if (!key.startsWith(id)) return true;
      final rest = key.substring(id.length);
      for (final c in keepCur) {
        if (c < 0) continue;
        if (rest.startsWith('$c')) return false;
      }
      return true;
    });
    if (_entries.length > maxEntries) {
      final keys = _entries.keys.toList();
      final drop = keys.length - maxEntries;
      for (var i = 0; i < drop; i++) {
        _entries.remove(keys[i]);
      }
    }
  }
}
