import 'dart:async';

import 'package:book/common/app_log.dart';
import 'package:book/common/book_pager.dart';
import 'package:book/common/chapter_cache.dart';
import 'package:book/data/repositories/chapter_repository.dart';
import 'package:book/entity/chapter_node.dart';
import 'package:book/entity/chapter_toc_entry.dart';
import 'package:book/entity/read_page.dart';
import 'package:book/entity/text_line.dart';
import 'package:book/entity/text_page.dart';
import 'package:book/model/reader/text_paginator.dart';
import 'package:flutter/foundation.dart';

typedef ChapterDiskCache = ({String body, String? pagesJson, String? layoutFp});

/// Loads one chapter body + paginated [TextPage]s (disk cache → network → layout).
class ChapterContentLoader {
  ChapterContentLoader({
    required this.chaptersRepo,
    required this.paginator,
    required this.fetchContent,
  });

  final ChapterRepository chaptersRepo;
  final TextPaginator paginator;
  final Future<String> Function(String chapterId, {int? idx}) fetchContent;

  ChapterRepository get _chapters => chaptersRepo;
  TextPaginator get _paginator => paginator;
  Future<String> Function(String chapterId, {int? idx}) get _fetchContent =>
      fetchContent;

  /// Prefer [warm] hit, then SQLite, then network; paginate and persist layout.
  Future<ReadPage?> load({
    required List<ChapterTocEntry> chapters,
    required int idx,
    required Map<String, ChapterDiskCache> warm,
    String? bookId,
    int bookChapterIndex = 0,
    Future<ReadPage> Function(String title, String message)? messagePage,
  }) async {
    if (chapters.isEmpty) {
      return messagePage?.call('目录为空', '暂无章节，请检查书源或网络后重试。');
    }
    if (idx < 0) {
      final r = ReadPage.kong();
      r.chapterName = '1';
      r.chapterContent = '已经是第一章';
      return r;
    }
    if (idx >= chapters.length) {
      final r = ReadPage.kong();
      r.chapterName = '-1';
      r.chapterContent = '没有更多内容,等待作者更新';
      return null;
    }

    final chapter = chapters[idx];
    final r = ReadPage.kong();
    r.chapterName = chapter.title;
    final chapterId = chapter.id;

    var contentSource = 'empty';
    String? cachedPagesJson;
    String? cachedLayoutFp;
    try {
      final disk =
          warm.remove(chapterId) ?? await _chapters.getChapterCache(chapterId);
      r.chapterContent = disk.body;
      cachedPagesJson = disk.pagesJson;
      cachedLayoutFp = disk.layoutFp;
      if (r.chapterContent.isNotEmpty) contentSource = 'db';
    } catch (_) {
      r.chapterContent = '';
    }

    final cached = r.chapterContent;
    final cacheLooksBad = cached.isEmpty ||
        (cached.length < 120 &&
            !cached.startsWith('章节内容加载失败') &&
            !cached.startsWith('书源不存在') &&
            !cached.startsWith('章节地址为空') &&
            !cached.startsWith('内容为空'));
    if (cacheLooksBad) {
      final fresh = await _fetchContent(chapterId, idx: idx);
      if (fresh.isNotEmpty &&
          !fresh.startsWith('章节内容加载失败') &&
          !fresh.startsWith('书源不存在') &&
          !fresh.startsWith('章节地址为空') &&
          fresh.length > cached.length) {
        r.chapterContent = fresh;
        contentSource = 'network';
        cachedPagesJson = null;
        cachedLayoutFp = null;
        await _chapters.updateBodies([ChapterNode(r.chapterContent, chapterId)]);
        chapters[idx].hasBody = true;
      } else if (r.chapterContent.isEmpty) {
        r.chapterContent = fresh.isNotEmpty
            ? fresh
            : '章节内容加载失败，请检查书源或换源后重试';
        contentSource = fresh.isNotEmpty ? 'network-error-text' : 'fail';
      }
    }

    _logContentDiag(idx, r.chapterName, r.chapterContent, contentSource);

    final layout = _paginator.layoutParams();
    final contentSig = _paginator.contentSignature(r.chapterContent);
    final fp = _paginator.layoutFingerprint(
      layoutParams: layout,
      contentLen: r.chapterContent.length,
      contentSig: contentSig,
    );

    List<TextPage>? cachedPages;
    try {
      if (cachedPagesJson != null &&
          cachedPagesJson.isNotEmpty &&
          cachedLayoutFp == fp) {
        cachedPages =
            await ChapterRepository.decodePagesJson(cachedPagesJson);
        if (cachedPages != null && cachedPages.isNotEmpty) {
          AppLog.i(
            'Read',
            'page cache HIT idx=$idx id=$chapterId pages=${cachedPages.length}',
          );
        }
      } else if (cachedPagesJson != null && cachedPagesJson.isNotEmpty) {
        AppLog.i(
          'Read',
          'page cache STALE idx=$idx fp=$cachedLayoutFp want=$fp',
        );
      }
    } catch (e) {
      AppLog.w('Read', 'page cache read failed idx=$idx', error: e);
    }

    if (cachedPages != null && cachedPages.isNotEmpty) {
      r.pages = cachedPages;
      debugPrint(
        '[PagerEngine] CACHE_HIT idx=$idx pages=${cachedPages.length} '
        'nativeAvailable=${BookPager.isAvailable} '
        '(layout not re-run; open a new chapter or change font to force paginate)',
      );
      AppLog.i(
        'Pager',
        'CACHE_HIT idx=$idx pages=${cachedPages.length} '
            'native=${BookPager.isAvailable}',
      );
    } else {
      var layoutComplete = false;
      try {
        // Neighbor preloads must not cancel each other / the open chapter.
        final outcome = await _paginator.paginateProgressive(
          r,
          cancelPrevious: false,
        );
        r.pages = outcome.pages;
        layoutComplete = outcome.complete;
        debugPrint(
          '[PagerEngine] progressive engine=${outcome.engine} '
          'pages=${r.pages.length} complete=${outcome.complete} '
          'reason=${outcome.fallbackReason ?? "-"}',
        );
        AppLog.i(
          'Pager',
          'progressive engine=${outcome.engine} pages=${r.pages.length} '
              'complete=${outcome.complete} reason=${outcome.fallbackReason ?? "-"}',
        );
        // Incomplete progressive results (cancelled mid-chapter) must not be
        // treated as final layout — one-page leftovers make "next" jump chapters.
        if (!outcome.complete) {
          AppLog.w(
            'Pager',
            'progressive incomplete idx=$idx pages=${r.pages.length} '
                '→ full re-paginate',
          );
          r.pages = await _paginator.paginate(r);
          layoutComplete = r.pages.isNotEmpty;
        }
      } catch (e, st) {
        AppLog.e('Read', 'paginateProgressive failed idx=$idx',
            error: e, stackTrace: st);
        r.pages = const [];
        layoutComplete = false;
      }

      if (r.pages.isEmpty) {
        try {
          r.pages = await _paginator.paginate(r);
          layoutComplete = r.pages.isNotEmpty;
        } catch (e, st) {
          AppLog.e('Read', 'parseContentAsync retry failed idx=$idx',
              error: e, stackTrace: st);
        }
        if (r.pages.isEmpty) {
          r.pages = fallbackPages(r.chapterContent);
          layoutComplete = r.pages.isNotEmpty;
        }
      }

      // Only persist complete layouts — never cache a truncated first page.
      if (layoutComplete &&
          r.pages.isNotEmpty &&
          contentSource != 'fail' &&
          contentSource != 'network-error-text' &&
          !r.chapterContent.startsWith('章节内容加载失败')) {
        final pagesToSave = r.pages;
        final saveId = chapterId;
        final saveFp = fp;
        final activeBookId = bookId;
        final cur = bookChapterIndex;
        unawaited(() async {
          try {
            final json = await ChapterRepository.encodePagesJson(pagesToSave);
            if (json.length > 2 * 1024 * 1024) {
              AppLog.w(
                'Read',
                'skip page cache write idx=$idx size=${json.length}',
              );
              return;
            }
            await _chapters.savePageLayout(saveId, json, saveFp);
            await ChapterCache.maybeEvict(
              activeBookId: activeBookId,
              activeCur: cur,
            );
          } catch (e) {
            AppLog.w('Read', 'page cache write failed idx=$idx', error: e);
          }
        }());
      }
    }

    _logPageDiag(idx, r);
    return r;
  }

