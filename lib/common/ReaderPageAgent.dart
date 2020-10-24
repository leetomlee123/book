import 'package:book/common/ReadSetting.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui;

class ReaderPageAgent {
  /// 文本间距
  double getPageHeight(String content, double width) {
    TextPainter textPainter = layout1(content, width);
    textPainter.layout(maxWidth: width, minWidth: width);
    return textPainter.height;
  }

  List<String> getPageContents(String content, double height, double width) {
    String tempContent;
    List<String> pageConfig = [];
    // List<ReaderChapterPageContentConfig> pageConfigList = [];
    double currentHeight = 0;
    double fontSize = ReadSetting.getFontSize();
    double lineHeight = ReadSetting.getLatterHeight();

    double paragraphSpacing = ReadSetting.getLatterSpace();
    TextPainter textPainter = TextPainter(textDirection: TextDirection.ltr);

    if (content == null) {
      return [];
    }
    List<String> paragraphs = content.split("\n");
    while (paragraphs.length > 0) {
      List<String> pageContents = [];
      while (currentHeight < height) {
        /// 如果最后一行再添一行比页面高度大，或者已经没有内容了，那么当前页面计算结束
        if (currentHeight + lineHeight >= height || paragraphs.length == 0) {
          break;
        }

        tempContent = paragraphs[0];

        /// 配置画笔 ///
        textPainter.text = TextSpan(
            text: tempContent,
            style:
                TextStyle(fontSize: fontSize.toDouble(), height: lineHeight / fontSize));
        textPainter.layout(maxWidth: width);

        /// 当前段落内容计算偏移量
        /// 为什么要减一个lineHeight？因为getPositionForOffset判断依据是只要能展示，即使展示不全，也在它的判定范围内，所以如需要减去一行高度
        int endOffset = textPainter
            .getPositionForOffset(
                Offset(width, height - currentHeight - lineHeight))
            .offset;

        /// 当前展示内容
        String currentParagraphContent = tempContent;

        /// 改变当前计算高度
        List<ui.LineMetrics> lineMetrics = textPainter.computeLineMetrics();

        /// 如果当前段落的内容展示不下，那么裁剪出展示内容，剩下内容填回去,否则移除顶部,计算下一个去
        if (endOffset < tempContent.length) {
          currentParagraphContent = tempContent.substring(0, endOffset);
          // pageConfig.add(currentParagraphContent);

          /// 剩余内容
          String leftParagraphContent = tempContent.substring(endOffset);

          /// 填入原先的段落数组中
          paragraphs[0] = leftParagraphContent;

          /// 改变当前计算高度,既然当前内容展示不下，那么currentHeight自然是height了
          currentHeight = height;
        } else {
          paragraphs.removeAt(0);
          currentHeight += lineHeight* lineMetrics.length;
          currentHeight += paragraphSpacing;
        }
        pageContents.add(currentParagraphContent);
        // config.paragraphContents.add(currentParagraphContent);
      }

      pageConfig.add(pageContents.join('\n'));
      currentHeight = 0;
    }

    return pageConfig;
  }

  List<String> getPageOffsets(String content, double height, double width) {
    // String zz = Common.page_height_pre + fontFamily;
    String tempStr = content;
    List<String> pageConfig = [];
    if (content.isEmpty) {
      return pageConfig;
    }
    int last = 0;
    String key = ReadSetting.getFontSize().toString();
    TextPainter textPainter = layout1(tempStr, width);
    double textLineHeight = (textPainter.preferredLineHeight);
    double pageHeight;
    if (SpUtil.haveKey(key)) {
      pageHeight = SpUtil.getDouble(key);
    } else {
      pageHeight = (height ~/ textLineHeight) * textLineHeight;
      SpUtil.putDouble(key, pageHeight);
    }

    while (true) {
      textPainter = layout1(tempStr, width);
      textPainter.layout(maxWidth: width);

      var end =
          textPainter.getPositionForOffset(Offset(width, pageHeight)).offset;

      if (end == 0) {
        break;
      }
      String pageText = tempStr.substring(0, end);

      pageConfig.add(pageText);

      tempStr = tempStr.substring(end, tempStr.length);

      while (tempStr.startsWith("\n")) {
        tempStr = tempStr.substring(1);
      }
      last = last + end;
    }
    return pageConfig;
  }

  TextPainter layout1(String text, double width) {
    TextPainter textPainter = TextPainter(textDirection: TextDirection.ltr);

    textPainter.text = TextSpan(
        text: text,
        style: TextStyle(
          locale: Locale('zh_CN'),
          fontSize: ReadSetting.getFontSize(),
        ));
    // height: ReadSetting.getLatterHeight(),
    // letterSpacing: ReadSetting.getLatterSpace()));
    // TextPainter textPainter = TextPainter(
    //     text: TextSpan(
    //         text: text,
    //         style: TextStyle(
    //             textBaseline: TextBaseline.alphabetic,
    //             // height: 1.5,

    //             fontSize: ReadSetting.getFontSize())),
    //     locale: Locale('zh_CN'),
    //     // strutStyle: StrutStyle(forceStrutHeight: true),
    //     textDirection: TextDirection.ltr);
    return textPainter;
  }
}
