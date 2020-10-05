import 'package:flustars/flustars.dart';
import 'package:flutter/material.dart';


class ReaderPageAgent {
  /// 文本间距
  double getPageHeight(
      String content, double height, double width, double fontSize) {
    String fontFamily = SpUtil.getString("fontName");
    TextPainter textPainter = layout(content, fontSize, width, fontFamily);
    textPainter.layout(maxWidth: width, minWidth: width);
    return textPainter.height;
  }

  List<String> getPageOffsets(
      String content, double height, double width, double fontSize) {
    String fontFamily = SpUtil.getString("fontName");
    // String zz = Common.page_height_pre + fontFamily;
    String tempStr = content;
    List<String> pageConfig = [];
    int last = 0;
    String key=fontSize.toString();
    double pageHeight;
    if (SpUtil.haveKey(key)) {
      pageHeight = SpUtil.getDouble(key);
    }
    while (true) {
      TextPainter textPainter = layout(tempStr, fontSize, width, fontFamily);
   
      if (!SpUtil.haveKey(key)) {
        print("fontFamily$fontFamily fontheight ${textPainter.preferredLineHeight} fontSize:$fontSize");
        double textLineHeight = textPainter.preferredLineHeight;

        pageHeight = (height ~/ textLineHeight) * textLineHeight;
        print(height);

        if (SpUtil.haveKey(key)) {
          SpUtil.remove(key);
        }
        SpUtil.putDouble(key, pageHeight);
      }
      textPainter.layout(maxWidth: width, minWidth: width);

      var end =
          textPainter.getPositionForOffset(Offset(width, pageHeight)).offset;

      if (end == 0) {
        break;
      }
      String pageText = tempStr.substring(0, end);
      // print(pageText);
      // print("------------------------------------");
      pageConfig.add(pageText);

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
                textBaseline: TextBaseline.alphabetic,
                height: 1.5,
                fontFamily: fontFamily,
                fontSize: fontSize )),
        locale: Locale('zh_CN'),
        // strutStyle: StrutStyle(forceStrutHeight: true),
        textDirection: TextDirection.ltr);
    return textPainter;
  }
}
