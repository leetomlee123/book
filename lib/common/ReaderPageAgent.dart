import 'package:flustars/flustars.dart';
import 'package:flutter/material.dart';

import 'common.dart';

class ReaderPageAgent {
  bool okHeight = false;

  List<String> getPageOffsets(
      String content, double height, double width, double fontSize) {
    String fontFamily = SpUtil.getString("fontName");
    String zz = Common.page_height_pre + fontFamily;
    String tempStr = content;
    List<String> pageConfig = [];
    int last = 0;
    if (SpUtil.haveKey(zz + fontSize.toString())) {
      height = SpUtil.getDouble(zz + fontSize.toString());
    }
    while (true) {
      TextPainter textPainter = layout(tempStr, fontSize, width, fontFamily);

      if (!SpUtil.haveKey(zz + fontSize.toString())) {
        height = checkHeight(textPainter, height);
        String key = zz + fontSize.toString();
        if (SpUtil.haveKey(key)) {
          SpUtil.remove(key);
        }
        SpUtil.putDouble(key, height);
      }
      textPainter.layout(maxWidth: width, minWidth: width);

      var end = textPainter.getPositionForOffset(Offset(width, height)).offset;

      if (end == 0) {
        break;
      }
      pageConfig.add(tempStr.substring(0, end));

      tempStr = tempStr.substring(end, tempStr.length);

      while (tempStr.startsWith("\n")) {
        tempStr = tempStr.substring(1);
      }
      last = last + end;
    }
    return pageConfig;
  }

  TextPainter layout(
      String text, double fontSize, double width, String fontFamily) {
    TextPainter textPainter = TextPainter(
        text: TextSpan(
            text: text,

            style: TextStyle(
              fontFamily: fontFamily,
              fontSize: fontSize,
            )),
        strutStyle:  StrutStyle(
          fontFamily: fontFamily,
          fontSize: fontSize,

        ),
        textDirection: TextDirection.ltr);
    return textPainter;
  }

  double checkHeight(TextPainter textPainter, double height) {

    double lineHeight = textPainter.preferredLineHeight;
    print("lineHeight:$lineHeight");
    int lineNumberPerPage = height ~/ lineHeight;
    print(lineNumberPerPage);
    double actualPageHeight = lineNumberPerPage * lineHeight;

    return actualPageHeight;
  }
}
