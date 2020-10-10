import 'package:book/common/ReadSetting.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/material.dart';

class ReaderPageAgent {
  /// 文本间距
  double getPageHeight(
      String content, double height, double width, double fontSize) {
    TextPainter textPainter = layout1(content, width);
    textPainter.layout(maxWidth: width, minWidth: width);
    return textPainter.height;
  }

  List<String> getPageOffsets(String content, double height, double width) {
    // String zz = Common.page_height_pre + fontFamily;
    String tempStr = content;
    List<String> pageConfig = [];
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

    // if (SpUtil.haveKey(key)) {
    //   pageHeight = SpUtil.getDouble(key);
    // }

    // if (!SpUtil.haveKey(key)) {
    // print('fontSize ${ReadSetting.getFontSize()}');
    // print('metric ${Screen.textScaleFactor}');
    // print('line height $textLineHeight');

    // print('line ${height ~/ textLineHeight}');
    // print('all height $height');

    // }
    while (true) {
      // print(height);
      // print(pageHeight);

      //   if (SpUtil.haveKey(key)) {
      //     SpUtil.remove(key);
      //   }
      //   SpUtil.putDouble(key, pageHeight);
      // }
      textPainter = layout1(tempStr, width);
      textPainter.layout(maxWidth: width);

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

  TextPainter layout1(String text, double width) {
    TextPainter textPainter = TextPainter(textDirection: TextDirection.ltr);

    textPainter.text = TextSpan(
        text: text,
        style: TextStyle(
          locale: Locale('zh_CN'),
          fontSize: ReadSetting.getFontSize(),
          height: ReadSetting.getLatterHeight(),
          // letterSpacing: ReadSetting.getLatterSpace()
        ));
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
