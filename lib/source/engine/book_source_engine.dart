import 'package:book/common/app_log.dart';
import 'package:book/entity/book_info.dart';
import 'package:book/source/model/book_source.dart';
import 'package:book/source/model/search_book.dart';
import 'package:book/source/net/analyze_url.dart';
import 'package:book/source/rule/analyze_rule.dart';
import 'package:book/source/util/book_id.dart';
import 'package:book/source/util/text_clean.dart';
import 'package:book/source/util/url_join.dart';
import 'package:html/dom.dart';

/// Core pipeline: search / explore / detail / toc / content via book-source rules.
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
      return _parseBookList(
        source,
        resp,
        listRule: source.ruleSearch.bookList,
        nameRule: source.ruleSearch.name,
        authorRule: source.ruleSearch.author,
        kindRule: source.ruleSearch.kind,
        wordCountRule: source.ruleSearch.wordCount,
        lastChapterRule: source.ruleSearch.lastChapter,
        introRule: source.ruleSearch.intro,
        coverRule: source.ruleSearch.coverUrl,
        bookUrlRule: source.ruleSearch.bookUrl,
        logTag: 'search',
      );
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

  /// Discover / category list via [url] template (`{{page}}` filled by AnalyzeUrl).
  /// List fields prefer [BookSource.ruleExplore], fall back to [BookSource.ruleSearch].
  Future<List<SearchBook>> explore(
    BookSource source,
    String url, {
    int page = 1,
  }) async {
    if (url.isEmpty) return const [];
    AppLog.d(
      'Source',
      'explore "${source.bookSourceName}" page=$page url=$url',
    );
    try {
      final resp = await AnalyzeUrl.fetch(
        source,
        url,
        page: page,
      ).timeout(sourceTimeout);
      final er = source.ruleExplore;
      final sr = source.ruleSearch;
      String pick(String a, String b) => a.isNotEmpty ? a : b;
      return _parseBookList(
        source,
        resp,
        listRule: pick(er.bookList, sr.bookList),
        nameRule: pick(er.name, sr.name),
        authorRule: pick(er.author, sr.author),
        kindRule: pick(er.kind, sr.kind),
        wordCountRule: pick(er.wordCount, sr.wordCount),
        lastChapterRule: pick(er.lastChapter, sr.lastChapter),
        introRule: pick(er.intro, sr.intro),
        coverRule: pick(er.coverUrl, sr.coverUrl),
        bookUrlRule: pick(er.bookUrl, sr.bookUrl),
        logTag: 'explore',
      );
    } catch (e, st) {
      AppLog.e(
        'Source',
        'explore fail "${source.bookSourceName}" url=$url',
        error: e,
        stackTrace: st,
      );
      rethrow;
    }
  }

  List<SearchBook> _parseBookList(
    BookSource source,
    SourceResponse resp, {
    required String listRule,
    required String nameRule,
    required String authorRule,
    required String kindRule,
    required String wordCountRule,
    required String lastChapterRule,
    required String introRule,
    required String coverRule,
    required String bookUrlRule,
    required String logTag,
  }) {
    final rule = AnalyzeRule(
      content: resp.body,
      baseUrl: resp.url,
      isJson: resp.isJson,
    );
    final items = listRule.isEmpty ? const <dynamic>[] : rule.getList(listRule);
    final out = <SearchBook>[];
    for (final item in items) {
      final name = rule.getString(nameRule, scope: item);
      if (name.isEmpty) continue;
      var bookUrl = rule.getString(bookUrlRule, scope: item);
      if (bookUrl.isEmpty && item is Element) {
        bookUrl = item.attributes['href'] ?? '';
        if (bookUrl.isEmpty) {
          bookUrl = item.querySelector('a')?.attributes['href'] ?? '';
        }
      }
      bookUrl = urlJoin(resp.url, bookUrl);
      if (bookUrl.isEmpty) continue;
      var cover = rule.getString(coverRule, scope: item);
      if ((cover.isEmpty || _isPlaceholderCover(cover)) && item is Element) {
        final img = item.localName == 'img' ? item : item.querySelector('img');
        if (img != null) {
          cover = rule.getString('img@src', scope: item);
          if (cover.isEmpty) cover = rule.getString('src', scope: img);
        }
      }
      if (cover.isNotEmpty) cover = urlJoin(resp.url, cover);
      if (_isPlaceholderCover(cover)) cover = '';
      out.add(SearchBook(
        name: name,
        author: _resolveAuthor(rule, ruleStr: authorRule, scope: item),
        kind: rule.getString(kindRule, scope: item),
        wordCount: rule.getString(wordCountRule, scope: item),
        lastChapter: rule.getString(lastChapterRule, scope: item),
        intro: rule.getString(introRule, scope: item),
        coverUrl: cover,
        bookUrl: bookUrl,
        sourceUrl: source.bookSourceUrl,
        sourceName: source.bookSourceName,
      ));
    }
    AppLog.i(
      'Source',
      '$logTag ok "${source.bookSourceName}" hits=${out.length}',
    );
    return out;
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
    if (cover.isEmpty || _isPlaceholderCover(cover)) {
      // Common detail-page cover selectors (incl. lazy data-src via analyzer).
      for (final fb in const [
        // package:html needs quoted attr values when they contain ':'
        'meta[property="og:image"]@content',
        'img.cover@src',
        '.cover img@src',
        '#cover img@src',
        'img@src',
      ]) {
        final c = rule.getString(fb);
        if (c.isNotEmpty && !_isPlaceholderCover(c)) {
          cover = c;
          break;
        }
      }
    }
    if (cover.isNotEmpty) cover = urlJoin(resp.url, cover);
    if (_isPlaceholderCover(cover)) cover = seed?.coverUrl ?? '';
    if (_isPlaceholderCover(cover)) cover = '';
    var tocUrl = pick(r.tocUrl, bookUrl);
    if (tocUrl.isNotEmpty) tocUrl = urlJoin(resp.url, tocUrl);

    final name = pick(r.name, seed?.name ?? '');
    // Author: never cleanAuthor(seed) through a failed rule — garbage detail
    // rules used to wipe a good search-result author via pick() + cleanAuthor.
    final author = _resolveAuthor(
      rule,
      ruleStr: r.author,
      fallback: seed?.author ?? '',
    );
    final intro = pick(r.intro, seed?.intro ?? '');
    final last = pick(r.lastChapter, seed?.lastChapter ?? '');
    final kind = pick(r.kind, seed?.kind ?? '');
    final id = makeBookKey(source.bookSourceUrl, bookUrl);

    return BookInfo(
      id: id,
      name: name,
      author: author,
      coverUrl: cover,
      category: kind,
      description: intro,
      latestChapter: last,
      sourceUrl: source.bookSourceUrl,
      bookUrl: bookUrl,
      originName: source.bookSourceName,
      tocUrl: tocUrl.isEmpty ? bookUrl : tocUrl,
    );
  }

  Future<List<SourceChapter>> toc(BookSource source, String tocUrl) async {
    AppLog.d(
      'Source',
      'toc "${source.bookSourceName}" url=$tocUrl '
          'chapterList=${source.ruleToc.chapterList}',
    );
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
        final listRule = source.ruleToc.chapterList;
        var items = listRule.isEmpty
            ? const <dynamic>[]
            : rule.getList(listRule);
        // Soft fallback for common novel layouts when rule misses.
        if (items.isEmpty && !resp.isJson) {
          for (final fb in const [
            'ul.chapter_list a',
            '.chapter_list a',
            '#list dd a',
            '.listmain dd a',
            '#chapterlist a',
            '.chapterlist a',
            '#chapters a',
          ]) {
            items = rule.getList(fb);
            if (items.isNotEmpty) {
              AppLog.w(
                'Source',
                'toc rule miss, fallback selector="$fb" hits=${items.length}',
              );
              break;
            }
          }
        }
        var skipped = 0;
        for (final item in items) {
          final nameRule = source.ruleToc.chapterName.isEmpty
              ? 'text'
              : source.ruleToc.chapterName;
          final urlRule = source.ruleToc.chapterUrl.isEmpty
              ? 'href'
              : source.ruleToc.chapterUrl;
          var name = rule.getString(nameRule, scope: item);
          var url = rule.getString(urlRule, scope: item);
          if (item is Element) {
            // Scope may be <li>/<div>; prefer nested <a>.
            final a = item.localName == 'a' ? item : item.querySelector('a');
            if (name.isEmpty) {
              name = (a?.attributes['title'] ?? '').trim();
              if (name.isEmpty) name = (a?.text ?? item.text).trim();
            }
            if (url.isEmpty) {
              url = a?.attributes['href'] ?? item.attributes['href'] ?? '';
            }
          }
          name = name.replaceAll(RegExp(r'\s+'), ' ').trim();
          url = urlJoin(resp.url, url.trim());
          if (name.isEmpty || url.isEmpty) {
            skipped++;
            continue;
          }
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
        AppLog.d(
          'Source',
          'toc page=$pages items=${items.length} kept=${all.length} '
              'skipped=$skipped bodyLen=${resp.body.length} '
              'status=${resp.statusCode}',
        );
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
        String raw = '';
        final contentRule = source.ruleContent.content;
        if (resp.isJson) {
          raw = rule.getString(contentRule);
        } else {
          if (contentRule.isNotEmpty) {
            raw = rule.getHtmlString(contentRule);
            if (raw.isEmpty) {
              raw = rule.getString(contentRule);
            }
          }
          // Always probe common containers and keep the longest plain text.
          // Many sources return a short partial match (e.g. first <p> only,
          // ~80–150 chars) which is still "valid" but incomplete — the old
          // threshold of 80 skipped fallbacks for those chapters.
          final primaryLen = _plainLen(raw);
          const fallbacks = [
            '.chapter_content_box',
            '#chaptercontent',
            '#content',
            '.content',
            '#BookText',
            '.book-content',
            '.read-content',
            '#chaptercontent p',
            '.chapter_content_box p',
            '#content p',
            'article',
            '.novel_content',
            '#novelcontent',
            '.txtnav',
            '#txtcontent',
          ];
          // Probe when primary is empty/short, or still modest (partial grab).
          final shouldProbe = primaryLen < 500;
          if (shouldProbe) {
            var best = raw;
            var bestLen = primaryLen;
            var bestSel = contentRule.isEmpty ? '(empty)' : contentRule;
            for (final fb in fallbacks) {
              if (fb == contentRule) continue;
              var cand = rule.getHtmlString(fb);
              if (cand.isEmpty) cand = rule.getString(fb);
              final n = _plainLen(cand);
              if (n > bestLen) {
                best = cand;
                bestLen = n;
                bestSel = fb;
              }
            }
            if (bestLen > primaryLen) {
              AppLog.w(
                'Source',
                'content rule weak/miss, fallback="$bestSel" '
                    'rawLen=$primaryLen fbLen=$bestLen',
              );
              raw = best;
            }
          }
        }
        final part = finalizeContent(raw, source.ruleContent.replaceRegex);
        AppLog.d(
          'Source',
          'content page=$pages status=${resp.statusCode} '
              'rawLen=${raw.length} plainLen=${part.length}',
        );
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

  /// Cheap length of text after stripping tags (for fallback ranking).
  static int _plainLen(String htmlOrText) {
    if (htmlOrText.isEmpty) return 0;
    return htmlOrText
        .replaceAll(RegExp(r'<[^>]+>'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim()
        .length;
  }

  static bool _isPlaceholderCover(String url) {
    if (url.isEmpty) return true;
    final u = url.toLowerCase();
    return u.contains('loading.jpg') ||
        u.contains('loading.png') ||
        u.contains('placeholder') ||
        u.contains('default_cover') ||
        u.contains('nocover') ||
        u.contains('nopic') ||
        u.contains('noimg') ||
        u.contains('no-cover') ||
        u.endsWith('/lazy.png');
  }

  /// Resolve author from rule + soft fallbacks. Never wipe a good [fallback]
  /// (e.g. search seed) when the detail rule returns unusable text.
  static String _resolveAuthor(
    AnalyzeRule rule, {
    String ruleStr = '',
    dynamic scope,
    String fallback = '',
  }) {
    if (ruleStr.isNotEmpty) {
      final cleaned = cleanAuthor(rule.getString(ruleStr, scope: scope));
      if (cleaned.isNotEmpty) return cleaned;
    }

    // Soft selectors — many sources omit / misconfigure author rules.
    final selectors = scope is Element
        ? const [
            '.author@text',
            'span.author@text',
            'p.author@text',
            'a.author@text',
            '.writer@text',
            '.book_author@text',
            '.authorName@text',
            '.s@text',
            'p.meta@text',
            '.btm@text',
            '.bookinfo@text',
            '.info@text',
          ]
        : const [
            'meta[property="og:novel:author"]@content',
            'meta[name="author"]@content',
            'meta[property="og:author"]@content',
            'meta[property="og:novel:author"]@content',
            '#info p@text',
            '.info .author@text',
            '.book-info .author@text',
            '.detail .author@text',
            '.author@text',
            'span.author@text',
            'p.author@text',
            'a.author@text',
            '.writer@text',
            '#bookinfo .author@text',
            '.bookinfo@text',
          ];

    for (final sel in selectors) {
      final cleaned = cleanAuthor(rule.getString(sel, scope: scope));
      if (cleaned.isNotEmpty) return cleaned;
    }

    // Last resort: whole card / page text may still contain "作者：xxx".
    if (scope is Element) {
      final cleaned = cleanAuthor(scope.text);
      if (cleaned.isNotEmpty) return cleaned;
    }

    return cleanAuthor(fallback);
  }
}
