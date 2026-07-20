import 'dart:io';

import 'package:book/common/app_log.dart';
import 'package:book/common/local_store.dart';
import 'package:book/common/read_setting.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Copies the bundled CJK TTF into app support so Rust book_pager can
/// `load_font_file` the **same** bytes Flutter paints with.
///
/// Safe to call multiple times; no-ops when the asset is missing (Dart
/// fallback still works with the platform font).
class ReaderFontBootstrap {
  ReaderFontBootstrap._();

  static bool _done = false;

  static Future<void> ensure() async {
    if (_done) return;
    _done = true;
    try {
      final dir = await getApplicationSupportDirectory();
      final fontsDir = Directory(p.join(dir.path, 'fonts'));
      if (!fontsDir.existsSync()) {
        fontsDir.createSync(recursive: true);
      }
      // File name must match the asset basename so cache paths stay stable.
      final outPath =
          p.join(fontsDir.path, p.basename(ReadSetting.defaultFontAsset));
      final outFile = File(outPath);

      // Re-extract if missing or suspiciously small (corrupt / partial write).
      if (!outFile.existsSync() || outFile.lengthSync() < 1024 * 100) {
        try {
          final data = await rootBundle.load(ReadSetting.defaultFontAsset);
          final bytes = data.buffer.asUint8List(
            data.offsetInBytes,
            data.lengthInBytes,
          );
          await outFile.writeAsBytes(bytes, flush: true);
          AppLog.i(
            'Font',
            'extracted bundled font (${bytes.length} bytes) → $outPath',
          );
        } catch (e) {
          // Asset not packaged — Rust will require font_path and fall back.
          AppLog.w(
            'Font',
            'bundled font asset missing (${ReadSetting.defaultFontAsset}); '
            'Rust pager needs a custom font path or Dart fallback',
            error: e,
          );
          return;
        }
      }

      if (outFile.existsSync() && outFile.lengthSync() > 1024 * 100) {
        ReadSetting.setBundledFontPath(outPath);
        // Only seed default family when user has never chosen one.
        final stored = SpUtil.getString(ReadSetting.fontNameKey, defValue: '');
        if (stored.isEmpty) {
          ReadSetting.setFontFamily(ReadSetting.defaultFontFamily);
        }
        // If current selection is the bundled face (or legacy Noto default name
        // with no custom path), keep SpUtil path pointing at extracted file.
        final family = ReadSetting.getFontFamily();
        final custom = SpUtil.getString(ReadSetting.fontPathKey, defValue: '');
        if (custom.isEmpty &&
            (family == ReadSetting.defaultFontFamily ||
                family == 'NotoSansSC')) {
          if (family == 'NotoSansSC') {
            ReadSetting.setFontFamily(ReadSetting.defaultFontFamily);
          }
          ReadSetting.setFontPath(outPath);
        }
        AppLog.i('Font', 'bundled font ready path=$outPath family=$family');
      }
    } catch (e, st) {
      AppLog.w('Font', 'bootstrap failed', error: e);
      assert(() {
        // ignore: avoid_print
        print('ReaderFontBootstrap failed: $e\n$st');
        return true;
      }());
    }
  }
}
