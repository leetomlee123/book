import 'dart:io';

import 'package:book/common/common.dart';
import 'package:book/common/local_store.dart';
import 'package:book/service/CustomCacheManager.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Built-in + downloaded + locally imported font catalog for the reader.
///
/// - Built-in: name → CDN URL (empty = system default).
/// - Downloaded CDN fonts: persisted under app support/fonts/ with path map.
/// - Local imports: name (`local:…`) → absolute path under app support/fonts/.
class FontCatalog {
  FontCatalog._();

  static const String localPrefix = 'local:';
  static const String fontPathKey = 'fontPath';
  static const String localFontsKey = 'local_fonts';
  /// name → absolute path for CDN fonts that finished downloading.
  static const String downloadedFontsKey = 'downloaded_fonts';

  /// Free/open Chinese fonts (CDN). Roboto is always the system default.
  static const Map<String, String> builtIn = {
    'Roboto': '',
    'NotoSansSC':
        'https://cdn.jsdelivr.net/gh/googlefonts/noto-cjk@main/Sans/SubsetOTF/SC/NotoSansSC-Regular.otf',
    'NotoSerifSC':
        'https://cdn.jsdelivr.net/gh/googlefonts/noto-cjk@main/Serif/SubsetOTF/SC/NotoSerifSC-Regular.otf',
    'LXGWWenKai':
        'https://github.com/lxgw/LxgwWenKai/releases/download/v1.501/LXGWWenKai-Regular.ttf',
  };

  static const Map<String, String> displayNames = {
    'Roboto': '系统默认',
    'NotoSansSC': '思源黑体',
    'NotoSerifSC': '思源宋体',
    'LXGWWenKai': '霞鹜文楷',
  };

  static Map<String, String> _readMap(String key) {
    final out = <String, String>{};
    SpUtil.getObj(key, (v) {
      v.forEach((k, val) {
        out[k.toString()] = val?.toString() ?? '';
      });
      return null;
    });
    return out;
  }

