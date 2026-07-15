import 'dart:convert';

import 'package:book/source/model/book_source.dart';
import 'package:book/source/net/source_http.dart';
import 'package:book/source/util/url_join.dart';

class AnalyzeRequest {
  final String url;
  final String method;
  final Map<String, String> headers;
  final dynamic body;
  final String charset;

  AnalyzeRequest({
    required this.url,
    this.method = 'GET',
    Map<String, String>? headers,
    this.body,
    this.charset = 'utf-8',
  }) : headers = headers ?? {};
}

/// Build request from Legado-style searchUrl / absolute url + source header.
class AnalyzeUrl {
  /// [template] examples:
  /// - `https://x.com/search?q={{key}}&page={{page}}`
  /// - `https://x.com/s,{"method":"POST","body":"key={{key}}"}`
  static AnalyzeRequest build(
    BookSource source,
    String template, {
    String key = '',
    int page = 1,
    Map<String, String>? extraHeaders,
  }) {
    var raw = template.trim();
    var method = 'GET';
    dynamic body;
    Map<String, String> headers = {};

    // Merge source header JSON if present
    headers.addAll(_parseHeader(source.header));
    if (extraHeaders != null) headers.addAll(extraHeaders);

    // Options after comma: url,{json}
    final comma = _findOptionsComma(raw);
    if (comma > 0) {
      final optStr = raw.substring(comma + 1).trim();
      raw = raw.substring(0, comma).trim();
      try {
        final opt = jsonDecode(optStr);
        if (opt is Map) {
          if (opt['method'] != null) {
            method = opt['method'].toString().toUpperCase();
          }
          if (opt['body'] != null) body = opt['body'];
          if (opt['headers'] is Map) {
            (opt['headers'] as Map).forEach((k, v) {
              headers[k.toString()] = v.toString();
            });
          }
          if (opt['charset'] != null) {
            // handled at response decode time via header preference
          }
        }
      } catch (_) {}
    }

    final host = hostOf(source.bookSourceUrl);
    String fill(String s) {
      return s
          .replaceAll('{{key}}', Uri.encodeQueryComponent(key))
          .replaceAll('{{page}}', '$page')
          .replaceAll('{{host}}', host)
          .replaceAll('{{sourceUrl}}', source.bookSourceUrl)
          .replaceAll('{key}', Uri.encodeQueryComponent(key))
          .replaceAll('{page}', '$page')
          .replaceAll('{host}', host);
    }

    raw = fill(raw);
    if (body is String) body = fill(body);

    // Relative path
    if (!raw.startsWith('http://') && !raw.startsWith('https://')) {
      raw = urlJoin(source.bookSourceUrl, raw);
    }

    return AnalyzeRequest(
      url: raw,
      method: method,
      headers: headers,
      body: body,
    );
  }

  static Future<SourceResponse> fetch(
    BookSource source,
    String template, {
    String key = '',
    int page = 1,
    String? absoluteUrl,
  }) async {
    final req = absoluteUrl != null && absoluteUrl.isNotEmpty
        ? AnalyzeRequest(
            url: absoluteUrl,
            headers: _parseHeader(source.header),
          )
        : build(source, template, key: key, page: page);
    return SourceHttp.instance.fetch(req);
  }

  static Map<String, String> _parseHeader(String header) {
    final map = <String, String>{};
    if (header.isEmpty) return map;
    try {
      final obj = jsonDecode(header);
      if (obj is Map) {
        obj.forEach((k, v) => map[k.toString()] = v.toString());
      }
    } catch (_) {
      // plain "Key: Value" lines
      for (final line in header.split(RegExp(r'[\r\n]+'))) {
        final i = line.indexOf(':');
        if (i > 0) {
          map[line.substring(0, i).trim()] = line.substring(i + 1).trim();
        }
      }
    }
    return map;
  }

  static int _findOptionsComma(String raw) {
    // last comma before a `{` options object
    final idx = raw.lastIndexOf(',{');
    return idx;
  }
}

/// Lightweight response holder (avoids tight Dio coupling in analyzers).
class SourceResponse {
  final String url;
  final String body;
  final String contentType;
  final int statusCode;

  SourceResponse({
    required this.url,
    required this.body,
    this.contentType = 'text/html',
    this.statusCode = 200,
  });

  bool get isJson =>
      contentType.contains('json') ||
      body.trimLeft().startsWith('{') ||
      body.trimLeft().startsWith('[');
}
