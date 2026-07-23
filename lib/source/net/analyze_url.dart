import 'dart:convert';

import 'package:book/source/analyzer/js_analyzer.dart';
import 'package:book/source/model/book_source.dart';
import 'package:book/source/net/source_http.dart';
import 'package:book/source/util/url_join.dart';
import 'package:flutter/foundation.dart';

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
    var charset = 'utf-8';
    Map<String, String> headers = {};

    // Merge source header JSON if present
    headers.addAll(_parseHeader(source.header));
    if (extraHeaders != null) headers.addAll(extraHeaders);

    // Legado JS searchUrl / exploreUrl.
    // Two shapes:
    // 1) Real JS that assigns/returns a url string
    // 2) Quirk: `<js>/path,{'method':'POST',...};result='';result;</js>`
    //    (URL template disguised as JS — not valid JS expression)
    if (JsEngine.needsJs(raw)) {
      if (source.jsLib.isNotEmpty) {
        JsEngine.instance.ensureJsLib(source.jsLib);
      }
      var code = JsEngine.extractCode(raw) ?? raw;
      final host = hostOf(source.bookSourceUrl);
      code = code
          .replaceAll('{{key}}', Uri.encodeQueryComponent(key))
          .replaceAll('{{page}}', '$page')
          .replaceAll('{{host}}', host)
          .replaceAll('{key}', Uri.encodeQueryComponent(key))
          .replaceAll('{page}', '$page');

      // Quirk path: `url,{opts};result=…` → use url,{opts} as template.
      final quirk = RegExp(
        r"^([^;]+);\s*result\s*=",
        multiLine: true,
      ).firstMatch(code.trim());
      if (quirk != null) {
        raw = quirk.group(1)!.trim();
      } else {
        final evaluated = JsEngine.instance.eval(
          // Ensure we produce a value: append `; result` if script uses result=
          code.contains('result') ? '$code\n;result' : code,
          result: '',
          baseUrl: source.bookSourceUrl,
          src: '',
          jsLib: source.jsLib,
        );
        raw = evaluated.trim().isEmpty ? raw : evaluated.trim();
        if (raw.contains('<js>') || raw.startsWith('@js:')) {
          raw = JsEngine.extractCode(raw) ?? raw;
        }
      }
    }

    // Options after comma: url,{json}  (JSON may use single quotes).
    final comma = _findOptionsComma(raw);
    if (comma > 0) {
      final optStr = raw.substring(comma + 1).trim();
      raw = raw.substring(0, comma).trim();
      try {
        final opt = jsonDecode(_jsonish(optStr));
        if (opt is Map) {
          if (opt['method'] != null) {
            method = opt['method'].toString().toUpperCase();
          }
          if (opt['body'] != null) body = opt['body'];
          if (opt['charset'] != null) {
            charset = opt['charset'].toString();
          }
          if (opt['headers'] is Map) {
            (opt['headers'] as Map).forEach((k, v) {
              _putHeader(headers, k.toString(), v.toString());
            });
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

    // Relative path from JS template → join against source host.
    if (raw.startsWith('/') && source.bookSourceUrl.isNotEmpty) {
      raw = urlJoin(source.bookSourceUrl, raw);
    }

    // Drop leftover Legado JS snippets (cookie/js helpers we don't evaluate)
    // e.g. `{{cookie.removeCookie(source.getKey())}}http://…`
    raw = sanitizeUrl(raw, base: source.bookSourceUrl);
    if (body is String) {
      // body may also carry {{…}} noise; only strip, don't force URL join.
      body = _stripJsTemplates(body);
    }

    return AnalyzeRequest(
      url: raw,
      method: method,
      headers: headers,
      body: body,
      charset: charset,
    );
  }

  /// Accept single-quoted JS object literals as JSON.
  static String _jsonish(String s) {
    var t = s.trim();
    // `{'method':'POST'}` → `{"method":"POST"}`
    if (t.contains("'")) {
      t = t.replaceAll("'", '"');
    }
    return t;
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
            url: sanitizeUrl(absoluteUrl, base: source.bookSourceUrl),
            headers: _parseHeader(source.header),
          )
        : build(source, template, key: key, page: page);
    return SourceHttp.instance.fetch(req);
  }

  /// Make a Legado-style URL safe for Dio / Uri.parse.
  ///
  /// Strips unevaluated `{{…}}` JS helpers, recovers the first http(s) URL if
  /// one is embedded, and joins relative paths against [base].
  static String sanitizeUrl(String input, {String base = ''}) {
    final original = input.trim();
    var raw = _stripJsTemplates(original);
    if (raw.isEmpty) return raw;

    // Recover `…noise…https://host/path` left after failed JS evaluation.
    if (!_looksAbsolute(raw)) {
      final embedded = _firstHttpUrl(raw);
      if (embedded != null) {
        raw = embedded;
      }
    }

    if (!_looksAbsolute(raw) && base.isNotEmpty) {
      raw = urlJoin(base, raw);
    }
    // Drop control chars / whitespace that break Dio Uri.parse.
    raw = raw.replaceAll(RegExp(r'[\x00-\x1F\x7F]'), '').trim();
    if (kDebugMode && original.contains('{{') && original != raw) {
      debugPrint(
        '[AnalyzeUrl] sanitized "${_clip(original)}" → "${_clip(raw)}"',
      );
    }
    return raw;
  }

  static String _clip(String s, [int n = 120]) =>
      s.length <= n ? s : '${s.substring(0, n)}…';

  /// Remove `{{ … }}` blocks (non-greedy). Known placeholders are filled first.
  static String _stripJsTemplates(String s) {
    if (!s.contains('{{')) return s;
    return s.replaceAll(RegExp(r'\{\{[\s\S]*?\}\}'), '').trim();
  }

  static bool _looksAbsolute(String s) =>
      s.startsWith('http://') || s.startsWith('https://');

  /// First http(s) URL substring, if any.
  static String? _firstHttpUrl(String s) {
    final m = RegExp(r'''https?://[^\s"'<>]+''').firstMatch(s);
    return m?.group(0);
  }

  static Map<String, String> _parseHeader(String header) {
    final map = <String, String>{};
    if (header.isEmpty) return map;
    try {
      final obj = jsonDecode(header);
      if (obj is Map) {
        obj.forEach((k, v) => _putHeader(map, k.toString(), v.toString()));
      }
    } catch (_) {
      // plain "Key: Value" lines
      for (final line in header.split(RegExp(r'[\r\n]+'))) {
        final i = line.indexOf(':');
        if (i > 0) {
          _putHeader(
            map,
            line.substring(0, i).trim(),
            line.substring(i + 1).trim(),
          );
        }
      }
    }
    return map;
  }

  /// Keep only valid HTTP header field names.
  ///
  /// Legado sources often put `@js` / `@Header:` style keys in `header` JSON;
  /// Dio rejects those names (`FormatException: Invalid HTTP header field name`).
  static void _putHeader(Map<String, String> map, String key, String value) {
    final k = key.trim();
    if (k.isEmpty) return;
    // Skip Legado rule markers and other non-token names.
    if (k.startsWith('@')) return;
    if (!_isValidHeaderName(k)) return;
    map[k] = value;
  }

  /// RFC 7230 token: tchar = "!" / "#" / "$" / "%" / "&" / "'" / "*" /
  ///   "+" / "-" / "." / "^" / "_" / "`" / "|" / "~" / DIGIT / ALPHA
  static bool _isValidHeaderName(String name) {
    if (name.isEmpty) return false;
    for (var i = 0; i < name.length; i++) {
      final c = name.codeUnitAt(i);
      final ok = (c >= 0x30 && c <= 0x39) || // 0-9
          (c >= 0x41 && c <= 0x5a) || // A-Z
          (c >= 0x61 && c <= 0x7a) || // a-z
          c == 0x21 || // !
          c == 0x23 || // #
          c == 0x24 || // $
          c == 0x25 || // %
          c == 0x26 || // &
          c == 0x27 || // '
          c == 0x2a || // *
          c == 0x2b || // +
          c == 0x2d || // -
          c == 0x2e || // .
          c == 0x5e || // ^
          c == 0x5f || // _
          c == 0x60 || // `
          c == 0x7c || // |
          c == 0x7e; // ~
      if (!ok) return false;
    }
    return true;
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