  static Future<Directory> _fontsDir() async {
    final support = await getApplicationSupportDirectory();
    final dir = Directory(p.join(support.path, 'fonts'));
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  /// Merge built-in + SpUtil catalog + local imports (name → url/path).
  static Map<String, String> all() {
    final out = <String, String>{...builtIn};
    // SpUtil remote config may add extra names; built-in URLs win for known keys
    // so a stale empty/bad URL cannot hide a downloadable font.
    final remote = _readMap(Common.fonts);
    remote.forEach((k, v) {
      if (!out.containsKey(k)) out[k] = v;
    });
    out.addAll(_readMap(localFontsKey));
    return out;
  }

  /// Ensure SpUtil has at least the built-in list (merge, don't wipe user fonts).
  static void ensureSeeded() {
    final existing = _readMap(Common.fonts);
    var changed = false;
    for (final e in builtIn.entries) {
      // Always refresh known built-in URLs so old empty values don't stick.
      if (existing[e.key] != e.value) {
        existing[e.key] = e.value;
        changed = true;
      }
    }
    if (changed || !SpUtil.haveKey(Common.fonts)) {
      SpUtil.putObject(Common.fonts, existing);
    }
  }

  static String displayName(String key) {
    if (displayNames.containsKey(key)) return displayNames[key]!;
    if (key.startsWith(localPrefix)) {
      return key.substring(localPrefix.length);
    }
    return key;
  }

  static String downloadUrl(String fontName) {
    final allMap = all();
    final v = allMap[fontName];
    if (v != null && v.isNotEmpty && !fontName.startsWith(localPrefix)) {
      // Local fonts store a path here; CDN entries store http(s) URL.
      if (v.startsWith('http://') || v.startsWith('https://')) return v;
    }
    return builtIn[fontName] ?? '';
  }

  /// Whether the face file is available on disk (no re-download needed).
  static Future<bool> isReady(String fontName) async {
    if (fontName.isEmpty || fontName == 'Roboto') return true;
    final path = await resolvePath(fontName);
    return path.isNotEmpty;
  }

  /// Resolve absolute path for [fontName] (local / persisted download / cache).
  static Future<String> resolvePath(String fontName) async {
    if (fontName.isEmpty || fontName == 'Roboto') return '';

    // 1) Local import
    final localMap = _readMap(localFontsKey);
    final localPath = localMap[fontName];
    if (localPath != null &&
        localPath.isNotEmpty &&
        await File(localPath).exists()) {
      return localPath;
    }

    // 2) Persisted CDN download (stable path we own)
    final dlMap = _readMap(downloadedFontsKey);
    final dlPath = dlMap[fontName];
    if (dlPath != null && dlPath.isNotEmpty && await File(dlPath).exists()) {
      return dlPath;
    }

    // 3) Stable file under fonts dir even if map was wiped
    try {
      final dir = await _fontsDir();
      for (final ext in const ['.otf', '.ttf', '.ttc', '.otc', '']) {
        final candidate = File(p.join(dir.path, '$fontName$ext'));
        if (await candidate.exists() && await candidate.length() > 0) {
          // Heal the registry so next lookup is O(1).
          final map = _readMap(downloadedFontsKey);
          map[fontName] = candidate.path;
          SpUtil.putObject(downloadedFontsKey, map);
          return candidate.path;
        }
      }
    } catch (_) {}

    // 4) flutter_cache_manager (legacy / mid-download)
    try {
      final info =
          await CustomCacheManager.instanceFont.getFileFromCache(fontName);
      if (info != null && await info.file.exists()) {
        // Promote into our durable store.
        return await persistDownloaded(fontName, info.file);
      }
    } catch (_) {}
    try {
      final url = downloadUrl(fontName);
      if (url.isNotEmpty) {
        final info =
            await CustomCacheManager.instanceFont.getFileFromCache(url);
        if (info != null && await info.file.exists()) {
          return await persistDownloaded(fontName, info.file);
        }
      }
    } catch (_) {}

    // 5) Currently selected font path in SpUtil
    final saved = SpUtil.getString(fontPathKey, defValue: '');
    if (saved.isNotEmpty &&
        SpUtil.getString('fontName', defValue: 'Roboto') == fontName &&
        await File(saved).exists()) {
      return saved;
    }
    return '';
  }

  /// Copy a just-downloaded cache file into app support/fonts and register it.
  static Future<String> persistDownloaded(String fontName, File source) async {
    if (fontName.isEmpty || fontName == 'Roboto') return '';
    if (!await source.exists()) return '';

    final dir = await _fontsDir();
    var ext = p.extension(source.path).toLowerCase();
    if (ext.isEmpty ||
        !const {'.ttf', '.otf', '.ttc', '.otc'}.contains(ext)) {
      // Guess from URL / built-in.
      final url = downloadUrl(fontName);
      ext = p.extension(url).toLowerCase();
      if (ext.isEmpty) ext = '.ttf';
    }
    final dest = File(p.join(dir.path, '$fontName$ext'));
    if (source.path != dest.path) {
      await source.copy(dest.path);
    }
    final map = _readMap(downloadedFontsKey);
    map[fontName] = dest.path;
    SpUtil.putObject(downloadedFontsKey, map);
    return dest.path;
  }

  /// Copy [sourceFile] into app support/fonts and register as local font.
  static Future<String> importLocalFile(File sourceFile, {String? name}) async {
    final dir = await _fontsDir();

    final base = name?.trim().isNotEmpty == true
        ? name!.trim()
        : p.basenameWithoutExtension(sourceFile.path);
    final key = '$localPrefix$base';
    final ext = p.extension(sourceFile.path);
    final dest = File(p.join(dir.path, 'local_$base$ext'));
    await sourceFile.copy(dest.path);

    final map = _readMap(localFontsKey);
    map[key] = dest.path;
    SpUtil.putObject(localFontsKey, map);
    return key;
  }

  /// Remove a previously imported local font and its file.
  static Future<void> removeLocal(String fontName) async {
    if (!fontName.startsWith(localPrefix)) return;
    final map = _readMap(localFontsKey);
    final path = map.remove(fontName);
    SpUtil.putObject(localFontsKey, map);
    if (path != null && path.isNotEmpty) {
      try {
        final f = File(path);
        if (await f.exists()) await f.delete();
      } catch (_) {}
    }
  }
}
