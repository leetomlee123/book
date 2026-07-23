import 'dart:ui' as ui;

import 'package:book/common/local_store.dart';
import 'package:book/common/read_setting.dart';
import 'package:book/common/screen.dart';
import 'package:book/entity/read_page.dart';
import 'package:book/entity/text_line.dart';
import 'package:book/entity/text_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:book/common/common.dart';

/// Canvas painter for reader pages (page-turn chrome + scroll body tiles).
///
/// ABI v3: Rust/Dart pagination emits **semantic** lines
/// (`text` / `top` / `justify` / `targetWidth`). This painter is the **only**
/// place that turns justify intent into Skia `letterSpacing` and paints.
class ReaderPainter {
  ReaderPainter();

  ui.Image? bgUI;

  final TextPainter _labelPainter =
      TextPainter(textDirection: TextDirection.ltr, maxLines: 1);

  /// Compute final letterSpacing from justify intent using Flutter metrics.
  static double resolveLetterSpacing({
    required String text,
    required TextStyle style,
    required bool justify,
    required double targetWidth,
    required double fontSize,
    double? cached,
  }) {
    // Any finite cached value (including 0) skips the measure pass.
    if (cached != null && cached.isFinite) {
      return cached;
    }
    if (!justify || targetWidth <= 0 || text.isEmpty) return 0;
    final n = text.characters.length;
    if (n <= 1) return 0;

    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    final measured = tp.width;
    if (measured <= 0 || measured >= targetWidth) return 0;
    // Only expand when the line is near-full (matches paginator intent).
    if (measured < targetWidth - fontSize) return 0;
    final ls = (targetWidth - measured) / (n - 1);
    if (!ls.isFinite || ls.abs() > fontSize * 0.5) return 0;
    return ls;
  }

  /// Paint a single composed line. Never multi-line-wraps.
  ///
  /// Writes the final [TextLine.letterSpacing] so a later re-record of the same
  /// semantic line skips the justify measure pass.
  void _paintLine(
    TextPainter painter,
    Canvas canvas,
    TextLine line,
    TextStyle style,
    double fontSize,
    double contentWidth,
    double padLeft,
    double y,
  ) {
    final target =
        line.targetWidth > 0 ? line.targetWidth : contentWidth;
    var ls = resolveLetterSpacing(
      text: line.text,
      style: style,
      justify: line.justify && !line.isLastLine,
      targetWidth: target,
      fontSize: fontSize,
      cached: line.letterSpacing,
    );

    TextStyle lineStyle =
        ls.abs() > 0.1 ? style.copyWith(letterSpacing: ls) : style;
    painter.text = TextSpan(text: line.text, style: lineStyle);
    // Unconstrained single-line layout — never re-wrap.
    painter.layout();

    if (ls != 0 && painter.width > contentWidth && nChars(line.text) > 1) {
      final n = nChars(line.text);
      final shrink = (painter.width - contentWidth) / (n - 1);
      final adjusted = ls - shrink;
      final clamped =
          adjusted.isFinite && adjusted.abs() <= fontSize * 0.5 ? adjusted : 0.0;
      ls = clamped;
      painter.text = TextSpan(
        text: line.text,
        style: style.copyWith(letterSpacing: clamped),
      );
      painter.layout();
    }

    // Cache for the next record of this same TextLine instance.
    final prev = line.letterSpacing;
    if (prev == null || (prev - ls).abs() > 0.05) {
      line.letterSpacing = ls;
    }

    painter.paint(canvas, Offset(padLeft, y));
  }

