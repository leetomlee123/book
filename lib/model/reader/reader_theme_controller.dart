import 'dart:ui' as ui;

import 'package:book/common/common.dart';
import 'package:book/common/local_store.dart';
import 'package:book/common/read_setting.dart';
import 'package:book/common/screen.dart';
import 'package:flutter/services.dart';

/// Reader paper/texture theme: prefs, asset decode, and paint invalidation.
class ReaderThemeController {
  ReaderThemeController({
    required this.setBgUI,
    required this.clearPictures,
    required this.markNeedsPaint,
    required this.notify,
  });

  final void Function(ui.Image? image) setBgUI;
  final void Function() clearPictures;
  final void Function() markNeedsPaint;
  final void Function() notify;

  /// Legacy texture filename (when not using solid paper).
  String backgroundImageName =
      SpUtil.getString(PrefsKeys.bgIdx, defValue: ReadSetting.bgImg.first);

  PaperTheme paperTheme = ReadSetting.getPaperTheme();

  /// Refresh [paperTheme] from prefs (call before paint so menu changes apply).
  void syncPaperTheme() {
    paperTheme = ReadSetting.getPaperTheme();
  }

  Future<void> refreshPaint() async {
    await reloadBackgroundImage();
    clearPictures();
    markNeedsPaint();
  }

  Future<void> setBackgroundImage(Object? i) async {
    // Legacy texture path.
    final path = i?.toString() ?? backgroundImageName;
    backgroundImageName = path;
    SpUtil.putString(PrefsKeys.bgIdx, path);
    ReadSetting.setUseSolidPaper(false);
    await refreshPaint();
    notify();
  }

  /// WeChat-style solid paper swatch.
  Future<void> setPaperTheme(PaperTheme theme) async {
    paperTheme = theme;
    ReadSetting.setPaperTheme(theme);
    ReadSetting.setUseSolidPaper(true);
    clearPictures();
    setBgUI(null); // solid fill only
    await refreshPaint();
    notify();
  }

  Future<ui.Image> loadAssetImage(
    String asset, {
    int? width,
    int? height,
  }) async {
    final data = await rootBundle.load(asset);
    final codec = await ui.instantiateImageCodec(
      data.buffer.asUint8List(),
      targetWidth: width,
      targetHeight: height,
    );
    final fi = await codec.getNextFrame();
    return fi.image;
  }

  Future<void> reloadBackgroundImage() async {
    paperTheme = ReadSetting.getPaperTheme();
    // Solid paper mode: no texture image.
    if (ReadSetting.useSolidPaper()) {
      setBgUI(null);
      return;
    }
    if (SpUtil.getBool(PrefsKeys.dark) || paperTheme == PaperTheme.night) {
      setBgUI(await loadAssetImage(
        "images/${ReadSetting.bgImg.last}",
        width: Screen.width.ceil(),
        height: Screen.height.ceil(),
      ));
    } else {
      setBgUI(await loadAssetImage(
        "images/$backgroundImageName",
        width: Screen.width.ceil(),
        height: Screen.height.ceil(),
      ));
    }
  }
}
