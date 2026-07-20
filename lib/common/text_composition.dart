import 'dart:convert';
import 'dart:isolate';
import 'dart:ui' as ui;

import 'package:book/common/read_setting.dart';
import 'package:book/common/screen.dart';
import 'package:book/common/app_log.dart';
import 'package:book/common/book_pager.dart';
import 'package:book/entity/read_page.dart';
import 'package:book/entity/text_line.dart';
import 'package:book/entity/text_page.dart';
import 'package:flutter/material.dart';

/// * 暂不支持图片
/// * 文本排版
/// * 两端对齐
/// * 底栏对齐
class TextComposition {
  /// 待渲染文本段落
  /// 已经预处理: 不重新计算空行 不重新缩进
  static Color darkFont = Color(0x5FFFFFFF);
  ReadPage? readPage;
  final List<String> paragraphs;
  bool? justRender;

  /// 字体样式 字号 [size] 行高 [height] 字体 [family] 字色[Color]
  TextStyle? style;

  /// 段间距
  final double paragraph;

  /// 每一页内容
  List<TextPage> pages;

  int get pageCount => pages.length;

  /// 单栏宽度
  final double columnWidth;

  /// 容器大小
  final Size boxSize;

  /// 内部边距
  final EdgeInsets? padding;

  /// 是否底栏对齐
  final bool shouldJustifyHeight;

  /// 前景 页眉页脚 菜单等
  final Widget Function(int pageIndex)? getForeground;

  /// 背景 背景色或者背景图片
  final ui.Image Function(int pageIndex)? getBackground;

  /// 是否显示动画
  bool showAnimation;

  // final Pattern? linkPattern;
  // final TextStyle? linkStyle;
  // final String Function(String s)? linkText;

  // canvas 点击事件不生效
  // final void Function(String s)? onLinkTap;

