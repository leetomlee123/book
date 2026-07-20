import 'dart:convert';

import 'package:book/source/model/book_source.dart';
import 'package:dio/dio.dart';

/// Result of parsing a Legado book-source JSON payload.
class SourceParseResult {
  final List<BookSource> sources;
  final int skipped;
  final int duplicatesInBatch;

  const SourceParseResult({
    required this.sources,
    this.skipped = 0,
    this.duplicatesInBatch = 0,
  });

  int get count => sources.length;
}

/// Result of upserting sources into the local DB.
class SourceUpsertStats {
  final int inserted;
  final int updated;

  const SourceUpsertStats({required this.inserted, required this.updated});

  int get total => inserted + updated;
}

class SourceImporter {
  /// Stable non-cryptographic hash for local:// ids (avoids Dart hashCode collisions).
  static int stableHash(String input) {
    // FNV-1a 32-bit
    var hash = 0x811c9dc5;
    for (final unit in input.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash;
  }

  /// Parse Legado JSON (object, array, or nested under `data`).
  ///
  /// Same-batch duplicates (identical [BookSource.bookSourceUrl]) collapse to
  /// the last occurrence so the subsequent DB replace matches the toast count.
  static SourceParseResult parseJson(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) {
      return const SourceParseResult(sources: []);
    }
    dynamic root;
    try {
      root = jsonDecode(trimmed);
    } catch (_) {
      throw FormatException('书源 JSON 解析失败');
    }
    final list = <Map<String, dynamic>>[];
    var skipped = 0;
    if (root is List) {
      for (final e in root) {
        if (e is Map) {
          list.add(Map<String, dynamic>.from(e));
        } else {
          skipped++;
        }
      }
    } else if (root is Map) {
      if (root['data'] is List) {
        for (final e in root['data']) {
          if (e is Map) {
            list.add(Map<String, dynamic>.from(e));
          } else {
            skipped++;
          }
        }
      } else if (root['bookSourceUrl'] != null ||
          root['bookSourceName'] != null) {
        list.add(Map<String, dynamic>.from(root));
      } else {
        // map of sources
        root.forEach((_, v) {
          if (v is Map && v['bookSourceUrl'] != null) {
            list.add(Map<String, dynamic>.from(v));
          } else {
            skipped++;
          }
        });
      }
    } else {
      skipped++;
    }

    final byUrl = <String, BookSource>{};
    var duplicates = 0;
    for (final m in list) {
      final s = BookSource.fromLegadoJson(m);
      if (s.bookSourceUrl.isEmpty && s.bookSourceName.isEmpty) {
        skipped++;
        continue;
      }
      if (s.bookSourceUrl.isEmpty) {
        final raw = jsonEncode(m);
        final name = s.bookSourceName.isEmpty ? 'unnamed' : s.bookSourceName;
        s.bookSourceUrl = 'local://${name}_${stableHash(raw).toRadixString(16)}';
      }
      s.rawJson = jsonEncode(m);
      if (byUrl.containsKey(s.bookSourceUrl)) {
        duplicates++;
      }
      byUrl[s.bookSourceUrl] = s;
    }
    return SourceParseResult(
      sources: byUrl.values.toList(),
      skipped: skipped,
      duplicatesInBatch: duplicates,
    );
  }

  static Future<SourceParseResult> fromUrl(
    String url, {
    Duration receiveTimeout = const Duration(seconds: 60),
  }) async {
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: receiveTimeout,
      responseType: ResponseType.plain,
      headers: {
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 '
            '(KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
        'Accept': 'application/json,text/plain,*/*',
      },
    ));
    final res = await dio.get<String>(url);
    return parseJson(res.data ?? '');
  }

  static String exportJson(List<BookSource> sources) {
    final list = sources.map((s) {
      if (s.rawJson.isNotEmpty) {
        try {
          return jsonDecode(s.rawJson);
        } catch (_) {}
      }
      return s.toLegadoJson();
    }).toList();
    return const JsonEncoder.withIndent('  ').convert(list);
  }
}
