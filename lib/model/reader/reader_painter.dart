import 'dart:ui' as ui;

import 'package:book/common/app_log.dart';
import 'package:book/common/local_store.dart';
import 'package:book/common/read_setting.dart';
import 'package:book/common/screen.dart';
import 'package:book/entity/read_page.dart';
import 'package:book/entity/text_page.dart';
import 'package:flutter/material.dart';
import 'package:book/common/common.dart';

/// Canvas painter for reader pages (page-turn chrome + scroll body tiles).
///
/// Keeps paint math out of [ReadModel] so layout/theme changes stay local.
class ReaderPainter {
  ReaderPainter();

  ui.Image? bgUI;

  final TextPainter _labelPainter =
      TextPainter(textDirection: TextDirection.ltr, maxLines: 1);

  /// Natural height of a scroll tile (content only + tiny pad).
  double scrollPageHeight(ReadPage readPage, int pageIdx) {
    if (pageIdx < 0 || pageIdx >= readPage.pages.length) {
      return 120;
    }
    final page = readPage.pages[pageIdx];
    final lineH = ReadSetting.getFontSize() * ReadSetting.getLineHeight();
    if (page.lines.isEmpty) {
      return lineH + 4;
    }
    var minDy = double.infinity;
    var maxDy = 0.0;
    for (final line in page.lines) {
      if (line.dy < minDy) minDy = line.dy;
      if (line.dy > maxDy) maxDy = line.dy;
    }
    if (!minDy.isFinite) minDy = 0;
    final contentH = (maxDy - minDy) + lineH;
    return (contentH < lineH ? lineH : contentH) + 2;
  }

