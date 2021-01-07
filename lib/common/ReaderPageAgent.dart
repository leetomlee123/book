import 'package:book/common/ReadSetting.dart';
import 'package:book/common/Screen.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/material.dart';

class ReaderPageAgent {
  /// 文本间距
  double getPageHeight(String content, double width) {
    TextPainter textPainter = layout1(content, width);
    textPainter.layout(maxWidth: width, minWidth: width);
    return textPainter.height;
  }



  List<String> getPageOffsets(String content, double height, double width) {
    // String zz = Common.page_height_pre + fontFamily;
    String tempStr = content;
    List<String> pageConfig = [];
    if (content.isEmpty) {
      return pageConfig;
    }
    TextPainter textPainter = layout1(tempStr, width);
    double textLineHeight = (textPainter.preferredLineHeight);
    int pageLines = (height / textLineHeight).floor()-1;
    double pageHeight =pageLines * textLineHeight;

    while (true) {
      textPainter = layout1(tempStr, width);
      textPainter.layout(maxWidth: width);

      var end =
          textPainter.getPositionForOffset(Offset(width, pageHeight)).offset;

      if (end == 0) {
        break;
      }

      pageConfig.add(end.toString());

      tempStr = tempStr.substring(end, tempStr.length);

      while (tempStr.startsWith("\n")) {
        tempStr = tempStr.substring(1);
      }
    }
    return pageConfig;
  }

  TextPainter layout1(String text, double width) {
    TextPainter textPainter = TextPainter(
        textDirection: TextDirection.ltr,
        textScaleFactor: Screen.textScaleFactor);

    textPainter.text = TextSpan(
        text: text,
        style: TextStyle(
            locale: Locale('zh_CN'),
            fontFamily: SpUtil.getString("fontName", defValue: "Roboto"),
            fontSize: ReadSetting.getFontSize(),
            letterSpacing: ReadSetting.getLatterSpace(),
            height: ReadSetting.getLineHeight()));
   
    return textPainter;
  }
}
