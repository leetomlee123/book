import 'dart:convert';
import 'dart:isolate';
import 'dart:ui' as ui;

import 'package:book/common/ReadSetting.dart';
import 'package:book/common/Screen.dart';
import 'package:book/entity/ReadPage.dart';
import 'package:book/entity/TextLine.dart';
import 'package:book/entity/TextPage.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/material.dart';

/// * 暂不支持图片
/// * 文本排版
/// * 两端对齐
/// * 底栏对齐
class TextComposition {
  /// 待渲染文本段落
  /// 已经预处理: 不重新计算空行 不重新缩进
  static Color darkFont = Color(0x5FFFFFFF);
  ReadPage readPage;
  final List<String> paragraphs;
  bool justRender;

  /// 字体样式 字号 [size] 行高 [height] 字体 [family] 字色[Color]
  TextStyle style;

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
  final EdgeInsets padding;

  /// 是否底栏对齐
  final bool shouldJustifyHeight;

  /// 前景 页眉页脚 菜单等
  final Widget Function(int pageIndex) getForeground;

  /// 背景 背景色或者背景图片
  final ui.Image Function(int pageIndex) getBackground;

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
    String text,
    List<String> paragraphs,
    this.style,
    this.readPage,
    this.justRender,
    Size boxSize,
    this.padding,
    this.shouldJustifyHeight = true,
    this.paragraph = 10.0,
    this.getForeground,
    this.getBackground,
    this.debug = false,
    List<TextPage> pages,
    this.showAnimation = true,
    // this.linkPattern,
    // this.linkStyle,
    // this.linkText,
    // this.onLinkTap,
  })  : pages = pages ?? <TextPage>[],
        paragraphs = paragraphs ?? text?.split("\n") ?? <String>[],
        boxSize =
            boxSize ?? ui.window.physicalSize / ui.window.devicePixelRatio,
        columnWidth = (boxSize.width - (padding?.horizontal ?? 0)) {
    // [_width2] [_height2] 用于调整判断
    final tp = TextPainter(textDirection: TextDirection.ltr, maxLines: 1);
    final offset = Offset(columnWidth, 1);
    final size = style.fontSize ?? 14;
    final _dx = padding?.left ?? 0;
    final _dy = padding?.top ?? 0;
    final _width = columnWidth;
    final _width2 = _width - size;
    final _height = this.boxSize.height - (padding?.vertical ?? 0);
    final _height2 = _height - size * (style.height ?? 1.0);

    var lines = <TextLine>[];
    var columnNum = 1;
    var dx = _dx;
    var dy = _dy;
    var startLine = 0;

    /// 下一页 判断分页 依据: `_boxHeight` `_boxHeight2`是否可以容纳下一行
    void newPage([bool shouldJustifyHeight = true, bool lastPage = false]) {
      if (shouldJustifyHeight && this.shouldJustifyHeight) {
        final len = lines.length - startLine;
        double justify = (_height - dy) / (len - 1);
        for (var i = 0; i < len; i++) {
          lines[i + startLine].justifyDy(justify * i);
        }
      }
      if (columnNum == 1 || lastPage) {
        this.pages.add(TextPage(lines, dy));
        lines = <TextLine>[];
        columnNum = 1;
        dx = _dx;
      } else {
        columnNum++;
        dx += columnWidth + 40;
      }
      dy = _dy;
      startLine = lines.length;
    }

    /// 新段落
    void newParagraph() {
      if (dy > _height2) {
        newPage();
      } else {
        dy += paragraph;
      }
    }

    for (var p in this.paragraphs) {
      while (true) {
        tp.text = TextSpan(text: p, style: style);
        tp.layout(maxWidth: columnWidth);
        final textCount = tp.getPositionForOffset(offset).offset;
        double spacing;
        final text = p.substring(0, textCount);
        if (tp.width > _width2) {
          tp.text = TextSpan(text: text, style: style);
          tp.layout();
          spacing = (_width - tp.width) / textCount;
        }
        lines.add(TextLine(text, dx, dy, spacing ?? 0));
        dy += tp.height;

        if (p.length == textCount) {
          newParagraph();
          break;
        } else {
          p = p.substring(textCount);
          if (dy > _height2) {
            newPage();
          }
        }
      }
    }
    if (lines.isNotEmpty) {
      newPage(false, true);
    }
    if (this.pages.length == 0) {
      this.pages.add(TextPage([], 0));
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

  static List<TextPage> parseContent(ReadPage readPage,
      {shouldJustifyHeight = true, justRender = false}) {
    TextComposition textComposition = TextComposition(
      text: readPage.chapterContent,
      readPage: readPage,
      style: TextStyle(
          locale: Locale('zh_CN'),
          fontFamily: SpUtil.getString("fontName", defValue: "Roboto"),
          fontSize: ReadSetting.getFontSize(),
          // letterSpacing: ReadSetting.getLatterSpace(),
          height: ReadSetting.getLineHeight()),
      paragraph: ReadSetting.getParagraph() *
          ReadSetting.getFontSize() *
          ReadSetting.getLineHeight(),
      justRender: justRender,
      boxSize: Size(Screen.width, Screen.height - 30 * 2),
      padding:
          EdgeInsets.symmetric(horizontal: ReadSetting.getPageDis().toDouble()),
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
  ui.Image _imageFrame;

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
  final CustomPainter forePainter;
  final TextStyle style;
  final int pageIndex;
  final bool debug;
  TextPage page;

  MyPagePainter(this.pageIndex, this.readPage, this.style, this.forePainter,
      [this.debug = false])
      : page = readPage.pages[pageIndex],
        super(foregroundPainter: forePainter);

  @override
  void paint(Canvas canvas, Size size) {
    final lineCount = page.lines.length;
    final tp = TextPainter(textDirection: TextDirection.ltr, maxLines: 1);

    for (var i = 0; i < lineCount; i++) {
      final line = page.lines[i];
      if (line.letterSpacing != null &&
          (line.letterSpacing < -0.1 || line.letterSpacing > 0.1)) {
        tp.text = TextSpan(
          text: line.text,
          style: style.copyWith(letterSpacing: line?.letterSpacing),
        );
      } else {
        tp.text = TextSpan(text: line.text, style: style);
      }
      final offset = Offset(line.dx, line.dy);
      tp.layout();
      tp.paint(canvas, offset);
    }
  }

  @override
  bool shouldRepaint(MyPagePainter old) {
    return old.pageIndex != pageIndex;
  }
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
    if (debug)
      print("****** [TextComposition paint start] [${DateTime.now()}] ******");
    final lineCount = page.lines.length;
    final tp = TextPainter(textDirection: TextDirection.ltr, maxLines: 1);

    for (var i = 0; i < lineCount; i++) {
      final line = page.lines[i];
      if (line.letterSpacing != null &&
          (line.letterSpacing < -0.1 || line.letterSpacing > 0.1)) {
        tp.text = TextSpan(
          text: line.text,
          style: style.copyWith(letterSpacing: line?.letterSpacing),
        );
      } else {
        tp.text = TextSpan(text: line.text, style: style);
      }
      final offset = Offset(line.dx, line.dy);
      tp.layout();
      tp.paint(canvas, offset);
    }
  }

  @override
  bool shouldRepaint(PagePainter old) {
    return old.pageIndex != pageIndex;
  }
}