  static int nChars(String text) => text.characters.length;

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
    // Prefer paginator-provided page height (ABI v3).
    if (page.height > lineH) {
      return page.height + 2;
    }
    var minTop = double.infinity;
    var maxBottom = 0.0;
    for (final line in page.lines) {
      if (line.top < minTop) minTop = line.top;
      final bottom = line.top + (line.height > 0 ? line.height : lineH);
      if (bottom > maxBottom) maxBottom = bottom;
    }
    if (!minTop.isFinite) minTop = 0;
    final contentH = maxBottom - minTop;
    return (contentH < lineH ? lineH : contentH) + 2;
  }

  /// Paint body lines only into a tight-height picture for continuous scroll.
  ui.Picture drawScrollContent(
    ReadPage readPage,
    int pageIdx, {
    required PaperTheme paperTheme,
  }) {
    final bool night = paperTheme == PaperTheme.night ||
        SpUtil.getBool(PrefsKeys.dark, defValue: false);
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
    final linePainter =
        TextPainter(textDirection: TextDirection.ltr, maxLines: 1);

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
    var minTop = double.infinity;
    for (final line in page.lines) {
      if (line.top < minTop) minTop = line.top;
    }
    if (!minTop.isFinite) minTop = 0;

    for (final line in page.lines) {
      final y = (line.top - minTop).clamp(0.0, tileH);
      _paintLine(
        linePainter,
        canvas,
        line,
        style,
        fontSize,
        maxLineWidth,
        contentPadding,
        y,
      );
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
    final sw = kDebugMode ? Stopwatch() : null;
    sw?.start();

    final pageRecorder = ui.PictureRecorder();

    final bool night = paperTheme == PaperTheme.night ||
        SpUtil.getBool(PrefsKeys.dark, defValue: false);
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

    // Explicit loading page (chapterName == '加载中') with a non-empty hint.
    // Blank reopen placeholders have real chapter titles + empty pages and
    // fall through to normal paint (paper only, no centered "正在加载").
    if (readPage.chapterName == '加载中') {
      final msg = readPage.chapterContent.trim();
      if (msg.isEmpty) {
        return pageRecorder.endRecording();
      }
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
      final pic = pageRecorder.endRecording();
      _logPaintPage(readPage, i, 0, sw);
      return pic;
    }

    final chromeStyle = TextStyle(
      fontSize: 12 / Screen.textScaleFactor,
      color: meta,
      fontFamily: familyOrNull,
    );

    if (chrome) {
      // Chapter title — vertically centered in the top chrome band.
      _labelPainter.text = TextSpan(
        text: readPage.chapterName,
        style: chromeStyle,
      );
      _labelPainter.layout();
      final titleY = ReadSetting.chapterTitleBandTop() +
          (ReadSetting.contentTopChrome - _labelPainter.height) / 2;
      _labelPainter.paint(
        pageCanvas,
        Offset(contentPadding, titleY),
      );
    }

    final linePainter =
        TextPainter(textDirection: TextDirection.ltr, maxLines: 1);

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
      final pic = pageRecorder.endRecording();
      _logPaintPage(readPage, i, 0, sw);
      return pic;
    }
    final pageIndex = i.clamp(0, readPage.pages.length - 1);
    final TextPage page = readPage.pages[pageIndex];
    final lineCount = page.lines.length;
    // Vertically center short middle pages in the content box (e.g. 560 in
    // 600). Chapter last page stays top-aligned so trailing space is empty.
    final isLastPage = pageIndex >= readPage.pages.length - 1;
    final contentBoxH = (pageH -
            ReadSetting.contentTopInset() -
            ReadSetting.contentBottomInset())
        .clamp(0.0, pageH);
    final contentH = _measuredContentHeight(page, fontSize);
    final centerOffset = !isLastPage && contentBoxH > contentH
        ? (contentBoxH - contentH) / 2.0
        : 0.0;
    for (var li = 0; li < lineCount; li++) {
      final line = page.lines[li];
      _paintLine(
        linePainter,
        pageCanvas,
        line,
        style,
        fontSize,
        maxLineWidth,
        contentPadding,
        line.top + bodyTop + centerOffset,
      );
    }
    if (!chrome) {
      final pic = pageRecorder.endRecording();
      _logPaintPage(readPage, i, lineCount, sw);
      return pic;
    }

    // Time + page number — vertically centered in the bottom chrome band.
    // Body box ends contentChromeGap above this band (contentBottomInset).
    final bottomBandTop = ReadSetting.bottomChromeBandTop();
    _labelPainter.text = TextSpan(
      text: DateUtil.formatDate(DateTime.now(), format: DateFormats.h_m),
      style: chromeStyle,
    );
    _labelPainter.layout();
    final bottomTextY =
        bottomBandTop + (ReadSetting.contentBottomChrome - _labelPainter.height) / 2;
    _labelPainter.paint(
      pageCanvas,
      Offset(contentPadding, bottomTextY),
    );

    final pageLabel = '${pageIndex + 1}/${readPage.pages.length}';
    _labelPainter.text = TextSpan(
      text: pageLabel,
      style: chromeStyle,
    );
    _labelPainter.layout();
    _labelPainter.paint(
      pageCanvas,
      Offset(pageW - contentPadding - _labelPainter.width, bottomTextY),
    );

    final pic = pageRecorder.endRecording();
    _logPaintPage(readPage, i, lineCount, sw);
    return pic;
  }

  void _logPaintPage(
    ReadPage readPage,
    int pageIndex,
    int lineCount,
    Stopwatch? sw,
  ) {
    if (!kDebugMode || sw == null) return;
    sw.stop();
    debugPrint(
      '[PaintPage] chapter=${readPage.chapterName} page=$pageIndex '
      'lines=$lineCount ms=${sw.elapsedMilliseconds}',
    );
  }

  /// Natural height of a page's body lines (content-local coords).
  ///
  /// Prefers paginator [TextPage.height]; falls back to last-line bottom.
  static double _measuredContentHeight(TextPage page, double fontSize) {
    if (page.lines.isEmpty) return 0;
    final lineH = fontSize * ReadSetting.getLineHeight();
    if (page.height > lineH * 0.5) return page.height;
    var maxBottom = 0.0;
    for (final line in page.lines) {
      final h = line.height > 0 ? line.height : lineH;
      final bottom = line.top + h;
      if (bottom > maxBottom) maxBottom = bottom;
    }
    return maxBottom;
  }
}
