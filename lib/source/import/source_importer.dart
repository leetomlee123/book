import 'dart:convert';

import 'package:book/source/model/book_source.dart';
import 'package:dio/dio.dart';

class SourceImporter {
  /// Parse Legado JSON (object, array, or nested under `data`).
  static List<BookSource> parseJson(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return const [];
    dynamic root;
    try {
      root = jsonDecode(trimmed);
    } catch (_) {
      throw FormatException('书源 JSON 解析失败');
    }
    final list = <Map<String, dynamic>>[];
    if (root is List) {
      for (final e in root) {
        if (e is Map) list.add(Map<String, dynamic>.from(e));
      }
    } else if (root is Map) {
      if (root['data'] is List) {
        for (final e in root['data']) {
          if (e is Map) list.add(Map<String, dynamic>.from(e));
        }
      } else if (root['bookSourceUrl'] != null || root['bookSourceName'] != null) {
        list.add(Map<String, dynamic>.from(root));
      } else {
        // map of sources
        root.forEach((_, v) {
          if (v is Map && v['bookSourceUrl'] != null) {
            list.add(Map<String, dynamic>.from(v));
          }
        });
      }
    }
    final out = <BookSource>[];
    for (final m in list) {
      final s = BookSource.fromLegadoJson(m);
      if (s.bookSourceUrl.isEmpty && s.bookSourceName.isEmpty) continue;
      if (s.bookSourceUrl.isEmpty) {
        s.bookSourceUrl = 'local://${s.bookSourceName.hashCode}';
      }
      s.rawJson = jsonEncode(m);
      out.add(s);
    }
    return out;
  }

  static Future<List<BookSource>> fromUrl(String url) async {
    final dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      responseType: ResponseType.plain,
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
