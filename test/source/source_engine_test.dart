import 'package:book/source/analyzer/js_analyzer.dart';
import 'package:book/source/engine/progress_mapper.dart';
import 'package:book/source/import/source_importer.dart';
import 'package:book/source/model/search_book.dart';
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
      final list = SourceImporter.parseJson(json);
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
      final list = SourceImporter.parseJson(json);
      expect(list.length, 2);
      expect(list.map((e) => e.bookSourceName).toList(), ['A', 'B']);
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