  /// * 文本排版
  /// * 两端对齐
  /// * 底栏对齐
  /// * 多栏布局
  ///
  ///
  /// * [text] 待渲染文本内容 已经预处理: 不重新计算空行 不重新缩进
  /// * [paragraphs] 待渲染文本内容 已经预处理: 不重新计算空行 不重新缩进
  /// * [paragraphs] 为空时使用[text], 否则忽略[text],
  /// * [style] 字体样式 字号 [size] 行高 [height] 字体 [family] 字色[Color]
  /// * [title] 标题
  /// * [titleStyle] 标题样式
  /// * [boxSize] 容器大小
  /// * [paragraph] 段间距
  /// * [shouldJustifyHeight] 是否底栏对齐
  /// * [columnCount] 分栏个数
  /// * [columnGap] 分栏间距
  /// * onLinkTap canvas 点击事件不生效
  TextComposition({
    String? text,
    List<String>? paragraphs,
    this.style,
    this.readPage,
    this.justRender,
    Size? boxSize,
    this.padding,
    this.shouldJustifyHeight = true,
    this.paragraph = 10.0,
    this.getForeground,
    this.getBackground,
    this.debug = false,
    List<TextPage>? pages,
    this.showAnimation = true,
    // this.linkPattern,
    // this.linkStyle,
    // this.linkText,
    // this.onLinkTap,
  })  : pages = pages ?? <TextPage>[],
        paragraphs = paragraphs ?? text?.split("\n") ?? <String>[],
        boxSize = boxSize ??
            (ui.PlatformDispatcher.instance.views.isNotEmpty
                ? ui.PlatformDispatcher.instance.views.first.physicalSize /
                    ui.PlatformDispatcher.instance.views.first.devicePixelRatio
                : const Size(360, 640)),
        columnWidth = ((boxSize ??
                    (ui.PlatformDispatcher.instance.views.isNotEmpty
                        ? ui.PlatformDispatcher.instance.views.first
                                .physicalSize /
                            ui.PlatformDispatcher.instance.views.first
                                .devicePixelRatio
                        : const Size(360, 640)))
                .width -
            (padding?.horizontal ?? 0)) {
    // ABI v3 Dart fallback: emit semantic lines (top/height/justify/targetWidth).
    // letterSpacing is computed at paint time by Flutter TextPainter.
    final tp = TextPainter(textDirection: TextDirection.ltr, maxLines: 1);
    final size = style?.fontSize ?? 14;
    final width = columnWidth;
    final width2 = width - size;
    final height = this.boxSize.height - (padding?.vertical ?? 0);
    final height2 = height - size * (style?.height ?? 1.0);
    final lineBoxH = size * (style?.height ?? 1.0);

    var lines = <TextLine>[];
    var top = 0.0;
    var startLine = 0;
    var pageIndex = 0;

    void newPage([bool shouldJustifyHeight = true, bool lastPage = false]) {
      if (shouldJustifyHeight && this.shouldJustifyHeight) {
        final len = lines.length - startLine;
        if (len > 1) {
          final justifyGap = (height - top) / (len - 1);
          if (justifyGap.isFinite && justifyGap > 0) {
            for (var i = 0; i < len; i++) {
              lines[i + startLine].justifyDy(justifyGap * i);
            }
          }
        }
      }
      final pageLines = lines;
      final pageH = pageLines.isEmpty
          ? 0.0
          : pageLines.last.top + pageLines.last.height;
      this.pages.add(TextPage(pageLines, pageH, pageIndex: pageIndex));
      pageIndex++;
      lines = <TextLine>[];
      top = 0.0;
      startLine = 0;
    }

    void newParagraph() {
      if (top > height2) {
        newPage();
      } else {
        top += paragraph;
      }
    }

    // Leave 1% width slack so paint-side metrics don't overflow.
    final measureWidth = width * 0.99;
    final measureOffset = Offset(measureWidth, 1);

    for (var p in this.paragraphs) {
      while (true) {
        tp.text = TextSpan(text: p, style: style);
        tp.layout(maxWidth: measureWidth);
        final textCount = tp.getPositionForOffset(measureOffset).offset;
        if (textCount <= 0) {
          final forceEnd = p.isEmpty
              ? 0
              : (p.length > 1 &&
                      p.codeUnitAt(0) >= 0xD800 &&
                      p.codeUnitAt(0) <= 0xDBFF
                  ? 2
                  : 1)
                  .clamp(1, p.length);
          final text = p.substring(0, forceEnd);
          final isEnd = p.length == forceEnd;
          lines.add(TextLine(
            text,
            top: top,
            height: lineBoxH,
            justify: false,
            isLastLine: isEnd,
            isParagraphEnd: isEnd,
            targetWidth: width,
          ));
          top += lineBoxH;
          if (isEnd) {
            newParagraph();
            break;
          }
          p = p.substring(forceEnd);
          if (top > height2) newPage();
          continue;
        }
        final text = p.substring(0, textCount);
        tp.text = TextSpan(text: text, style: style);
        tp.layout();
        final measured = tp.width;
        final isEnd = p.length == textCount;
        final n = text.characters.length;
        final nearlyFull = measured > width2 && measured > size * 0.5;
        final doJustify = !isEnd && nearlyFull && n > 1;
        final h = tp.height > 0 ? tp.height : lineBoxH;
        lines.add(TextLine(
          text,
          top: top,
          height: h,
          justify: doJustify,
          isLastLine: isEnd,
          isParagraphEnd: isEnd,
          targetWidth: width,
        ));
        top += h;
        if (isEnd) {
          newParagraph();
          break;
        } else {
          p = p.substring(textCount);
          if (top > height2) {
            newPage();
          }
        }
      }
    }
    if (lines.isNotEmpty) {
      newPage(false, true);
    }
    if (this.pages.isEmpty) {
      this.pages.add(const TextPage([], 0));
    }
  }

  /// 调试模式 输出布局信息
  bool debug;

