import 'package:book/source/model/search_book.dart';
import 'package:book/source/util/text_clean.dart';

/// Map reading progress from [oldName]/[oldIndex] onto a new TOC.
class ProgressMapper {
  /// Returns the best chapter index in [newChapters].
  static int map({
    required String? oldName,
    required int oldIndex,
    required List<SourceChapter> newChapters,
  }) {
    if (newChapters.isEmpty) return 0;
    if (oldName != null && oldName.isNotEmpty) {
      // 1 exact
      for (var i = 0; i < newChapters.length; i++) {
        if (newChapters[i].name == oldName) return i;
      }
      // 2 normalized
      final norm = normalizeChapterTitle(oldName);
      if (norm.isNotEmpty) {
        for (var i = 0; i < newChapters.length; i++) {
          if (normalizeChapterTitle(newChapters[i].name) == norm) return i;
        }
        // 3 contains either way
        for (var i = 0; i < newChapters.length; i++) {
          final n = normalizeChapterTitle(newChapters[i].name);
          if (n.isEmpty) continue;
          if (n.contains(norm) || norm.contains(n)) return i;
        }
      }
    }
    // 4 same index if lengths similar
    if (oldIndex >= 0) {
      if ((newChapters.length - (oldIndex + 1)).abs() <=
              (newChapters.length * 0.1).ceil() + 2 ||
          oldIndex < newChapters.length) {
        return oldIndex.clamp(0, newChapters.length - 1);
      }
    }
    return 0;
  }
}
