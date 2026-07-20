import 'package:book/common/app_log.dart';
import 'package:book/data/repositories/chapter_repository.dart';
import 'package:book/entity/chapter_node.dart';
import 'package:book/entity/chapter_toc_entry.dart';
import 'package:book/source/engine/book_source_engine.dart';
import 'package:book/source/model/book_source.dart';
import 'package:bot_toast/bot_toast.dart';

/// Network chapter body fetch + optional bulk download into reader.db.
class ChapterDownloadService {
  ChapterDownloadService({
    required this.engine,
    required this.chapters,
  });

  final BookSourceEngine engine;
  final ChapterRepository chapters;

  /// Fetch plain text for one chapter URL via the active source.
  Future<String> fetchBody({
    required BookSource? source,
    required List<ChapterTocEntry> toc,
    required String chapterId,
    int? idx,
  }) async {
    if (source == null) {
      return '书源不存在，请重新搜索添加或换源';
    }
    String chapterUrl = '';
    if (idx != null && idx >= 0 && idx < toc.length) {
      chapterUrl = toc[idx].url;
    } else {
      for (final c in toc) {
        if (c.id == chapterId) {
          chapterUrl = c.url;
          break;
        }
      }
    }
    if (chapterUrl.isEmpty) {
      return '章节地址为空，请重新加载目录';
    }
    try {
      AppLog.d('Read', 'fetch content idx=$idx url=$chapterUrl');
      final content = await engine.content(source, chapterUrl);
      if (content.isEmpty) {
        AppLog.w('Read', 'empty content idx=$idx url=$chapterUrl');
        return '章节内容加载失败，请检查书源或换源后重试';
      }
      AppLog.d('Read', 'content ok idx=$idx len=${content.length}');
      return content;
    } catch (e, st) {
      AppLog.e(
        'Read',
        'content failed idx=$idx url=$chapterUrl',
        error: e,
        stackTrace: st,
      );
      return '章节内容加载失败，请检查书源或换源后重试\n$e';
    }
  }

  /// Download chapter bodies from [start] to end, batching DB writes.
  Future<void> downloadFrom({
    required List<ChapterTocEntry> toc,
    required int start,
    required BookSource? source,
    required String bookName,
    int batchSize = 100,
  }) async {
    if (toc.isEmpty) return;
    final nodes = <ChapterNode>[];
    for (var i = start; i < toc.length; i++) {
      final chapter = toc[i];
      final id = chapter.id;
      if (chapter.hasBody) continue;
      final content = await fetchBody(
        source: source,
        toc: toc,
        chapterId: id,
        idx: i,
      );
      if (content.isNotEmpty &&
          !content.startsWith('章节内容加载失败') &&
          !content.startsWith('书源不存在') &&
          !content.startsWith('章节地址为空')) {
        nodes.add(ChapterNode(content, id));
        chapter.hasBody = true;
      }
      if (nodes.length >= batchSize) {
        await chapters.updateBodies(nodes);
        nodes.clear();
      }
    }
    if (nodes.isNotEmpty) {
      await chapters.updateBodies(nodes);
      nodes.clear();
    }
    BotToast.showText(text: '${bookName.isEmpty ? "本书" : bookName}下载完成');
  }
}