  /// Wrap plain text into simple pages when the normal pager failed.
  List<TextPage> fallbackPages(String content) {
    final text = content.trim();
    if (text.isEmpty) {
      return [TextPage([TextLine.simple('内容为空')], 24)];
    }
    try {
      final pages = _paginator.paginateSync(
        ReadPage(text, '', 0, const []),
        shouldJustifyHeight: false,
      );
      if (pages.isNotEmpty) return pages;
    } catch (_) {}
    // Absolute last resort: one long line page.
    return [TextPage([TextLine.simple(text)], 24)];
  }

  void _logContentDiag(
    int idx,
    String name,
    String content,
    String source,
  ) {
    final text = content;
    final len = text.length;
    final nl = '\n'.allMatches(text).length;
    final crlf = '\r\n'.allMatches(text).length;
    final br =
        RegExp(r'<br\s*/?>', caseSensitive: false).allMatches(text).length;
    final pTag = RegExp(r'</p>', caseSensitive: false).allMatches(text).length;
    final lines = text.split('\n');
    var maxLine = 0;
    for (final l in lines) {
      if (l.length > maxLine) maxLine = l.length;
    }
    final preview = text.length <= 120
        ? text.replaceAll('\n', r'\n')
        : '${text.substring(0, 120).replaceAll('\n', r'\n')}…';
    final verdict = (len > 80 && nl == 0 && br == 0 && pTag == 0)
        ? 'CONTENT_ONE_BLOB'
        : (len <= 40 ? 'CONTENT_SHORT' : 'CONTENT_HAS_BREAKS');
    AppLog.i(
      'ReadDiag',
      'CONTENT idx=$idx name=$name src=$source '
          'len=$len newlines=$nl crlf=$crlf br=$br pTag=$pTag '
          'splitLines=${lines.length} maxLineLen=$maxLine '
          'verdict=$verdict preview="$preview"',
    );
  }

