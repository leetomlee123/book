import 'package:book/common/TextLayoutCache.dart';
import 'package:flutter/material.dart';

class ReaderPageAgent {
  static List<int> getPageOffsets(
      String content, double height, double width, double fontSize) {
    String tempStr = content;
    List<int> pageConfig = [];
    int last = 0;

    while (true) {
//      TextPainter textPainter = TextPainter(textDirection: TextDirection.ltr);
      var textPainter = TextLayoutCache(TextDirection.ltr, 6553600)
          .getOrPerformLayout(
              TextSpan(text: tempStr, style: TextStyle(fontSize: fontSize)));
      textPainter.layout(maxWidth: width);
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
}
