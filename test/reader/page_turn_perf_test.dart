import 'dart:ui' as ui;

import 'package:book/animation/static_page_turn.dart';
import 'package:book/entity/book.dart';
import 'package:book/entity/read_page.dart';
import 'package:book/entity/text_line.dart';
import 'package:book/entity/text_page.dart';
import 'package:book/model/reader/page_picture_cache.dart';
import 'package:book/model/reader/page_picture_resolver.dart';
import 'package:book/model/reader/reader_painter.dart';
import 'package:book/view/page_turn/reader_page_manager.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PagePictureResolver Lookahead Pre-warming', () {
    test('preloadNeighbors warms forward +1, +2, and +3 pages', () {
      final cache = PagePictureCache();
      final book = Book(id: 'test_book', name: 'Test Book', chapterIndex: 0, pageIndex: 0);

      // Create a chapter with 5 pages
      final readPage = ReadPage(
        'Content',
        '第1章',
        0,
        List.generate(
          5,
          (i) => TextPage([TextLine.simple('Line in page $i')], 24, pageIndex: i),
        ),
      );

      final resolver = PagePictureResolver(
        cache: cache,
        drawContent: (page, i) {
          final recorder = ui.PictureRecorder();
          final canvas = Canvas(recorder);
          canvas.drawRect(const Rect.fromLTWH(0, 0, 100, 100), Paint());
          return recorder.endRecording();
        },
        loadChapter: (idx) async => null,
        bookOf: () => book,
        curPageOf: () => readPage,
        prePageOf: () => null,
        nextPageOf: () => null,
        setNextPage: (_) {},
        activeBookId: () => book.id,
      );

      expect(cache.isEmpty, isTrue);

      // Trigger preloadNeighbors when at page 0
      resolver.preloadNeighbors();

      // Page 1, 2, 3 should be pre-warmed in cache
      expect(cache.containsKey('test_book|0|1'), isTrue);
      expect(cache.containsKey('test_book|0|2'), isTrue);
      expect(cache.containsKey('test_book|0|3'), isTrue);
      expect(cache.containsKey('test_book|0|4'), isFalse);
    });
  });

  group('ReaderPageManager Rapid Tap & Static Mode', () {
    test('Static mode is never blocked by cooldown and commits immediately', () {
      final manager = ReaderPageManager();
      manager.setCurrentAnimation(ReaderPageManager.TYPE_ANIMATION_NONE);
      expect(manager.isBusy, isFalse);

      final page = manager.currentAnimationPage;
      expect(page, isA<StaticPageTurn>());
    });

    test('Cooldown is disabled in static mode', () {
      final manager = ReaderPageManager();
      manager.setCurrentAnimation(ReaderPageManager.TYPE_ANIMATION_NONE);
      expect(manager.isBusy, isFalse);
      expect(manager.isAnimating, isFalse);
    });
  });

  group('ReaderPainter Spacing & LetterSpacing Cache', () {
    test('resolveLetterSpacing caches and returns finite value', () {
      const style = TextStyle(fontSize: 16);
      final ls = ReaderPainter.resolveLetterSpacing(
        text: '这是一段测试文本',
        style: style,
        justify: true,
        targetWidth: 300,
        fontSize: 16,
      );
      expect(ls.isFinite, isTrue);

      // Providing cached value skips measurement
      final cachedLs = ReaderPainter.resolveLetterSpacing(
        text: '这是一段测试文本',
        style: style,
        justify: true,
        targetWidth: 300,
        fontSize: 16,
        cached: 1.5,
      );
      expect(cachedLs, 1.5);
    });
  });
}
