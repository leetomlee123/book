import 'package:book/common/text_composition.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('first line of each paragraph is indented, wrap lines are flush', () {
    const body = '第一段正文很长需要换行显示一二三四五六七八九十甲乙丙丁戊己庚辛。\n'
        '第二段同样很长需要换行显示子丑寅卯辰巳午未申酉戌亥。';
    final pages = TextComposition(
      text: body,
      style: const TextStyle(fontSize: 20, height: 1.5),
      paragraph: 12,
      indent: 40,
      boxSize: const Size(200, 800),
      padding: const EdgeInsets.symmetric(horizontal: 10),
    ).pages;

    final lines = pages.expand((p) => p.lines).toList();
    expect(lines.length, greaterThan(2));

    final firsts = lines.where((l) => l.indent == 40).toList();
    expect(firsts.length, 2);
    expect(firsts.first.text.startsWith('第一段'), isTrue);
    expect(firsts.last.text.startsWith('第二段'), isTrue);
    expect(lines.where((l) => l.indent == 0).length, lines.length - 2);
    for (final line in firsts) {
      expect(line.targetWidth, lessThan(180));
    }
  });

  test('zero indent leaves every line flush', () {
    const body = '只有一段。\n再来一段。';
    final pages = TextComposition(
      text: body,
      style: const TextStyle(fontSize: 18, height: 1.4),
      indent: 0,
      boxSize: const Size(240, 400),
    ).pages;
    final lines = pages.expand((p) => p.lines);
    expect(lines.every((l) => l.indent == 0), isTrue);
  });
}
