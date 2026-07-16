import 'dart:typed_data';

import 'package:book/common/app_colors.dart';
import 'package:book/common/common.dart';
import 'package:book/common/local_store.dart';
import 'package:book/service/CustomCacheManager.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class ColorModel with ChangeNotifier {
  BuildContext? buildContext;
  bool dark = false;
  Map _fonts = {};

  /// When true, use WeChat-neutral theme (product default).
  /// Skin grid still available; picking a swatch sets this false.
  bool useWeReadSkin = SpUtil.getBool('use_weread_skin', defValue: true);

  Map fonts() {
    if (_fonts.isEmpty) {
      _fonts["Roboto"] = "默认字体";
      SpUtil.getObj(Common.fonts, (v) {
        v.entries.forEach((element) {
          _fonts[element.key] = element.value;
        });
      });
    }
    return _fonts;
  }

  List<Color> skins = FlexScheme.values
      .map((e) => FlexColorScheme.light(
            scheme: e,
          ).toTheme.primaryColor)
      .toList();
  String savePath = "";
  int idx = SpUtil.getInt('skin', defValue: 5);

  ThemeData? _theme;
  String font = SpUtil.getString("fontName", defValue: "Roboto");

  ThemeData get theme {
    if (font != "Roboto" && font != "") {
      readFont(font);
    }
    if (SpUtil.haveKey("dark")) {
      dark = SpUtil.getBool("dark");
    }
    useWeReadSkin = SpUtil.getBool('use_weread_skin', defValue: true);

    if (useWeReadSkin) {
      _theme = buildWeReadTheme(
        dark: dark,
        fontFamily: font == "Roboto" || font.isEmpty ? null : font,
      );
    } else {
      final scheme = FlexScheme.values[idx.clamp(0, FlexScheme.values.length - 1)];
      _theme = dark
          ? FlexColorScheme.dark(
              scheme: scheme,
              fontFamily: font,
            ).toTheme
          : FlexColorScheme.light(
              scheme: scheme,
              fontFamily: font,
            ).toTheme;
    }
    return _theme!;
  }

  getSkins() {
    List<Widget> wds = [];
    // First tile: WeChat default
    wds.add(GestureDetector(
      onTap: () {
        useWeReadSkin = true;
        SpUtil.putBool('use_weread_skin', true);
        notifyListeners();
      },
      child: Stack(
        children: [
          Container(color: AppColors.brand),
          if (useWeReadSkin)
            const Align(
              alignment: Alignment.topRight,
              child: ImageIcon(
                AssetImage('images/pick.png'),
                color: Colors.white,
              ),
            ),
          const Align(
            alignment: Alignment.bottomLeft,
            child: Padding(
              padding: EdgeInsets.all(4),
              child: Text(
                '默认',
                style: TextStyle(color: Colors.white, fontSize: 11),
              ),
            ),
          ),
        ],
      ),
    ));

    for (var i = 0; i < skins.length; i++) {
      wds.add(GestureDetector(
        child: Stack(
          children: <Widget>[
            Container(
              color: skins[i],
            ),
            (!useWeReadSkin && i == idx)
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
          useWeReadSkin = false;
          SpUtil.putBool('use_weread_skin', false);
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
    FileInfo? file =
        await CustomCacheManager.instanceFont.getFileFromCache(fontName);
    if (file == null) return;
    var fontLoader = FontLoader(fontName);
    Uint8List readAsBytes = file.file.readAsBytesSync();

    fontLoader.addFont(Future.value(ByteData.view(readAsBytes.buffer)));
    await fontLoader.load();
  }
}
