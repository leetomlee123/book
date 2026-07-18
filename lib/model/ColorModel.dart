import 'dart:io';

import 'package:book/common/ReadSetting.dart';
import 'package:book/common/app_colors.dart';
import 'package:book/common/font_catalog.dart';
import 'package:book/common/local_store.dart';
import 'package:book/service/CustomCacheManager.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class ColorModel with ChangeNotifier {
  BuildContext? buildContext;
  bool dark = false;
  Map _fonts = {};

  /// When true, use WeChat-neutral theme (product default).
  bool useWeReadSkin = SpUtil.getBool('use_weread_skin', defValue: true);

  /// Families already registered with [FontLoader] this process.
  final Set<String> _loadedFamilies = {'Roboto', ''};

  Map fonts() {
    FontCatalog.ensureSeeded();
    if (_fonts.isEmpty) {
      _fonts.addAll(FontCatalog.all());
    }
    return _fonts;
  }

  void reloadFontMap() {
    _fonts = {};
    fonts();
    notifyListeners();
  }

  List<Color> skins = FlexScheme.values
      .map((e) => FlexColorScheme.light(scheme: e).toTheme.primaryColor)
      .toList();
  String savePath = "";
  int idx = SpUtil.getInt('skin', defValue: 5);

  ThemeData? _theme;
  String font = SpUtil.getString(ReadSetting.fontNameKey, defValue: "Roboto");

  ThemeData get theme {
    if (SpUtil.haveKey("dark")) {
      dark = SpUtil.getBool("dark");
    }
    useWeReadSkin = SpUtil.getBool('use_weread_skin', defValue: true);
    font = ReadSetting.getFontFamily();
    final family = font == "Roboto" || font.isEmpty ? null : font;

    if (useWeReadSkin) {
      _theme = buildWeReadTheme(dark: dark, fontFamily: family);
    } else {
      final scheme =
          FlexScheme.values[idx.clamp(0, FlexScheme.values.length - 1)];
      _theme = dark
          ? FlexColorScheme.dark(scheme: scheme, fontFamily: family).toTheme
          : FlexColorScheme.light(scheme: scheme, fontFamily: family).toTheme;
    }
    return _theme!;
  }

  List<Widget> getSkins() {
    final wds = <Widget>[];
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
        onTap: () {
          idx = i;
          useWeReadSkin = false;
          SpUtil.putBool('use_weread_skin', false);
          notifyListeners();
          SpUtil.putInt('skin', idx);
        },
        child: Stack(
          children: <Widget>[
            Container(color: skins[i]),
            if (!useWeReadSkin && i == idx)
              const Align(
                alignment: Alignment.topRight,
                child: ImageIcon(
                  AssetImage('images/pick.png'),
                  color: Colors.white,
                ),
              ),
          ],
        ),
      ));
    }
    return wds;
  }

  void switchModel() {
    dark = !dark;
    SpUtil.putBool("dark", dark);
    notifyListeners();
  }

  /// Apply font: register with Flutter, resolve path for Rust, persist.
  /// Returns false if a custom face could not be loaded (caller may toast).
  Future<bool> setFontFamily(String name) async {
    final n = name.isEmpty ? 'Roboto' : name;
    final ok = await ensureFontLoaded(n);
    if (!ok) return false;
    final path = await FontCatalog.resolvePath(n);
    font = n;
    ReadSetting.setFontFamily(n);
    ReadSetting.setFontPath(path);
    notifyListeners();
    return true;
  }

  bool isFontLoaded(String fontName) =>
      fontName.isEmpty ||
      fontName == 'Roboto' ||
      _loadedFamilies.contains(fontName);

  /// Ensure [fontName] is registered with Flutter's [FontLoader].
  Future<bool> ensureFontLoaded(String fontName) async {
    if (fontName.isEmpty || fontName == 'Roboto') return true;
    if (_loadedFamilies.contains(fontName)) return true;

    var path = await FontCatalog.resolvePath(fontName);
    if (path.isEmpty) {
      try {
        final info =
            await CustomCacheManager.instanceFont.getFileFromCache(fontName);
        if (info != null) path = info.file.path;
      } catch (_) {}
    }
    if (path.isEmpty || !await File(path).exists()) return false;

    try {
      final bytes = await File(path).readAsBytes();
      if (bytes.isEmpty) return false;
      // Prefer sublistView so offset/length of the Uint8List are respected.
      final data = ByteData.sublistView(bytes);
      final loader = FontLoader(fontName);
      loader.addFont(Future.value(data));
      await loader.load();
      _loadedFamilies.add(fontName);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Cold-start: load current reader font if custom.
  Future<void> ensureCurrentFontLoaded() async {
    final name = ReadSetting.getFontFamily();
    await ensureFontLoaded(name);
    if (ReadSetting.getFontPath().isEmpty && name != 'Roboto' && name.isNotEmpty) {
      final path = await FontCatalog.resolvePath(name);
      if (path.isNotEmpty) ReadSetting.setFontPath(path);
    }
    // Theme/body may have painted with fallback before FontLoader finished.
    if (name != 'Roboto' && name.isNotEmpty) {
      notifyListeners();
    }
  }
}
