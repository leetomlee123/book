import 'package:book/entity/text_line.dart';
import 'package:book/entity/text_page.dart';
import 'package:book/model/reader/reader_painter.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ABI v3 TextLine/TextPage', () {
    test('fromJson accepts semantic fields', () {
      final line = TextLine.fromJson({
        'text': '你好世界',
        'top': 12.5,
        'height': 30.0,
        'justify': true,
        'isLastLine': false,
        'isParagraphEnd': false,
        'targetWidth': 360.0,
      });
      expect(line.text, '你好世界');
      expect(line.top, 12.5);
      expect(line.justify, isTrue);
      expect(line.targetWidth, 360.0);
    });

    test('fromJson accepts legacy dx/dy cache rows', () {
      final line = TextLine.fromJson({
        'text': '旧缓存',
        'dx': 20,
        'dy': 40,
        'letterSpacing': 1.2,
      });
      expect(line.top, 40);
      expect(line.letterSpacing, 1.2);
    });

    test('TextPage round-trip', () {
      final page = TextPage(
        [
          TextLine(
            '第一行',
            top: 0,
            height: 28,
            justify: true,
            targetWidth: 300,
          ),
          TextLine.simple('段末', top: 28, height: 28, targetWidth: 300),
        ],
        56,
        pageIndex: 2,
        charStart: 0,
        charEnd: 10,
      );
      final json = page.toJson();
      final back = TextPage.fromJson(json);
      expect(back.lines.length, 2);
      expect(back.pageIndex, 2);
      expect(back.lines.first.justify, isTrue);
      expect(back.lines.last.isLastLine, isTrue);
    });
  });

  group('ReaderPainter spacing', () {
    test('non-justify returns 0', () {
      final ls = ReaderPainter.resolveLetterSpacing(
        text: 'abcdefgh',
        style: const TextStyle(fontSize: 18),
        justify: false,
        targetWidth: 400,
        fontSize: 18,
      );
      expect(ls, 0);
    });

    test('single char returns 0', () {
      final ls = ReaderPainter.resolveLetterSpacing(
        text: '中',
        style: const TextStyle(fontSize: 18),
        justify: true,
        targetWidth: 400,
        fontSize: 18,
      );
      expect(ls, 0);
    });
  });
}
