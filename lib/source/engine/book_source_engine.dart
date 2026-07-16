import 'package:book/common/app_log.dart';
import 'package:book/entity/BookInfo.dart';
import 'package:book/source/model/book_source.dart';
import 'package:book/source/model/search_book.dart';
import 'package:book/source/net/analyze_url.dart';
import 'package:book/source/rule/analyze_rule.dart';
import 'package:book/source/util/book_id.dart';
import 'package:book/source/util/url_join.dart';
import 'package:html/dom.dart';

/// Core pipeline: search / detail / toc / content via book-source rules.
class BookSourceEngine {
  static const int maxTocPages = 30;
  static const int maxContentPages = 20;
  static const Duration sourceTimeout = Duration(seconds: 12);

  Future<List<SearchBook>> search(
    BookSource source,
    String key,
    int page,
  ) async {
    if (source.searchUrl.isEmpty || key.isEmpty) return const [];
    AppLog.d('Source', 'search "${source.bookSourceName}" key=$key page=$page');
    try {
      final resp = await AnalyzeUrl.fetch(
        source,
        source.searchUrl,
        key: key,
        page: page,
      ).timeout(sourceTimeout);
      final rule = AnalyzeRule(
        content: resp.body,
        baseUrl: resp.url,
        isJson: resp.isJson,
      );
      final listRule = source.ruleSearch.bookList;
      final items = rule.getList(listRule);
      final out = <SearchBook>[];
      for (final item in items) {
        final name = rule.getString(source.ruleSearch.name, scope: item);
        if (name.isEmpty) continue;
        var bookUrl = rule.getString(source.ruleSearch.bookUrl, scope: item);
        if (bookUrl.isEmpty && item is Element) {
          bookUrl = item.attributes['href'] ?? '';
        }
        bookUrl = urlJoin(resp.url, bookUrl);
        if (bookUrl.isEmpty) continue;
        var cover = rule.getString(source.ruleSearch.coverUrl, scope: item);
        if (cover.isNotEmpty) cover = urlJoin(resp.url, cover);
        out.add(SearchBook(
          name: name,
          author: rule.getString(source.ruleSearch.author, scope: item),
          kind: rule.getString(source.ruleSearch.kind, scope: item),
          wordCount: rule.getString(source.ruleSearch.wordCount, scope: item),
          lastChapter:
              rule.getString(source.ruleSearch.lastChapter, scope: item),
          intro: rule.getString(source.ruleSearch.intro, scope: item),
          coverUrl: cover,
          bookUrl: bookUrl,
          sourceUrl: source.bookSourceUrl,
          sourceName: source.bookSourceName,
        ));
      }
      AppLog.i(
        'Source',
        'search ok "${source.bookSourceName}" hits=${out.length}',
      );
      return out;
    } catch (e, st) {
      AppLog.e(
        'Source',
        'search fail "${source.bookSourceName}" key=$key',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  Future<BookInfo> bookInfo(
    BookSource source,
    String bookUrl, {
    SearchBook? seed,
  }) async {
    final resp = await AnalyzeUrl.fetch(
      source,
      '',
      absoluteUrl: bookUrl,
    ).timeout(sourceTimeout);
    final rule = AnalyzeRule(
      content: resp.body,
      baseUrl: resp.url,
      isJson: resp.isJson,
    );
    final r = source.ruleBookInfo;
    String pick(String ruleStr, String fallback) {
      final v = rule.getString(ruleStr);
      return v.isNotEmpty ? v : fallback;
    }

    var cover = pick(r.coverUrl, seed?.coverUrl ?? '');
    if (cover.isNotEmpty) cover = urlJoin(resp.url, cover);
    var tocUrl = pick(r.tocUrl, bookUrl);
    if (tocUrl.isNotEmpty) tocUrl = urlJoin(resp.url, tocUrl);

    final name = pick(r.name, seed?.name ?? '');
    final author = pick(r.author, seed?.author ?? '');
    final intro = pick(r.intro, seed?.intro ?? '');
    final last = pick(r.lastChapter, seed?.lastChapter ?? '');
    final kind = pick(r.kind, seed?.kind ?? '');
    final id = makeBookKey(source.bookSourceUrl, bookUrl);

    final info = BookInfo(
      0,
      author,
      '',
      '',
      kind,
      id,
      name,
      cover,
      0,
      intro,
      '',
      last,
      '',
      '',
      const [],
    );
    info.sourceUrl = source.bookSourceUrl;
    info.bookUrl = bookUrl;
    info.originName = source.bookSourceName;
    info.tocUrl = tocUrl.isEmpty ? bookUrl : tocUrl;
    return info;
  }

  Future<List<SourceChapter>> toc(BookSource source, String tocUrl) async {
    AppLog.d('Source', 'toc "${source.bookSourceName}" url=$tocUrl');
    final all = <SourceChapter>[];
    final seen = <String>{};
    var next = tocUrl;
    var pages = 0;
    try {
      while (next.isNotEmpty && pages < maxTocPages) {
        pages++;
        final resp = await AnalyzeUrl.fetch(
          source,
          '',
          absoluteUrl: next,
        ).timeout(sourceTimeout);
        final rule = AnalyzeRule(
          content: resp.body,
          baseUrl: resp.url,
          isJson: resp.isJson,
        );
        final items = rule.getList(source.ruleToc.chapterList);
        for (final item in items) {
          final name = rule.getString(source.ruleToc.chapterName, scope: item);
          var url = rule.getString(source.ruleToc.chapterUrl, scope: item);
          if (url.isEmpty && item is Element) {
            url = item.attributes['href'] ?? '';
          }
          url = urlJoin(resp.url, url);
          if (name.isEmpty || url.isEmpty) continue;
          if (!seen.add(url)) continue;
          final isVol = source.ruleToc.isVolume.isNotEmpty &&
              rule.getString(source.ruleToc.isVolume, scope: item).isNotEmpty;
          all.add(SourceChapter(
            name: name,
            url: url,
            isVolume: isVol,
            index: all.length,
          ));
        }
        var nextUrl = '';
        if (source.ruleToc.nextTocUrl.isNotEmpty) {
          nextUrl = rule.getString(source.ruleToc.nextTocUrl);
          if (nextUrl.isNotEmpty) nextUrl = urlJoin(resp.url, nextUrl);
        }
        if (nextUrl.isEmpty || nextUrl == next || seen.contains(nextUrl)) break;
        next = nextUrl;
      }
      AppLog.i(
        'Source',
        'toc ok "${source.bookSourceName}" chapters=${all.length} pages=$pages',
      );
      return all;
    } catch (e, st) {
      AppLog.e(
        'Source',
        'toc fail "${source.bookSourceName}" url=$tocUrl',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  Future<String> content(BookSource source, String chapterUrl) async {
    AppLog.d('Source', 'content "${source.bookSourceName}" url=$chapterUrl');
    final buf = StringBuffer();
    var next = chapterUrl;
    var pages = 0;
    final seen = <String>{};
    try {
      while (next.isNotEmpty && pages < maxContentPages) {
        if (!seen.add(next)) break;
        pages++;
        final resp = await AnalyzeUrl.fetch(
          source,
          '',
          absoluteUrl: next,
        ).timeout(sourceTimeout);
        final rule = AnalyzeRule(
          content: resp.body,
          baseUrl: resp.url,
          isJson: resp.isJson,
        );
        String raw;
        if (resp.isJson) {
          raw = rule.getString(source.ruleContent.content);
        } else {
          raw = rule.getHtmlString(source.ruleContent.content);
          if (raw.isEmpty) {
            raw = rule.getString(source.ruleContent.content);
          }
        }
        final part = finalizeContent(raw, source.ruleContent.replaceRegex);
        if (part.isNotEmpty) {
          if (buf.isNotEmpty) buf.writeln();
          buf.write(part);
        }
        var nextUrl = '';
        if (source.ruleContent.nextContentUrl.isNotEmpty) {
          nextUrl = rule.getString(source.ruleContent.nextContentUrl);
          if (nextUrl.isNotEmpty) nextUrl = urlJoin(resp.url, nextUrl);
        }
        if (nextUrl.isEmpty || nextUrl == next) break;
        next = nextUrl;
      }
      final text = buf.toString();
      AppLog.i(
        'Source',
        'content ok "${source.bookSourceName}" len=${text.length} pages=$pages',
      );
      return text;
    } catch (e, st) {
      AppLog.e(
        'Source',
        'content fail "${source.bookSourceName}" url=$chapterUrl',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }
}
