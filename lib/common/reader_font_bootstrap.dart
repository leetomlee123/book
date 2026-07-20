import 'dart:io';

import 'package:book/common/app_log.dart';
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
      final outPath = p.join(fontsDir.path, 'NotoSansSC-Regular.ttf');
      final outFile = File(outPath);

      if (!outFile.existsSync() || outFile.lengthSync() < 1024) {
        try {
          final data =
              await rootBundle.load(ReadSetting.defaultFontAsset);
          final bytes = data.buffer.asUint8List(
            data.offsetInBytes,
            data.lengthInBytes,
          );
          await outFile.writeAsBytes(bytes, flush: true);
          AppLog.i('Font', 'extracted bundled font → $outPath');
        } catch (e) {
          // Asset not packaged yet — Rust will require font_path and fall back.
          AppLog.w(
            'Font',
            'bundled font asset missing (${ReadSetting.defaultFontAsset}); '
            'Rust pager needs a custom font path or Dart fallback',
            error: e,
          );
          return;
        }
      }

      if (outFile.existsSync() && outFile.lengthSync() > 1024) {
        ReadSetting.setBundledFontPath(outPath);
        // Default family to bundled face when user never chose one.
        final fam = ReadSetting.getFontFamily();
        if (fam.isEmpty || fam == 'Roboto') {
          ReadSetting.setFontFamily(ReadSetting.defaultFontFamily);
        }
        AppLog.i('Font', 'bundled font ready path=$outPath');
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
