import 'dart:convert';

import 'package:book/source/net/analyze_url.dart';
import 'package:dio/dio.dart';
import 'package:fast_gbk/fast_gbk.dart';

/// Shared Dio client for book-source fetches (independent of official API).
class SourceHttp {
  SourceHttp._() {
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(seconds: 12),
      responseType: ResponseType.bytes,
      validateStatus: (c) => c != null && c < 500,
      headers: {
        'User-Agent':
            'Mozilla/5.0 (Linux; Android 13) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36',
        'Accept':
            'text/html,application/xhtml+xml,application/xml;q=0.9,application/json,*/*;q=0.8',
        'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
      },
    ));
  }

  static final SourceHttp instance = SourceHttp._();
  late final Dio _dio;

  Future<SourceResponse> fetch(AnalyzeRequest req) async {
    final options = Options(
      method: req.method,
      headers: req.headers,
      contentType:
          req.method == 'POST' ? Headers.formUrlEncodedContentType : null,
    );
    final response = await _dio.request<List<int>>(
      req.url,
      data: req.body,
      options: options,
    );
    final bytes = response.data ?? <int>[];
    final ctype =
        response.headers.value(Headers.contentTypeHeader)?.toLowerCase() ?? '';
    // Prefer explicit request charset, then header, then meta/html sniff, then utf-8.
    var charset = req.charset.toLowerCase();
    if (charset.isEmpty || charset == 'utf-8') {
      charset = _charsetFrom(ctype, '');
    }
    if (charset.isEmpty) {
      charset = _sniffCharset(bytes) ?? 'utf-8';
    }
    final body = _decode(bytes, charset);
    return SourceResponse(
      url: response.realUri.toString(),
      body: body,
      contentType: ctype,
      statusCode: response.statusCode ?? 0,
    );
  }

  String _charsetFrom(String contentType, String fallback) {
    final m = RegExp(r'charset=([^\s;]+)', caseSensitive: false)
        .firstMatch(contentType);
    if (m != null) return m.group(1)!.replaceAll('"', '').toLowerCase();
    return fallback.toLowerCase();
  }

  /// Peek at the first ~2KB as latin1 to find <meta charset=...>
  String? _sniffCharset(List<int> bytes) {
    if (bytes.isEmpty) return null;
    final head = latin1.decode(
      bytes.take(bytes.length > 2048 ? 2048 : bytes.length).toList(),
      allowInvalid: true,
    );
    final m1 = RegExp(
      r'charset\s*=\s*["' "'" r']?([a-zA-Z0-9_\-]+)',
      caseSensitive: false,
    ).firstMatch(head);
    if (m1 != null) return m1.group(1)!.toLowerCase();
    final m2 = RegExp(
      r'encoding\s*=\s*["' "'" r']?([a-zA-Z0-9_\-]+)',
      caseSensitive: false,
    ).firstMatch(head);
    if (m2 != null) return m2.group(1)!.toLowerCase();
    return null;
  }

  String _decode(List<int> bytes, String charset) {
    final c = charset.toLowerCase().replaceAll('_', '-');
    try {
      if (c.contains('gb2312') ||
          c.contains('gbk') ||
          c.contains('gb18030') ||
          c == 'gb2312' ||
          c == 'gbk') {
        try {
          return gbk.decode(bytes);
        } catch (_) {
          // fall through
        }
      }
      if (c.contains('big5')) {
        // no dedicated codec; try gbk as best-effort then utf8
        try {
          return gbk.decode(bytes);
        } catch (_) {}
      }
      if (c.contains('latin') || c.contains('iso-8859-1') || c == 'ascii') {
        return latin1.decode(bytes, allowInvalid: true);
      }
      return utf8.decode(bytes, allowMalformed: true);
    } catch (_) {
      // Last resort: try gbk then utf8
      try {
        return gbk.decode(bytes);
      } catch (_) {
        try {
          return utf8.decode(bytes, allowMalformed: true);
        } catch (_) {
          return latin1.decode(bytes, allowInvalid: true);
        }
      }
    }
  }
}