  /// Paint body lines only into a tight-height picture for continuous scroll.
  ui.Picture drawScrollContent(
    ReadPage readPage,
    int pageIdx, {
    required PaperTheme paperTheme,
  }) {
    final bool night =
        paperTheme == PaperTheme.night || SpUtil.getBool(PrefsKeys.dark, defValue: false);
    final effectivePaper = night ? PaperTheme.night : paperTheme;
    final paper = ReadSetting.paperColor(effectivePaper);
    final ink = ReadSetting.inkColor(effectivePaper);

    final contentPadding = ReadSetting.getPageDis().toDouble();
    final pageW = Screen.width;
    final fontFamily = ReadSetting.getFontFamily();
    final familyOrNull =
        (fontFamily.isEmpty || fontFamily == 'Roboto') ? null : fontFamily;
    final fontSize = ReadSetting.getFontSize();
    final lineHeight = ReadSetting.getLineHeight();
    final TextStyle style = TextStyle(
      color: ink,
      locale: const Locale('zh_CN'),
      fontFamily: familyOrNull,
      fontSize: fontSize,
      height: lineHeight,
    );

    final tileH = scrollPageHeight(readPage, pageIdx);
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, pageW, tileH));
    canvas.drawRect(Rect.fromLTWH(0, 0, pageW, tileH), Paint()..color = paper);

    final maxLineWidth = (pageW - contentPadding * 2).clamp(1.0, pageW);
    final linePainter = TextPainter(textDirection: TextDirection.ltr);

    if (pageIdx < 0 ||
        pageIdx >= readPage.pages.length ||
        readPage.pages[pageIdx].lines.isEmpty) {
      final fallback = TextPainter(
        textDirection: TextDirection.ltr,
        text: TextSpan(
          text: readPage.chapterContent.isNotEmpty
              ? readPage.chapterContent
              : '内容为空',
          style: style,
        ),
      );
      fallback.layout(maxWidth: maxLineWidth);
      fallback.paint(canvas, Offset(contentPadding, 0));
      return recorder.endRecording();
    }

    final page = readPage.pages[pageIdx];
    var minDy = double.infinity;
    for (final line in page.lines) {
      if (line.dy < minDy) minDy = line.dy;
    }
    if (!minDy.isFinite) minDy = 0;

    for (final line in page.lines) {
      final ls = line.letterSpacing;
      final TextStyle lineStyle =
          (ls != null && (ls < -0.1 || ls > 0.1) && ls.isFinite)
              ? style.copyWith(letterSpacing: ls)
              : style;
      linePainter.text = TextSpan(text: line.text, style: lineStyle);
      linePainter.layout();
      if (linePainter.width > maxLineWidth * 1.05) {
        linePainter.layout(maxWidth: maxLineWidth);
      }
      final y = (line.dy - minDy).clamp(0.0, tileH);
      linePainter.paint(canvas, Offset(line.dx, y));
    }
    return recorder.endRecording();
  }

  /// Paint one page picture.
  ///
  /// [chrome]: when true (page-turn), bake chapter title + time/page.
  /// When false (vertical scroll), body only — chrome is a sticky overlay.
  ui.Picture drawContent(
    ReadPage readPage,
    int i, {
    bool chrome = true,
    required PaperTheme paperTheme,
  }) {
    final pageRecorder = ui.PictureRecorder();

    final bool night =
        paperTheme == PaperTheme.night || SpUtil.getBool(PrefsKeys.dark, defValue: false);
    final effectivePaper = night ? PaperTheme.night : paperTheme;
    final paper = ReadSetting.paperColor(effectivePaper);
    final ink = ReadSetting.inkColor(effectivePaper);
    final meta = ReadSetting.metaColor(effectivePaper);

    final contentPadding = ReadSetting.getPageDis().toDouble();
    final pageW = Screen.width;
    final pageH = Screen.height;
    final pageCanvas =
        Canvas(pageRecorder, Rect.fromLTWH(0, 0, pageW, pageH));
    pageCanvas.drawRect(
      Rect.fromLTWH(0, 0, pageW, pageH),
      Paint()..color = paper,
    );
    if (!ReadSetting.useSolidPaper()) {
      final selfPaint = Paint()
        ..style = PaintingStyle.fill
        ..isAntiAlias = true
        ..strokeCap = StrokeCap.butt
        ..strokeWidth = 30.0;
      final bg = bgUI;
      if (bg != null) {
        pageCanvas.drawImage(bg, const Offset(0, 0), selfPaint);
      }
    }

    final fontFamily = ReadSetting.getFontFamily();
    final familyOrNull =
        (fontFamily.isEmpty || fontFamily == 'Roboto') ? null : fontFamily;
    final fontSize = ReadSetting.getFontSize();
    final TextStyle style = TextStyle(
      color: ink,
      locale: const Locale('zh_CN'),
      fontFamily: familyOrNull,
      fontSize: fontSize,
      height: ReadSetting.getLineHeight(),
    );

    final bodyTop = ReadSetting.contentTopInset();
    final maxLineWidth = (pageW - contentPadding * 2).clamp(1.0, pageW);

    if (readPage.chapterName == '加载中') {
      final msg = readPage.chapterContent.isNotEmpty
          ? readPage.chapterContent
          : '正在加载…';
      final centerPainter = TextPainter(
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
        text: TextSpan(
          text: msg,
          style: style.copyWith(
            color: meta,
            fontSize: (fontSize * 0.95).clamp(14.0, 18.0),
          ),
        ),
      );
      centerPainter.layout(maxWidth: maxLineWidth);
      final dx = (pageW - centerPainter.width) / 2;
      final dy = (pageH - centerPainter.height) / 2;
      centerPainter.paint(pageCanvas, Offset(dx, dy));
      return pageRecorder.endRecording();
    }

    if (chrome) {
      _labelPainter.text = TextSpan(
        text: readPage.chapterName,
        style: TextStyle(
          fontSize: 12 / Screen.textScaleFactor,
          color: meta,
          fontFamily: familyOrNull,
        ),
      );
      _labelPainter.layout();
      _labelPainter.paint(
        pageCanvas,
        Offset(contentPadding, ReadSetting.chapterTitleOffsetY()),
      );
    }

    final linePainter = TextPainter(textDirection: TextDirection.ltr);

    if (readPage.pages.isEmpty) {
      final fallbackPainter = TextPainter(
        textDirection: TextDirection.ltr,
        text: TextSpan(
          text: readPage.chapterContent.isNotEmpty
              ? readPage.chapterContent
              : '内容为空',
          style: style,
        ),
      );
      fallbackPainter.layout(maxWidth: maxLineWidth);
      fallbackPainter.paint(
        pageCanvas,
        Offset(contentPadding, bodyTop),
      );
      return pageRecorder.endRecording();
    }
    final pageIndex = i.clamp(0, readPage.pages.length - 1);
    final TextPage page = readPage.pages[pageIndex];
    final lineCount = page.lines.length;
    for (var li = 0; li < lineCount; li++) {
      final line = page.lines[li];
      final ls = line.letterSpacing;
      final TextStyle lineStyle =
          (ls != null && (ls < -0.1 || ls > 0.1) && ls.isFinite)
              ? style.copyWith(letterSpacing: ls)
              : style;
      final charCount = line.text.characters.length;
      final roughMaxChars =
          (maxLineWidth / (fontSize * 0.9)).floor().clamp(1, 500);
      final needsWrap = charCount > roughMaxChars;
      linePainter.text = TextSpan(text: line.text, style: lineStyle);
      if (needsWrap) {
        AppLog.w(
          'Read',
          'overlong line li=$li chars=$charCount — wrapping in drawContent',
        );
        linePainter.layout(maxWidth: maxLineWidth);
      } else {
        linePainter.layout();
        if (linePainter.width > maxLineWidth * 1.05) {
          linePainter.layout(maxWidth: maxLineWidth);
        }
      }
      linePainter.paint(pageCanvas, Offset(line.dx, line.dy + bodyTop));
    }
    if (!chrome) {
      return pageRecorder.endRecording();
    }

    // Time + page number chrome (no battery).
    final bottomTextH = Screen.height - 27 - Screen.bottomSafeHeight;
    _labelPainter.text = TextSpan(
      text: DateUtil.formatDate(DateTime.now(), format: DateFormats.h_m),
      style: TextStyle(
        fontFamily: familyOrNull,
        fontSize: 12 / Screen.textScaleFactor,
        color: meta,
      ),
    );
    _labelPainter.layout();
    _labelPainter.paint(
      pageCanvas,
      Offset(contentPadding, bottomTextH),
    );
    _labelPainter.text = TextSpan(
      text: '${i + 1}/${readPage.pages.length}',
      style: TextStyle(
        fontSize: 12 / Screen.textScaleFactor,
        fontFamily: familyOrNull,
        color: meta,
      ),
    );
    _labelPainter.layout();
    _labelPainter.paint(
      pageCanvas,
      Offset(Screen.width - contentPadding - 40, bottomTextH),
    );
    return pageRecorder.endRecording();
  }
}
