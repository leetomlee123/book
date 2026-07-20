import 'package:book/source/import/source_importer.dart';
import 'package:book/source/repo/yckceo_repo.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('parse shuyuan list HTML', () {
    const html = '''
<div class="ylist">
  <p class="checkboxclass">
    <input type="checkbox" class="class_one" name="ids[]" value="7592" title="" lay-skin="primary">
  </p>
  <h2><a href="/yuedu/shuyuan/content/id/7592.html">恩木书库 https://m.enmuku.com</a>
    <p class="m-right" style="top: 3px;">刚刚</p>
  </h2>
  <span class="layui-badge-rim">下载 : 2369</span>
</div>
<div class="ylist">
  <p class="checkboxclass">
    <input type="checkbox" class="class_one" name="ids[]" value="7249" title="" lay-skin="primary">
  </p>
  <h2><a href="/yuedu/shuyuan/content/id/7249.html">光遇聚合</a>
    <p class="m-right" style="top: 3px;">1天前</p>
  </h2>
  <span class="layui-badge-rim">下载 : 100</span>
</div>
共有 5567 条数据
''';
    final items = YckceoRepo.parseSourcesHtml(html);
    expect(items.length, 2);
    expect(items[0].id, '7592');
    expect(items[0].title, '恩木书库');
    expect(items[0].host, 'https://m.enmuku.com');
    expect(items[0].downloads, 2369);
    expect(items[0].kind, YckKind.source);
    expect(items[0].jsonUrl,
        'https://www.yckceo.com/yuedu/shuyuan/json/id/7592.json');
    expect(items[1].title, '光遇聚合');
  });

  test('parse rss list HTML', () {
    const html = '''
<div class="ylist">
  <p class="checkboxclass">
    <input type="checkbox" class="class_one" name="ids[]" value="193" title="" lay-skin="primary">
  </p>
  <h2><a href="/yuedu/rss/content/id/193.html">源仓库(官方纯净) http://yckceo.vip</a>
    <p class="m-right" style="top: 3px;">刚刚</p>
  </h2>
  <span class="layui-badge-rim">下载 : 1361255</span>
</div>
共有 306 条数据
''';
    final items = YckceoRepo.parseRssHtml(html);
    expect(items.length, 1);
    expect(items[0].id, '193');
    expect(items[0].isRss, isTrue);
    expect(items[0].title, '源仓库(官方纯净)');
    expect(items[0].host, 'http://yckceo.vip');
    expect(items[0].jsonUrl,
        'https://www.yckceo.com/yuedu/rss/json/id/193.json');
  });

  test('parse collections HTML', () {
    const html = '''
<div class="ylist">
  <h2><a href="/yuedu/shuyuans/content/id/1193.html">自用600个源</a>
    <p class="m-right">4天前</p>
  </h2>
</div>
''';
    final items = YckceoRepo.parseCollectionsHtml(html);
    expect(items.length, 1);
    expect(items[0].isCollection, isTrue);
    expect(items[0].jsonUrl,
        'https://www.yckceo.com/yuedu/shuyuans/json/id/1193.json');
  });

  test('multi source json url falls back to first id only', () {
    expect(
      YckceoRepo.multiSourceJsonUrl(['1', '2', '3']),
      'https://www.yckceo.com/yuedu/shuyuan/json/id/1.json',
    );
  });

  test('parses Legado RSS object into BookSource fields', () {
    const json = '''
[
  {
    "sourceName": "源仓库(官方纯净)",
    "sourceUrl": "http://yckceo.vip",
    "sourceGroup": "1",
    "enabled": true,
    "enableJs": true
  }
]
''';
    final parsed = SourceImporter.parseJson(json);
    expect(parsed.sources.length, 1);
    final s = parsed.sources.first;
    expect(s.bookSourceName, '源仓库(官方纯净)');
    expect(s.bookSourceUrl, 'http://yckceo.vip');
    expect(s.bookSourceGroup.contains('订阅源'), isTrue);
    expect(s.rawJson.contains('sourceName'), isTrue);
  });
}