  void _logPageDiag(int idx, ReadPage r) {
    final pages = r.pages;
    final totalLines = pages.fold<int>(0, (n, p) => n + p.lines.length);
    final lines0 = pages.isEmpty ? 0 : pages.first.lines.length;
    final firstLine = (pages.isEmpty || pages.first.lines.isEmpty)
        ? ''
        : pages.first.lines.first.text;
    final firstLineLen = firstLine.length;
    var maxLineChars = 0;
    for (final p in pages) {
      for (final l in p.lines) {
        final c = l.text.length;
        if (c > maxLineChars) maxLineChars = c;
      }
    }
    final contentLen = r.chapterContent.length;
    String verdict;
    if (contentLen > 80 && totalLines <= 1) {
      verdict = 'PAGE_BROKEN_ONE_LINE';
    } else if (contentLen > 80 && maxLineChars > 80) {
      verdict = 'PAGE_OVERLONG_LINE';
    } else if (contentLen <= 40) {
      verdict = 'PAGE_OK_SHORT_CONTENT';
    } else {
      verdict = 'PAGE_OK';
    }
    AppLog.i(
      'ReadDiag',
      'PAGE idx=$idx name=${r.chapterName} contentLen=$contentLen '
          'pages=${pages.length} totalLines=$totalLines lines0=$lines0 '
          'firstLineLen=$firstLineLen maxLineChars=$maxLineChars '
          'verdict=$verdict firstLine="${firstLine.length > 60 ? '${firstLine.substring(0, 60)}…' : firstLine}"',
    );
  }
}