  static void dataLoader(SendPort sendPort) async {
    // 打开ReceivePort①以接收传入的消息
    ReceivePort port = ReceivePort();

    // 通知其他的isolates，本isolate 所监听的端口
    sendPort.send(port.sendPort);
    // 获取其他端口发送的异步消息 msg② -> ["https://jsonplaceholder.typicode.com/posts", response.sendPort]
    await for (var msg in port) {
      SendPort replyToPort = msg[0];
      ReadPage readPage = ReadPage.fromJson(jsonDecode(msg[1]));

      double w = double.parse(msg[2].toString());
      double h = double.parse(msg[3].toString());
      String fontFamily = msg[4].toString();
      double fontSize = double.parse(msg[5].toString());
      double height = double.parse(msg[6].toString());
      double dis = double.parse(msg[7].toString());
      double paragraph = double.parse(msg[8].toString());

      TextComposition textComposition = TextComposition(
        text: readPage.chapterContent,
        readPage: readPage,
        style: TextStyle(
            // color: dark == 1 ? darkFont : Colors.black,
            // locale: Locale('zh_CN'),
            fontFamily: fontFamily,
            fontSize: fontSize,
            // letterSpacing: ReadSetting.getLatterSpace(),
            height: height),
        paragraph: paragraph,
        justRender: true,
        boxSize: Size(w, h),
        padding: EdgeInsets.symmetric(horizontal: dis),
        shouldJustifyHeight: true,
        debug: false,
      );
      List<TextPage> parseContent2 = textComposition.pages;

      String result = jsonEncode(parseContent2);

      replyToPort.send([result]);
    }
  }

  /// Collect layout metrics on the UI isolate (SpUtil / Screen are main-only).
  static Map<String, dynamic> layoutParams({
    bool shouldJustifyHeight = true,
  }) {
    final fontSize = ReadSetting.getFontSize();
    final lineHeight = ReadSetting.getLineHeight();
    // Content box uses shared insets from ReadSetting so paint + paginate match.
    // Never allow a non-positive height — that collapses pagination to one line.
    final topPad = ReadSetting.contentTopInset();
    final bottomPad = ReadSetting.contentBottomInset();
    final rawH = Screen.height - topPad - bottomPad;
    final boxH =
        rawH > 120 ? rawH : (Screen.height * 0.7).clamp(200.0, 2000.0);
    final boxW = Screen.width > 0 ? Screen.width : 360.0;
    return <String, dynamic>{
      'fontSize': fontSize,
      'lineHeight': lineHeight,
      'paragraph': ReadSetting.getParagraph() * fontSize * lineHeight,
      'padH': ReadSetting.getPageDis().toDouble(),
      'boxW': boxW,
      'boxH': boxH,
      'fontFamily': ReadSetting.getFontFamily(),
      'fontPath': ReadSetting.getFontPath(),
      'shouldJustifyHeight': shouldJustifyHeight,
      // Bump cache when pager contract changes.
      'abi': bookPagerAbiVersion,
      'textAlign': 'justify',
    };
  }

  /// Sync parse — may block the current isolate. Prefer [parseContentAsync].
  static List<TextPage> parseContent(ReadPage readPage,
      {shouldJustifyHeight = true, justRender = false}) {
    final p = layoutParams(shouldJustifyHeight: shouldJustifyHeight == true);
    return _parseWithParams(readPage, p, justRender: justRender == true);
  }

