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
    expect(items[0].jsonUrl,
        'https://www.yckceo.com/yuedu/shuyuan/json/id/7592.json');
    expect(items[1].title, '光遇聚合');
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

  test('multi source json url', () {
    expect(
      YckceoRepo.multiSourceJsonUrl(['1', '2', '3']),
      'https://www.yckceo.com/yuedu/shuyuan/json/id/1,2,3',
    );
  });
}
