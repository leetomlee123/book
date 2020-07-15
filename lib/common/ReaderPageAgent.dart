import 'package:book/common/TextLayoutCache.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/material.dart';

import 'common.dart';

class ReaderPageAgent {
  bool okHeight = false;
  String fontFamily = SpUtil.getString("fontName");

  List<int> getPageOffsets(
      String content, double height, double width, double fontSize) {
    String tempStr = content;
    List<int> pageConfig = [];
    int last = 0;
    if (SpUtil.haveKey(Common.page_height_pre + fontSize.toString())) {
      height = SpUtil.getDouble(Common.page_height_pre + fontSize.toString());
    }
    while (true) {
//      TextPainter textPainter = TextPainter(textDirection: TextDirection.ltr);
      TextPainter textPainter = layout(tempStr, fontSize, width);

      if (!SpUtil.haveKey(Common.page_height_pre + fontSize.toString())) {
        height = checkHeight(textPainter, height);
        String key = Common.page_height_pre + fontSize.toString();
        if (SpUtil.haveKey(key)) {
          SpUtil.remove(key);
        }
        SpUtil.putDouble(key, height);
      }

      var end = textPainter.getPositionForOffset(Offset(width, height)).offset;

      if (end == 0) {
        break;
      }

      tempStr = tempStr.substring(end, tempStr.length);

      pageConfig.add(last + end);
      last = last + end;
    }
    return pageConfig;
  }

  TextPainter layout(String text, double fontSize, double width) {
    TextPainter textPainter = TextLayoutCache(TextDirection.ltr, 6553600)
        .getOrPerformLayout(TextSpan(
            text: text,
            style: TextStyle(fontSize: fontSize, fontFamily: fontFamily)));
    textPainter.layout(maxWidth: width);
    return textPainter;
  }

  double checkHeight(TextPainter textPainter, double height) {
//    double textHeight = textPainter.height;
    double lineHeight = textPainter.preferredLineHeight;
//    int lineNumber = textHeight ~/ lineHeight;
    int lineNumberPerPage = height ~/ lineHeight;
//    int pageNum = (lineNumber / lineNumberPerPage).ceil();
    double actualPageHeight = lineNumberPerPage * lineHeight;
//    double temp = height;

//    while (textPainter.size.height > temp + 1.5) {
////      print(
////          "painter:${textPainter.size.height} me:${height} ${textPainter.size.height > height} strlen:${text.length}");
//
//      height -= fontSize;
//      if (height < 0) {
//        break;
//      }
//      var end = textPainter.getPositionForOffset(Offset(width, height)).offset;
//      if (end == 0) {
//        break;
//      }
//      text = text.substring(0, end);
//
//      textPainter = layout(text, fontSize, width);
//      print(textPainter.height);
//    }

//    okHeight = true;
    return actualPageHeight;
  }
}