  /// Async parse: Rust path runs in a **background isolate**; Dart fallback
  /// stays on the caller isolate (TextPainter needs the Flutter binding).
  static Future<List<TextPage>> parseContentAsync(ReadPage readPage,
      {bool shouldJustifyHeight = true, bool justRender = false}) async {
    final p = layoutParams(shouldJustifyHeight: shouldJustifyHeight);
    final fontSize = p['fontSize'] as double;
    final lineHeight = p['lineHeight'] as double;
    final paragraph = p['paragraph'] as double;
    final padH = p['padH'] as double;
    final boxW = p['boxW'] as double;
    final boxH = p['boxH'] as double;
    final fontFamily = p['fontFamily'] as String;
    final fontPath = p['fontPath'] as String? ?? '';

    final nativeOk = BookPager.isAvailable;
    // Always print engine probe so real-device logcat can filter "PagerEngine".
    debugPrint(
      '[PagerEngine] probe native=$nativeOk '
      'err=${BookPager.lastError ?? "-"} '
      'contentLen=${readPage.chapterContent.length} '
      'box=${boxW.toStringAsFixed(0)}x${boxH.toStringAsFixed(0)} '
      'font=$fontSize',
    );
    AppLog.i(
      'Pager',
      'layout boxW=$boxW boxH=$boxH fontSize=$fontSize '
          'lineHeight=$lineHeight padH=$padH family=$fontFamily '
          'fontPath=${fontPath.isEmpty ? "-" : fontPath} '
          'contentLen=${readPage.chapterContent.length} '
          'native=$nativeOk err=${BookPager.lastError ?? "-"}',
    );

    if (nativeOk && fontPath.isNotEmpty) {
      try {
        final pages = await BookPager.paginateAsync(
          text: readPage.chapterContent,
          fontSize: fontSize,
          lineHeight: lineHeight,
          paragraph: paragraph,
          boxWidth: boxW,
          boxHeight: boxH,
          paddingHorizontal: padH,
          paddingVertical: 0,
          shouldJustifyHeight: shouldJustifyHeight,
          fontPath: fontPath,
          fontFamily: fontFamily,
        );
        final totalLines = pages.fold<int>(0, (n, p) => n + p.lines.length);
        if (!_looksBrokenPagination(
            pages, readPage.chapterContent, boxW, fontSize)) {
          debugPrint(
            '[PagerEngine] ENGINE=RUST pages=${pages.length} '
            'lines=$totalLines lines0=${pages.isEmpty ? 0 : pages.first.lines.length}',
          );
          AppLog.i(
            'Pager',
            'ENGINE=RUST pages=${pages.length} totalLines=$totalLines '
                'lines0=${pages.isEmpty ? 0 : pages.first.lines.length}',
          );
          return pages;
        }
        debugPrint(
          '[PagerEngine] ENGINE=DART reason=rust_broken_pagination '
          'pages=${pages.length} lines=$totalLines',
        );
        AppLog.w(
          'Pager',
          'ENGINE=DART reason=rust_broken (single overlong line) '
              'pages=${pages.length} lines=$totalLines',
        );
      } catch (e, st) {
        debugPrint('[PagerEngine] ENGINE=DART reason=rust_exception $e');
        AppLog.w('Pager', 'ENGINE=DART reason=rust_exception', error: e);
        debugPrint('BookPager async failed, falling back to Dart: $e\n$st');
      }
    } else if (nativeOk && fontPath.isEmpty) {
      debugPrint(
        '[PagerEngine] ENGINE=DART reason=font_path_empty '
        '(need assets/fonts/NotoSansSC-Regular.ttf or custom font)',
      );
      AppLog.i('Pager', 'ENGINE=DART reason=font_path_empty');
    } else {
      debugPrint(
        '[PagerEngine] ENGINE=DART reason=native_unavailable '
        'err=${BookPager.lastError ?? "-"}',
      );
      AppLog.i(
        'Pager',
        'ENGINE=DART reason=native_unavailable err=${BookPager.lastError ?? "-"}',
      );
    }

    // Yield once so loading UI can paint before heavy TextPainter work.
    await Future<void>.delayed(Duration.zero);
    final dartPages = _dartParse(
      readPage,
      fontSize: fontSize,
      lineHeight: lineHeight,
      paragraph: paragraph,
      padH: padH,
      boxW: boxW,
      boxH: boxH,
      fontFamily: fontFamily,
      shouldJustifyHeight: shouldJustifyHeight,
      justRender: justRender,
    );
    final dartLines = dartPages.fold<int>(0, (n, p) => n + p.lines.length);
    debugPrint(
      '[PagerEngine] ENGINE=DART pages=${dartPages.length} lines=$dartLines',
    );
    AppLog.i(
      'Pager',
      'ENGINE=DART pages=${dartPages.length} totalLines=$dartLines '
          'lines0=${dartPages.isEmpty ? 0 : dartPages.first.lines.length}',
    );
    return dartPages;
  }

  /// Detect "whole chapter as one TextLine" failure mode from native pager.
  static bool _looksBrokenPagination(
    List<TextPage> pages,
    String content,
    double boxW,
    double fontSize,
  ) {
    if (content.trim().length < 40) return false;
    if (pages.isEmpty) return true;
    final totalLines = pages.fold<int>(0, (n, p) => n + p.lines.length);
    if (totalLines == 0) return true;
    // One visual line for a long chapter is always wrong.
    if (totalLines == 1 && content.trim().length > 60) return true;
    final maxChars = (boxW / (fontSize * 0.85)).floor().clamp(8, 200);
    for (final p in pages) {
      for (final line in p.lines) {
        if (line.text.characters.length > maxChars * 2) return true;
      }
    }
    return false;
  }

