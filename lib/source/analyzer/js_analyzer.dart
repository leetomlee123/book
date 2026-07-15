import 'dart:convert';

import 'package:flutter_js/flutter_js.dart';

/// Minimal Legado-style JS host for book-source rules.
///
/// Supported inputs:
/// - rule starts with `@js:`
/// - rule / content contains `<js>...</js>`
///
/// Injected bindings (subset of Legado):
/// - `result`  previous stage text / current content
/// - `baseUrl` page url
/// - `src`     full page body (alias of result when not chained)
/// - `java`    tiny helper object: `ajax` not implemented; `getString`/`get` passthrough
///
/// Returns string, or JSON-encoded list/map when JS returns array/object.
class JsEngine {
  JsEngine._();
  static final JsEngine instance = JsEngine._();

  JavascriptRuntime? _rt;
  bool _failed = false;

  JavascriptRuntime? get _runtime {
    if (_failed) return null;
    if (_rt != null) return _rt;
    try {
      _rt = getJavascriptRuntime(forceJavascriptCoreOnAndroid: false);
      // Lightweight polyfills commonly expected by source snippets.
      _rt!.evaluate('''
var java = {
  getString: function(x){ return String(x==null?'':x); },
  ajax: function(){ return ''; }
};
''');
      return _rt;
    } catch (_) {
      _failed = true;
      return null;
    }
  }

  /// True if [rule] looks like it needs JS evaluation.
  static bool needsJs(String rule) {
    final r = rule.trim();
    if (r.isEmpty) return false;
    return r.startsWith('@js:') ||
        r.contains('<js>') ||
        r.contains('@js:');
  }

  /// Extract pure JS code from a Legado rule fragment.
  static String? extractCode(String rule) {
    final r = rule.trim();
    if (r.isEmpty) return null;
    if (r.startsWith('@js:')) {
      return r.substring(4).trim();
    }
    final m = RegExp(r'<js>([\s\S]*?)</js>', caseSensitive: false).firstMatch(r);
    if (m != null) return (m.group(1) ?? '').trim();
    // inline @js: mid-string
    final idx = r.indexOf('@js:');
    if (idx >= 0) return r.substring(idx + 4).trim();
    return null;
  }

  /// Evaluate [code] with bindings. Returns stringified result (JSON for list/map).
  String eval(
    String code, {
    String result = '',
    String baseUrl = '',
    String src = '',
  }) {
    final rt = _runtime;
    if (rt == null || code.isEmpty) return result;
    try {
      // Escape via JSON so quotes/newlines are safe.
      final prelude = '''
var result = ${jsonEncode(result)};
var baseUrl = ${jsonEncode(baseUrl)};
var src = ${jsonEncode(src.isEmpty ? result : src)};
var java = java || { getString: function(x){ return String(x==null?'':x); }, ajax: function(){ return ''; } };
''';
      final wrapped = '''
(function(){
$prelude
$code
})()
''';
      final jsResult = rt.evaluate(wrapped);
      if (jsResult.isError) {
        return result;
      }
      return _stringify(jsResult.stringResult, jsResult.rawResult);
    } catch (_) {
      return result;
    }
  }

  /// If [rule] is JS, run it against [input]; otherwise return null (caller handles).
  String? tryEvalRule(
    String rule, {
    required String input,
    required String baseUrl,
  }) {
    if (!needsJs(rule)) return null;
    final code = extractCode(rule);
    if (code == null || code.isEmpty) return null;
    return eval(code, result: input, baseUrl: baseUrl, src: input);
  }

  /// Parse JS list output into List (of Map or String).
  List<dynamic> evalList(
    String code, {
    String result = '',
    String baseUrl = '',
    String src = '',
  }) {
    final out = eval(code, result: result, baseUrl: baseUrl, src: src);
    if (out.isEmpty) return const [];
    try {
      final decoded = jsonDecode(out);
      if (decoded is List) return decoded;
      if (decoded is Map) return [decoded];
    } catch (_) {
      // newline / comma separated fallback
      final lines = out
          .split(RegExp(r'[\r\n]+'))
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
      if (lines.length > 1) return lines;
    }
    return [out];
  }

  String _stringify(String stringResult, dynamic raw) {
    if (raw is List || raw is Map) {
      try {
        return jsonEncode(raw);
      } catch (_) {}
    }
    final s = stringResult;
    // QuickJS may return [object Object]; prefer JSON if looks like array
    if (s == '[object Object]' || s == 'undefined' || s == 'null') {
      try {
        return jsonEncode(raw);
      } catch (_) {
        return '';
      }
    }
    return s;
  }

  void dispose() {
    try {
      _rt?.dispose();
    } catch (_) {}
    _rt = null;
  }
}
