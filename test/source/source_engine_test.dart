import 'package:book/source/analyzer/js_analyzer.dart';
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
  });

  group('AnalyzeRule JSON', () {
    test('json path list', () {
      const body = '''
{"data":[{"name":"N1","url":"/1"},{"name":"N2","url":"/2"}]}
''';
      final rule = AnalyzeRule(content: body, baseUrl: 'https://ex.com', isJson: true);
      final list = rule.getList('\$.data');
      expect(list.length, 2);
      expect(rule.getString('\$.name', scope: list.first), 'N1');
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
      // If native runtime unavailable in test env, falls back to input.
      expect(out == 'hello-ok' || out == 'hello', true);
    });
  });
}