  static List<TextPage> _parseWithParams(
    ReadPage readPage,
    Map<String, dynamic> p, {
    bool justRender = false,
  }) {
    final fontSize = p['fontSize'] as double;
    final lineHeight = p['lineHeight'] as double;
    final paragraph = p['paragraph'] as double;
    final padH = p['padH'] as double;
    final boxW = p['boxW'] as double;
    final boxH = p['boxH'] as double;
    final fontFamily = p['fontFamily'] as String;
    final fontPath = p['fontPath'] as String? ?? '';
    final shouldJustifyHeight = p['shouldJustifyHeight'] as bool? ?? true;

    if (BookPager.isAvailable && fontPath.isNotEmpty) {
      try {
        return BookPager.paginate(
          text: readPage.chapterContent,
          fontSize: fontSize,
          lineHeight: lineHeight,
          paragraph: paragraph,
          boxWidth: boxW,
          boxHeight: boxH,
          paddingHorizontal: padH,
          paddingVertical: 0,
          shouldJustifyHeight: shouldJustifyHeight,
          fontPath: fontPath,
          fontFamily: fontFamily,
        );
      } catch (e, st) {
        AppLog.w('Pager', 'BookPager sync failed, Dart fallback', error: e);
        debugPrint(
          '[PagerEngine] ENGINE=DART reason=rust_exception $e',
        );
        debugPrint('BookPager failed, falling back to Dart: $e\n$st');
      }
    } else if (nativeOkMissingPath(fontPath)) {
      debugPrint(
        '[PagerEngine] ENGINE=DART reason=font_path_empty',
      );
    }
    return _dartParse(
      readPage,
      fontSize: fontSize,
      lineHeight: lineHeight,
      paragraph: paragraph,
      padH: padH,
      boxW: boxW,
      boxH: boxH,
      fontFamily: fontFamily,
      shouldJustifyHeight: shouldJustifyHeight,
      justRender: justRender,
    );
  }

  static bool nativeOkMissingPath(String fontPath) =>
      BookPager.isAvailable && fontPath.isEmpty;

  static List<TextPage> _dartParse(
    ReadPage readPage, {
    required double fontSize,
    required double lineHeight,
    required double paragraph,
    required double padH,
    required double boxW,
    required double boxH,
    required String fontFamily,
    required bool shouldJustifyHeight,
    bool justRender = false,
  }) {
    final textComposition = TextComposition(
      text: readPage.chapterContent,
      readPage: readPage,
      style: TextStyle(
          locale: Locale('zh_CN'),
          fontFamily: (fontFamily.isEmpty || fontFamily == 'Roboto')
              ? ReadSetting.defaultFontFamily
              : fontFamily,
          fontSize: fontSize,
          height: lineHeight),
      paragraph: paragraph,
      justRender: justRender,
      boxSize: Size(boxW, boxH),
      padding: EdgeInsets.symmetric(horizontal: padH),
      shouldJustifyHeight: shouldJustifyHeight,
      debug: false,
    );
    return textComposition.pages;
  }
}
//  static void painterPage(SendPort sendPort) async {
//     // 打开ReceivePort①以接收传入的消息
//     ReceivePort port = ReceivePort();

//     // 通知其他的isolates，本isolate 所监听的端口
//     sendPort.send(port.sendPort);
//     // 获取其他端口发送的异步消息 msg② -> ["https://jsonplaceholder.typicode.com/posts", response.sendPort]
//     await for (var msg in port) {
//       SendPort replyToPort = msg[0];
//       ReadPage readPage = ReadPage.fromJson(jsonDecode(msg[1]));

//       double w = double.parse(msg[2].toString());
//       double h = double.parse(msg[3].toString());
//       String fontFamily = msg[4].toString();
//       double fontSize = double.parse(msg[5].toString());
//       double height = double.parse(msg[6].toString());
//       double dis = double.parse(msg[7].toString());
//       double paragraph = double.parse(msg[8].toString());

