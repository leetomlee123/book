import 'package:book/common/ReadSetting.dart';
import 'package:book/common/Screen.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/material.dart';

class ReaderPageAgent {
  /// 文本间距
  double getPageHeight(String content, double width) {
    TextPainter textPainter = getTextPainter(content, width);
    textPainter.layout(maxWidth: width, minWidth: width);
    return textPainter.height;
  }

  List<String> getPageOffsets1(
      String content, double pageHeight, double pageWidth) {
    String tempStr = content;
    List<String> pageContents = [];
    if (content.isEmpty) {
      return pageContents;
    }
    double fontSize = ReadSetting.getFontSize() * Screen.textScaleFactor;
    int maxLineCharacters =
        (pageWidth / (fontSize - ReadSetting.getLatterSpace())).floor().toInt();
    int maxPageLines =
        (pageHeight / (fontSize * ReadSetting.getLineHeight())).floor().toInt();
    print(
        "maxLineCharacters :$maxLineCharacters maxPageLines: $maxPageLines textScaleFactor:${Screen.textScaleFactor}");
    // tempStr=tempStr.replaceAll("\t\t\t\t", "^");
    while (tempStr.trim().length > 0) {
      String temp = "";
      for (var i = 0; i < maxPageLines; i++) {
        if (tempStr.trim().length == 0) {
          break;
        }
        int max = maxLineCharacters <= tempStr.length
            ? maxLineCharacters
            : tempStr.length - 1;
        String calcStr = "";
        int j = 0;
        while (j < maxLineCharacters) {
          String x = tempStr.substring(0, 1);
          if (x == "\t") {
            calcStr += tempStr.substring(0, 8);
            tempStr = tempStr.substring(8);
            j += 2;
          } else if (x == "\n") {
            calcStr += tempStr.substring(0, 1);
            tempStr = tempStr.substring(1);
            break;
          } else {
            calcStr += x;
            j += 1;
            tempStr = tempStr.substring(1);
          }
        }

        print("j: $j  calcStr :$calcStr");
        temp += calcStr;
      }

      pageContents.add(temp);
    }
    return pageContents;
  }

  List<String> getPageOffsets(
      String content, double pageHeight, double width) {
    String tempStr = content;
    List<String> pageConfig = [];
    if (content.isEmpty) {
      return pageConfig;
    }

    TextPainter textPainter = getTextPainter(tempStr, width);

    // double textHeight = textPainter.height;
    double lineHeight = textPainter.preferredLineHeight;

    // int lineNumber = textHeight ~/ lineHeight;
    int lineNumberPerPage = pageHeight ~/ lineHeight;
    // int pageNum = (lineNumber / lineNumberPerPage).ceil();
    double actualPageHeight = lineNumberPerPage * lineHeight;

    while (true) {
      textPainter = getTextPainter(tempStr, width);
      textPainter.layout(maxWidth: width);

      var end = textPainter
          .getPositionForOffset(Offset(width, actualPageHeight))
          .offset;

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

  TextPainter getTextPainter(String text, double width) {
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
