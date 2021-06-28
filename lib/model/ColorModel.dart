import 'dart:typed_data';

import 'package:book/common/common.dart';
import 'package:book/event/event.dart';
import 'package:book/service/CustomCacheManager.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flustars/flustars.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class ColorModel with ChangeNotifier {
  BuildContext buildContext;
  bool dark = false;

  List<Color> skins = FlexScheme.values
      .map((e) => FlexColorScheme.light(
            scheme: e,
          ).toTheme.primaryColor)
      .toList();
  // List<FlexScheme> skins = FlexThemeModeSwitch(themeMode: themeMode, onThemeModeChanged: onThemeModeChanged, flexSchemeData: flexSchemeData)
  String savePath = "";
  Map fonts = {
    "Roboto": "默认字体",
    "方正新楷体": "https://oss-asq-download.11222.cn/font/package/FZXKTK.TTF",
    "方正稚艺": "http://oss-asq-download.11222.cn/font/package/FZZHYK.TTF",
    "方正魏碑": "http://oss-asq-download.11222.cn/font/package/FZWBK.TTF",
    "方正苏新诗柳楷": "https://oss-asq-download.11222.cn/font/package/FZSXSLKJW.TTF",
    "方正宋刻本秀楷体": "https://oss-asq-download.11222.cn/font/package/FZSKBXKK.TTF",
    "方正卡通": "http://oss-asq-download.11222.cn/font/package/FZKATK.TTF",
  };
  int idx = SpUtil.getInt('skin', defValue: 5);

  ThemeData _theme;
  String font = SpUtil.getString("fontName", defValue: "Roboto");

  ThemeData get theme {
    if (font != "Roboto" && font != "") {
      readFont(font);
    }
    if (SpUtil.haveKey("dark")) {
      dark = SpUtil.getBool("dark");
    }
    var scheme = FlexScheme.values[idx];
    _theme = dark
        ? FlexColorScheme.dark(
            scheme: scheme,
            fontFamily: font,
          ).toTheme
        : FlexColorScheme.light(
            scheme: scheme,
            fontFamily: font,
          ).toTheme;
    return _theme;
  }

  getSkins() {
    List<Widget> wds = [];
    for (var i = 0; i < skins.length; i++) {
      wds.add(GestureDetector(
        child: Stack(
          children: <Widget>[
            Container(
              color: skins[i],
            ),
            i == idx
                ? Align(
                    alignment: Alignment.topRight,
                    child: ImageIcon(
                      AssetImage('images/pick.png'),
                      color: Colors.white,
                    ),
                  )
                : Container()
          ],
        ),
        onTap: () {
          idx = i;
          notifyListeners();
          SpUtil.putInt('skin', idx);
        },
      ));
    }
    return wds;
  }

  switchModel() {
    dark = !dark;

    SpUtil.putBool("dark", dark);

    notifyListeners();
  }

  setFontFamily(name) {
    font = name;
    SpUtil.putString("fontName", font);
    notifyListeners();
  }

  Future<void> readFont(String fontName) async {
    FileInfo file =
        await CustomCacheManager.instanceFont.getFileFromCache(fontName);
    var fontLoader = FontLoader(fontName);
    Uint8List readAsBytes = file.file.readAsBytesSync();

    fontLoader.addFont(Future.value(ByteData.view(readAsBytes.buffer)));
    await fontLoader.load();
  }
//
// Future<ByteData> getCustomFont(String path) async {
//   File file = File(path);
//   var uint8list = await file.readAsBytes();
//
//   ByteData asByteData = uint8list.buffer.asByteData();
//   return Future.value(asByteData);
// }
}