//       TextComposition textComposition = TextComposition(
//         text: readPage.chapterContent,
//         readPage: readPage,
//         style: TextStyle(
//             // color: dark == 1 ? darkFont : Colors.black,
//             // locale: Locale('zh_CN'),
//             fontFamily: fontFamily,
//             fontSize: fontSize,
//             // letterSpacing: ReadSetting.getLatterSpace(),
//             height: height),
//         paragraph: paragraph,
//         justRender: true,
//         boxSize: Size(w, h),
//         padding: EdgeInsets.symmetric(horizontal: dis),
//         shouldJustifyHeight: true,
//         debug: false,
//       );
//       List<TextPage> parseContent2 = textComposition.pages;

//       String result = jsonEncode(parseContent2);

//       replyToPort.send([result]);
//     }
//   }
class SelfForePainter extends CustomPainter {
  final ui.Image _imageFrame;

  SelfForePainter(this._imageFrame) : super();

  @override
  void paint(Canvas canvas, Size size) {
    Paint selfPaint = Paint()
      ..style = PaintingStyle.fill
      ..isAntiAlias = true
      ..strokeCap = StrokeCap.butt
      ..strokeWidth = 30.0;
    canvas.drawImage(_imageFrame, Offset(0, 0), selfPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) {
    return true;
  }
}

class MyPagePainter extends CustomPaint {
  final ReadPage readPage;
  final CustomPainter? forePainter;
  final TextStyle style;
  final int pageIndex;
  final bool debug;
  final TextPage page;

  MyPagePainter(this.pageIndex, this.readPage, this.style, this.forePainter,
      {super.key, this.debug = false})
      : page = readPage.pages[pageIndex],
        super(foregroundPainter: forePainter);
}

class PagePainter extends CustomPainter {
  final TextPage page;
  final TextStyle style;
  final int pageIndex;
  final bool debug;

  const PagePainter(this.pageIndex, this.page, this.style,
      [this.debug = false]);

  @override
  void paint(Canvas canvas, Size size) {
    final lineCount = page.lines.length;
    final tp = TextPainter(textDirection: TextDirection.ltr, maxLines: 1);

    for (var i = 0; i < lineCount; i++) {
      final line = page.lines[i];
      // ABI v3: Flutter computes letterSpacing from justify + targetWidth.
      final target = line.targetWidth > 0 ? line.targetWidth : size.width;
      var ls = line.letterSpacing;
      if (ls == null || !ls.isFinite) {
        ls = 0;
        if (line.justify && !line.isLastLine && target > 0) {
          final n = line.text.characters.length;
          if (n > 1) {
            tp.text = TextSpan(text: line.text, style: style);
            tp.layout();
            final measured = tp.width;
            if (measured > 0 &&
                measured < target &&
                measured > target - (style.fontSize ?? 14)) {
              final v = (target - measured) / (n - 1);
              if (v.isFinite && v.abs() <= (style.fontSize ?? 14) * 0.5) {
                ls = v;
              }
            }
          }
        }
      }
      final lineStyle =
          ls.abs() > 0.1 ? style.copyWith(letterSpacing: ls) : style;
      tp.text = TextSpan(text: line.text, style: lineStyle);
      tp.layout();
      if (ls != 0 && tp.width > size.width) {
        final n = line.text.characters.length;
        if (n > 1) {
          final shrink = (tp.width - size.width) / (n - 1);
          final adjusted = ls - shrink;
          final clamped =
              adjusted.isFinite && adjusted.abs() <= (style.fontSize ?? 14) * 0.5
                  ? adjusted
                  : 0.0;
          tp.text = TextSpan(
            text: line.text,
            style: style.copyWith(letterSpacing: clamped),
          );
          tp.layout();
        }
      }
      // x = padding is already baked into style box; page painter uses pad 0.
      tp.paint(canvas, Offset(0, line.top));
    }
  }

  @override
  bool shouldRepaint(PagePainter old) {
    return old.pageIndex != pageIndex;
  }
}
