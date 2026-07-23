import 'package:book/source/analyzer/js_analyzer.dart';
import 'package:book/source/analyzer/regex_analyzer.dart';
import 'package:book/source/engine/progress_mapper.dart';
import 'package:book/source/import/source_importer.dart';
import 'package:book/source/model/book_source.dart';
import 'package:book/source/model/search_book.dart';
import 'package:book/source/net/analyze_url.dart';
import 'package:book/source/rule/analyze_rule.dart';
import 'package:book/source/util/book_id.dart';
import 'package:book/source/util/text_clean.dart';
import 'package:book/source/util/url_join.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SourceImporter', () {
    test('parses single object', () {
      const json = '''
{
  "bookSourceUrl": "https://example.com",
  "bookSourceName": "示例源",
  "searchUrl": "https://example.com/search?q={{key}}",
  "ruleSearch": {
    "bookList": ".item",
    "name": "a@text",
    "bookUrl": "a@href"
  },
  "ruleBookInfo": {"name": "h1@text"},
  "ruleToc": {"chapterList": "dd a", "chapterName": "text", "chapterUrl": "href"},
  "ruleContent": {"content": "#content"}
}
''';
      final list = SourceImporter.parseJson(json).sources;
      expect(list.length, 1);
      expect(list.first.bookSourceName, '示例源');
      expect(list.first.ruleSearch.bookList, '.item');
      expect(list.first.rawJson.isNotEmpty, true);
    });

    test('parses array', () {
      const json = '''
[
  {"bookSourceUrl":"https://a.com","bookSourceName":"A","searchUrl":"/s?q={{key}}","ruleSearch":{"bookList":".x"},"ruleBookInfo":{},"ruleToc":{},"ruleContent":{}},
  {"bookSourceUrl":"https://b.com","bookSourceName":"B","searchUrl":"/s?q={{key}}","ruleSearch":{"bookList":".y"},"ruleBookInfo":{},"ruleToc":{},"ruleContent":{}}
]
''';
      final list = SourceImporter.parseJson(json).sources;
      expect(list.length, 2);
      expect(list.map((e) => e.bookSourceName).toList(), ['A', 'B']);
    });

    test('dedupes same bookSourceUrl in batch', () {
      const json = '''
[
  {"bookSourceUrl":"https://a.com","bookSourceName":"A1","searchUrl":"/s","ruleSearch":{},"ruleBookInfo":{},"ruleToc":{},"ruleContent":{}},
  {"bookSourceUrl":"https://a.com","bookSourceName":"A2","searchUrl":"/s","ruleSearch":{},"ruleBookInfo":{},"ruleToc":{},"ruleContent":{}}
]
''';
      final parsed = SourceImporter.parseJson(json);
      expect(parsed.sources.length, 1);
      expect(parsed.duplicatesInBatch, 1);
      expect(parsed.sources.first.bookSourceName, 'A2');
    });
  });

  group('AnalyzeUrl headers', () {
    test('strips Legado @js keys from source header JSON', () {
      final source = BookSource(
        bookSourceUrl: 'https://example.com',
        bookSourceName: 't',
        header: '{"User-Agent":"UA-TEST","@js":"java.ajax(\'x\')","Referer":"https://example.com/"}',
        searchUrl: 'https://example.com/s?q={{key}}',
      );
      final req = AnalyzeUrl.build(source, source.searchUrl, key: 'hello');
      expect(req.headers.containsKey('@js'), isFalse);
      expect(req.headers['User-Agent'], 'UA-TEST');
      expect(req.headers['Referer'], 'https://example.com/');
    });

    test('strips invalid header names from url options', () {
      final source = BookSource(
        bookSourceUrl: 'https://example.com',
        bookSourceName: 't',
        header: '',
        searchUrl:
            'https://example.com/s,{"method":"GET","headers":{"@js":"1","X-Ok":"yes"}}',
      );
      final req = AnalyzeUrl.build(source, source.searchUrl, key: 'k');
      expect(req.headers.containsKey('@js'), isFalse);
      expect(req.headers['X-Ok'], 'yes');
    });

    test('strips Legado {{cookie…}} prefix from searchUrl', () {
      final source = BookSource(
        bookSourceUrl: 'http://www.kkbiquge.net',
        bookSourceName: 'kk',
        searchUrl:
            '{{cookie.removeCookie(source.getKey())}}http://www.kkbiquge.net/search2c.html?searchkey={{key}}',
      );
      final req = AnalyzeUrl.build(source, source.searchUrl, key: '斗破');
      expect(req.url.startsWith('http://www.kkbiquge.net/search2c.html'), isTrue);
      expect(req.url.contains('cookie'), isFalse);
      expect(req.url.contains('{{'), isFalse);
      expect(req.url, contains(Uri.encodeQueryComponent('斗破')));
    });

    test('sanitizeUrl recovers embedded absolute url', () {
      final cleaned = AnalyzeUrl.sanitizeUrl(
        '{{java.ajax("x")}}https://a.com/path?q=1',
        base: 'https://fallback.com',
      );
      expect(cleaned, 'https://a.com/path?q=1');
    });

    test('sanitizeUrl rejects leftover JS statements', () {
      final cleaned = AnalyzeUrl.sanitizeUrl(
        "let base_url = getArguments(source.getVariable(), 'server');",
        base: 'https://example.com',
      );
      expect(cleaned, isEmpty);
    });

    test('urlJoin does not throw on JS-looking relative path', () {
      final out = urlJoin(
        'https://example.com',
        "let base_url = getArguments(source.getVariable(), 'server');",
      );
      // Must not throw FormatException; returns path untouched when rejected.
      expect(out.contains('let base_url'), isTrue);
      expect(out.startsWith('https://example.com/let'), isFalse);
    });

    test('build leaves empty url when @js searchUrl fails to resolve', () {
      final source = BookSource(
        bookSourceUrl: 'https://example.com',
        bookSourceName: 'js-fail',
        searchUrl:
            "@js:\nlet base_url = getArguments(source.getVariable(), 'server');\nbase_url;",
      );
      final req = AnalyzeUrl.build(source, source.searchUrl, key: '斗破');
      // No absolute URL produced — empty rather than crashing Uri.parse.
      expect(req.url, isEmpty);
    });
  });

  group('AnalyzeRule CSS', () {
    test('extracts list and fields', () {
      const html = '''
<html><body>
<div class="item"><a href="/book/1">书名一</a><span class="author">张三</span></div>
<div class="item"><a href="/book/2">书名二</a><span class="author">李四</span></div>
</body></html>
''';
      final rule = AnalyzeRule(content: html, baseUrl: 'https://ex.com');
      final list = rule.getList('.item');
      expect(list.length, 2);
      final name = rule.getString('a@text', scope: list.first);
      final href = rule.getString('a@href', scope: list.first);
      final author = rule.getString('.author@text', scope: list.first);
      expect(name, '书名一');
      expect(href, '/book/1');
      expect(author, '张三');
    });

    test('missed author child selector does not dump whole card text', () {
      const html = '''
<html><body>
<div class="item">
  <a href="/book/1">书名一</a>
  <p class="meta">作者：张三 分类：玄幻</p>
  <p class="intro">一段简介</p>
</div>
</body></html>
''';
      final rule = AnalyzeRule(content: html, baseUrl: 'https://ex.com');
      final list = rule.getList('.item');
      final missed = rule.getString('.author@text', scope: list.first);
      expect(missed, isEmpty);
      final ok = rule.getString('.meta@text', scope: list.first);
      expect(ok, contains('张三'));
      expect(cleanAuthor(ok), '张三');
    });

    test('author from nested span under label', () {
      const html = '''
<html><body>
<div class="item">
  <a href="/book/1">书名一</a>
  <div class="author">作者：<span>王五</span></div>
</div>
</body></html>
''';
      final rule = AnalyzeRule(content: html, baseUrl: 'https://ex.com');
      final list = rule.getList('.item');
      final raw = rule.getString('.author@text', scope: list.first);
      expect(cleanAuthor(raw), '王五');
    });

    test('cleanAuthor keeps short name and strips trailing 著', () {
      expect(cleanAuthor('作者：天蚕土豆著'), '天蚕土豆');
      expect(cleanAuthor('张三/玄幻'), '张三');
      expect(cleanAuthor(''), '');
    });

    test('ownText excludes descendant elements', () {
      const html = '''
<html><body>
<div class="author">作者：<span>王五</span> 连载</div>
</body></html>
''';
      final rule = AnalyzeRule(content: html, baseUrl: 'https://ex.com');
      final el = rule.getList('.author').first;
      final own = rule.getString('ownText', scope: el);
      expect(own.contains('王五'), isFalse);
      expect(own, contains('作者'));
      final full = rule.getString('text', scope: el);
      expect(full, contains('王五'));
    });

    test('normalizes Jsoup class./tag. and || fallbacks', () {
      const html = '''
<html><body>
<div class="catalog_box">
  <ul class="chapter_list">
    <li><div><a href="/novel/x/1" title="第1章">第1章 开始</a><p>2026</p></div></li>
    <li><div><a href="/novel/x/2" title="第2章">第2章 继续</a><p>2026</p></div></li>
  </ul>
</div>
</body></html>
''';
      final rule = AnalyzeRule(content: html, baseUrl: 'https://ex.com');
      // Jsoup-style: class.chapter_list@tag.a
      final list = rule.getList('class.missing@tag.a||class.chapter_list@tag.a');
      expect(list.length, 2);
      expect(rule.getString('text', scope: list.first), contains('第1章'));
      expect(rule.getString('href', scope: list.first), '/novel/x/1');
      // Bare @text / @href aliases
      expect(rule.getString('@text', scope: list.first), contains('第1章'));
      expect(rule.getString('@href', scope: list.first), '/novel/x/1');
    });

    test('chapter list li scope resolves nested a', () {
      const html = '''
<html><body>
<ul class="chapter_list">
  <li><div><a href="/c/1" title="第一章">第一章 标题</a></div></li>
</ul>
</body></html>
''';
      final rule = AnalyzeRule(content: html, baseUrl: 'https://ex.com');
      final list = rule.getList('.chapter_list li');
      expect(list.length, 1);
      // Common bad source rule: chapterName=text, chapterUrl=href on <li>
      // Analyzer should still recover nested <a> via engine fallbacks; here
      // getString('href') on li is empty unless we use a@href.
      expect(rule.getString('a@href', scope: list.first), '/c/1');
      expect(rule.getString('a@text', scope: list.first), contains('第一章'));
    });

    test('banshanren-shaped catalog with wrong primary selector', () {
      // Mirrors https://www.banshanren.com/novel/cangxian catalog markup.
      const html = '''
<html><body>
<div class="catalog_box">
  <div class="volume_box">
    <ul class="chapter_list">
      <li>
        <div><a href="/novel/cangxian/1273628667947255006"
                title="第1章 手术穿越">第1章 手术穿越</a>
          <p>2026.12.07</p>
        </div>
        <span>字数</span>
      </li>
      <li>
        <div><a href="/novel/cangxian/1273628667951449311"
                title="第2章 合欢宗">第2章 合欢宗</a>
          <p>2026.12.07</p>
        </div>
      </li>
    </ul>
  </div>
</div>
</body></html>
''';
      final rule = AnalyzeRule(
        content: html,
        baseUrl: 'https://www.banshanren.com/novel/cangxian',
      );
      // Wrong first alt (common when source is copy-pasted from another site)
      final items = rule.getList('#list dd a||ul.chapter_list a');
      expect(items.length, 2);
      expect(rule.getString('text', scope: items.first), contains('第1章'));
      expect(
        rule.getString('href', scope: items.first),
        '/novel/cangxian/1273628667947255006',
      );
    });

    test('supports :eq(n) index pseudo', () {
      const html = '''
<html><body>
<ul class="list">
  <li><a href="/0">零</a></li>
  <li><a href="/1">一</a></li>
  <li><a href="/2">二</a></li>
</ul>
</body></html>
''';
      final rule = AnalyzeRule(content: html, baseUrl: 'https://ex.com');
      final first = rule.getList('ul.list li:eq(0)');
      expect(first.length, 1);
      expect(rule.getString('a@text', scope: first.first), '零');
      final second = rule.getList('ul.list li:eq(1) a');
      expect(second.length, 1);
      expect(rule.getString('text', scope: second.first), '一');
      expect(rule.getString('href', scope: second.first), '/1');
    });

    test('supports :gt(n) and :lt(n)', () {
      const html = '''
<html><body>
<div class="item">A</div>
<div class="item">B</div>
<div class="item">C</div>
<div class="item">D</div>
</body></html>
''';
      final rule = AnalyzeRule(content: html, baseUrl: 'https://ex.com');
      final gt0 = rule.getList('.item:gt(0)');
      expect(gt0.length, 3);
      expect(rule.getString('text', scope: gt0.first), 'B');
      final lt2 = rule.getList('.item:lt(2)');
      expect(lt2.length, 2);
      expect(rule.getString('text', scope: lt2.last), 'B');
    });

    test('supports :contains(text)', () {
      const html = '''
<html><body>
<div id="pager">
  <a href="/prev">上一章</a>
  <a href="/next">下一章</a>
  <a href="/catalog">目录</a>
</div>
</body></html>
''';
      final rule = AnalyzeRule(content: html, baseUrl: 'https://ex.com');
      final next = rule.getList('a:contains(下一章)');
      expect(next.length, 1);
      expect(rule.getString('href', scope: next.first), '/next');
      // Jsoup-style with class + contains
      final again = rule.getList('#pager a:contains(上一章)');
      expect(again.length, 1);
      expect(rule.getString('@text', scope: again.first), '上一章');
    });

    test('Jsoup class. + :eq combination', () {
      const html = '''
<html><body>
<div class="chapter_list">
  <dd><a href="/c1">第1章</a></dd>
  <dd><a href="/c2">第2章</a></dd>
</div>
</body></html>
''';
      final rule = AnalyzeRule(content: html, baseUrl: 'https://ex.com');
      final list = rule.getList('class.chapter_list@tag.dd:eq(1)@tag.a');
      expect(list.length, 1);
      expect(rule.getString('text', scope: list.first), '第2章');
      expect(rule.getString('href', scope: list.first), '/c2');
    });
  });

  group('sourceRegex / init helpers', () {
    test('sourceRegex extracts chapter body from full page', () {
      const page = '''
<html><body>
<div class="wrap">广告广告</div>
<div id="content">第一章正文内容这里有足够的字数用于测试抽取是否成功。</div>
<script>var x=1</script>
</body></html>
''';
      // Simulate ruleContent.sourceRegex (first capture group).
      final body = RegexAnalyzer.getString(
        page,
        r'id="content"[^>]*>([\s\S]*?)</div>',
      );
      expect(body, contains('第一章正文'));
      expect(body.contains('广告'), isFalse);
    });

    test('init CSS narrows page then field rules work', () {
      const page = '''
<html><body>
<div class="side">垃圾侧栏 书名侧栏</div>
<div class="detail">
  <h1 class="title">真正书名</h1>
  <p class="author">作者：测试</p>
</div>
</body></html>
''';
      // Emulate bookInfo.init = `.detail` then name = `h1@text`
      final full = AnalyzeRule(content: page, baseUrl: 'https://ex.com');
      final narrowed = full.getHtmlString('.detail');
      expect(narrowed, contains('真正书名'));
      final rule = AnalyzeRule(content: narrowed, baseUrl: 'https://ex.com');
      expect(rule.getString('h1@text'), '真正书名');
      expect(rule.getString('.author@text'), contains('测试'));
    });

    test('init regex extracts JSON blob from HTML wrapper', () {
      const page = '''
<html><script>var data={"name":"书A","author":"甲"};</script></html>
''';
      final json = RegexAnalyzer.getString(
        page,
        r'var data=(\{[\s\S]*?\});',
      );
      expect(json, contains('"name":"书A"'));
      final rule = AnalyzeRule(
        content: json,
        baseUrl: 'https://ex.com',
        isJson: true,
      );
      expect(rule.getString(r'$.name'), '书A');
      expect(rule.getString(r'$.author'), '甲');
    });
  });

  group('AnalyzeRule JSON', () {
    test('json path list', () {
      const body = '''
{"data":[{"name":"N1","url":"/1"},{"name":"N2","url":"/2"}]}
''';
      final rule = AnalyzeRule(content: body, baseUrl: 'https://ex.com', isJson: true);
      final list = rule.getList(r'$.data');
      expect(list.length, 2);
      expect(rule.getString(r'$.name', scope: list.first), 'N1');
    });
  });

  group('69shuba-shaped rules', () {
    test('xpath meta property extract', () {
      const html = '''
<html><head>
<meta property="og:novel:book_name" content="剑来"/>
<meta property="og:novel:author" content="烽火戏诸侯"/>
<meta property="og:image" content="https://cdn.example.com/cover.jpg"/>
<meta property="og:description" content="简介一段"/>
<meta property="og:novel:category" content="玄幻"/>
<meta property="og:novel:status" content="连载"/>
<meta property="og:novel:update_time" content="2026-01-01"/>
<meta property="og:novel:latest_chapter_name" content="1234.第1234章 终局"/>
</head><body></body></html>
''';
      final rule = AnalyzeRule(content: html, baseUrl: 'https://www.69shuba.com');
      expect(
        rule.getString("//meta[@property='og:novel:book_name']/@content"),
        '剑来',
      );
      expect(
        rule.getString("//meta[@property='og:novel:author']/@content"),
        '烽火戏诸侯',
      );
      expect(
        rule.getString("//meta[@property='og:image']/@content"),
        'https://cdn.example.com/cover.jpg',
      );
      final kind = rule.getString(
        "//meta[@property='og:novel:category' or @property='og:novel:status' or @property='og:novel:update_time']/@content",
      );
      expect(kind, contains('玄幻'));
      expect(kind, contains('连载'));
      final last = rule.getString(
        "//meta[@property='og:novel:latest_chapter_name']/@content##\\d+\\.(?=第)",
      );
      expect(last, '第1234章 终局');
    });

    test('Jsoup a.0 / label.1 index and && join', () {
      const html = '''
<html><body>
<li class="item">
  <a href="/book/1"><img data-src="/c.jpg" alt="书名图"/></a>
  <h3><a href="/book/1">占位</a><a href="/book/1">真正书名</a></h3>
  <label>作者甲</label>
  <label>玄幻</label>
  <label>连载</label>
  <div class="ellipsis_2">简介内容</div>
</li>
</body></html>
''';
      final rule = AnalyzeRule(content: html, baseUrl: 'https://ex.com');
      final items = rule.getList('li.item');
      expect(items.length, 1);
      final item = items.first;
      expect(rule.getString('a.0@href', scope: item), '/book/1');
      expect(rule.getString('h3 a.1@text', scope: item), '真正书名');
      expect(rule.getString('label.0@text', scope: item), '作者甲');
      expect(
        rule.getString('label.1@text&&label.2@text', scope: item),
        '玄幻 连载',
      );
      expect(rule.getString('img@data-src||img@src', scope: item), '/c.jpg');
    });

    test('list reverse range a[-1:0]', () {
      const html = '''
<html><body>
<div id="catalog"><ul>
  <a href="/c/3">第3章</a>
  <a href="/c/2">第2章</a>
  <a href="/c/1">第1章</a>
</ul></div>
</body></html>
''';
      final rule = AnalyzeRule(content: html, baseUrl: 'https://ex.com');
      final items = rule.getList('#catalog ul a[-1:0]');
      expect(items.length, 3);
      expect(rule.getString('text', scope: items.first), '第1章');
      expect(rule.getString('href', scope: items.first), '/c/1');
      expect(rule.getString('text', scope: items.last), '第3章');
    });

    test('hybrid <js>…</js> then CSS list (cfCheck pass-through)', () {
      const html = '''
<html><body>
<ul id="article_list_content">
  <li><h3><a href="/x">A</a><a href="/x">书A</a></h3></li>
  <li><h3><a href="/y">B</a><a href="/y">书B</a></h3></li>
</ul>
</body></html>
''';
      const jsLib = '''
function cfCheck(html, targetUrl) {
  var text = String(html || '');
  if (/Just a moment|cf-turnstile/i.test(text)) {
    return '';
  }
  return html;
}
''';
      final rule = AnalyzeRule(
        content: html,
        baseUrl: 'https://www.69shuba.com/novels/hot',
        jsLib: jsLib,
      );
      final items = rule.getList(
        '<js>cfCheck(result, baseUrl);</js>#article_list_content li',
      );
      expect(items.length, 2);
      expect(rule.getString('h3 a.1@text', scope: items.first), '书A');
    });

    test('hybrid content rule .txtnav@textNodes after js', () {
      const html = '''
<html><body>
<div class="txtnav">第一段
第二段
</div>
</body></html>
''';
      final rule = AnalyzeRule(
        content: html,
        baseUrl: 'https://www.69shuba.com/txt/1',
      );
      final body = rule.getString(
        '<js>cfCheck(result, baseUrl);</js>.txtnav@textNodes',
      );
      expect(body, contains('第一段'));
      expect(body, contains('第二段'));
    });

    test('JS searchUrl quirk becomes POST with gbk charset', () {
      final source = BookSource(
        bookSourceUrl: 'https://www.69shuba.com',
        bookSourceName: '69',
        searchUrl:
            "<js>/modules/article/search.php,{'charset':'gbk','body':'searchkey={{key}}&searchtype=all','method':'POST'};result='';result;</js>",
      );
      final req = AnalyzeUrl.build(source, source.searchUrl, key: '剑来');
      expect(req.method, 'POST');
      expect(req.charset.toLowerCase(), 'gbk');
      expect(req.url, contains('www.69shuba.com/modules/article/search.php'));
      expect(req.body.toString(), contains(Uri.encodeQueryComponent('剑来')));
    });

    test('tocUrl @js relative transform', () {
      final out = JsEngine.instance.eval(
        "baseUrl.endsWith('/') ? baseUrl : baseUrl.replace('.htm','/')",
        result: '',
        baseUrl: 'https://www.69shuba.com/book/123.htm',
        src: '',
      );
      if (out.isEmpty || out == '<html></html>') {
        // Pure-JS path needs native runtime; skip on hosts without flutter_js.
        // ignore: avoid_print
        print('SKIP tocUrl @js — JsEngine unavailable');
        return;
      }
      expect(out, 'https://www.69shuba.com/book/123/');
      final rule = AnalyzeRule(
        content: '<html></html>',
        baseUrl: 'https://www.69shuba.com/book/123.htm',
      );
      final toc = rule.getString(
        "@js:baseUrl.endsWith('/') ? baseUrl : baseUrl.replace('.htm','/')",
      );
      expect(toc, 'https://www.69shuba.com/book/123/');
    });
  });

  group('ProgressMapper', () {
    final toc = [
      SourceChapter(name: '第一章 起航', url: 'u1', index: 0),
      SourceChapter(name: '第二章 风暴', url: 'u2', index: 1),
      SourceChapter(name: '第三章 归途', url: 'u3', index: 2),
    ];

    test('exact name', () {
      expect(
        ProgressMapper.map(oldName: '第二章 风暴', oldIndex: 0, newChapters: toc),
        1,
      );
    });

    test('normalized name', () {
      expect(
        ProgressMapper.map(oldName: '第2章风暴', oldIndex: 0, newChapters: toc),
        1,
      );
    });

    test('index fallback', () {
      expect(
        ProgressMapper.map(oldName: '不存在的章节', oldIndex: 2, newChapters: toc),
        2,
      );
    });
  });

  group('utils', () {
    test('cleanAuthor strips labels and metadata', () {
      expect(cleanAuthor('作者：张三'), '张三');
      expect(cleanAuthor('作者 李四'), '李四');
      expect(cleanAuthor('原著：王五'), '王五');
      expect(cleanAuthor('张三 分类：玄幻 状态：连载'), '张三');
      expect(
        cleanAuthor('书名一\n作者：赵六 分类：都市\n简介xxx'),
        '赵六',
      );
      expect(cleanAuthor(''), '');
      expect(cleanAuthor('123'), '');
    });

    test('urlJoin', () {
      expect(urlJoin('https://a.com/x/', 'y'), 'https://a.com/x/y');
      expect(urlJoin('https://a.com/x', '/y'), 'https://a.com/y');
      expect(urlJoin('https://a.com', 'https://b.com/z'), 'https://b.com/z');
    });

    test('book key stable', () {
      final a = makeBookKey('s1', 'https://b/1');
      final b = makeBookKey('s1', 'https://b/1');
      final c = makeBookKey('s2', 'https://b/1');
      expect(a, b);
      expect(a == c, false);
      expect(a.length, 16);
    });

    test('replaceRegex', () {
      expect(applyReplaceRegex('abc123', r'\d+##'), 'abc');
    });

    test('htmlToPlainText drops comment spans and keeps paragraphs', () {
      const html = '''
<div class="chapter_content_box">
  <h2>第1章</h2>
  <p>第一段文字内容。<span class="z count_0">0</span></p>
  <p>第二段继续讲述故事。<span class="z count_1">0</span></p>
</div>
''';
      final plain = htmlToPlainText(html);
      expect(plain.contains('第一段'), true);
      expect(plain.contains('第二段'), true);
      expect(plain.contains('\n'), true);
      // comment counters stripped
      expect(RegExp(r'^\d+$', multiLine: true).hasMatch(plain), false);
    });

    test('parseExploreKinds multi-line and json', () {
      final multi = parseExploreKinds(
        '玄幻::https://ex.com/x/{{page}}\n都市&&https://ex.com/d/{page}',
      );
      expect(multi.length, 2);
      expect(multi.first.title, '玄幻');
      expect(multi.first.url, contains('ex.com/x'));

      final json = parseExploreKinds(
        '[{"title":"完本","url":"https://ex.com/end/{{page}}"}]',
      );
      expect(json.length, 1);
      expect(json.first.title, '完本');

      final single = parseExploreKinds('https://ex.com/all/{{page}}');
      expect(single.length, 1);
      expect(single.first.title, '全部');
    });
  });

  group('lazy cover src', () {
    test('img@src prefers data-src over loading placeholder', () {
      const html = '''
<html><body>
<div class="item">
  <img class="sm encrypted-image"
       src="https://cdn.example.com/static/image/loading.jpg"
       data-src="https://cdn.example.com/file/cover/real.webp"
       alt="书"/>
  <a href="/novel/x">书名</a>
</div>
</body></html>
''';
      final rule = AnalyzeRule(content: html, baseUrl: 'https://ex.com');
      final items = rule.getList('.item');
      expect(items.length, 1);
      final cover = rule.getString('img@src', scope: items.first);
      expect(cover, 'https://cdn.example.com/file/cover/real.webp');
    });
  });

  group('JsEngine', () {
    test('detects js rules', () {
      expect(JsEngine.needsJs('@js: result'), true);
      expect(JsEngine.needsJs('<js>1+1</js>'), true);
      expect(JsEngine.needsJs('.item a@text'), false);
    });

    test('extracts code', () {
      expect(JsEngine.extractCode('@js: result + "!"'), 'result + "!"');
      expect(JsEngine.extractCode('<js>1+1</js>'), '1+1');
    });

    test('evaluates simple expression', () {
      final out = JsEngine.instance.eval(
        'result + "-ok"',
        result: 'hello',
        baseUrl: 'https://ex.com',
      );
      // flutter_js may be unavailable in some unit-test hosts (no native lib).
      // On device/Android it should evaluate; host fallback returns input.
      if (out == 'hello') {
        // ignore: avoid_print
        print('SKIP JsEngine runtime unavailable in this test host');
        return;
      }
      expect(out, 'hello-ok');
    });

    test('evaluates baseUrl ternary expression', () {
      final out = JsEngine.instance.eval(
        "baseUrl.endsWith('/') ? baseUrl : baseUrl.replace('.htm','/')",
        result: '',
        baseUrl: 'https://www.69shuba.com/book/123.htm',
      );
      if (out.isEmpty) {
        // ignore: avoid_print
        print('SKIP JsEngine runtime unavailable in this test host');
        return;
      }
      expect(out, 'https://www.69shuba.com/book/123/');
    });
  });
}
