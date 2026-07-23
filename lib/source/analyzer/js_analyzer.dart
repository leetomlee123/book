import 'dart:convert';

import 'package:flutter/foundation.dart';
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
/// - `java`    tiny helper object (stubs for CF / browser APIs)
/// - optional [jsLib] helpers (`cfCheck`, etc.) loaded per source
///
/// Returns string, or JSON-encoded list/map when JS returns array/object.
class JsEngine {
  JsEngine._();
  static final JsEngine instance = JsEngine._();

  JavascriptRuntime? _rt;
  bool _failed = false;
  String _loadedJsLib = '';

  JavascriptRuntime? get _runtime {
    if (_failed) return null;
    if (_rt != null) return _rt;
    try {
      _rt = getJavascriptRuntime(forceJavascriptCoreOnAndroid: false);
      // Lightweight polyfills commonly expected by source snippets.
      // java.startBrowserAwait / longToast are stubs: return original body
      // so CF-gated sources degrade to "no challenge rewrite" instead of crash.
      final init = _rt!.evaluate(r'''
var java = {
  getString: function(x){ return String(x==null?'':x); },
  ajax: function(){ return ''; },
  longToast: function(msg){},
  startBrowserAwait: function(url, title){
    return { body: function(){ return ''; }, url: String(url||'') };
  }
};
// Legado helpers used by many searchUrl @js snippets.
function getArguments(vars, key) {
  if (vars == null || key == null) return '';
  var s = String(vars);
  var k = String(key);
  try {
    var o = JSON.parse(s);
    if (o && o[k] != null) return String(o[k]);
  } catch (e) {}
  // query / comma form: key=value&… or key=value,…
  var re = new RegExp('(?:^|[,;&\\s])' + k.replace(/[.*+?^${}()|[\]\\]/g, '\\$&') + '=([^,;&\\s]*)');
  var m = s.match(re);
  if (m) {
    try { return decodeURIComponent(m[1]); } catch (e2) { return m[1]; }
  }
  return '';
}
var source = source || {
  getVariable: function(){ return ''; },
  getKey: function(){ return ''; },
  bookSourceUrl: ''
};
if (typeof String.prototype.endsWith !== 'function') {
  String.prototype.endsWith = function(s) {
    s = String(s);
    return this.length >= s.length && this.substring(this.length - s.length) === s;
  };
}
if (typeof String.prototype.startsWith !== 'function') {
  String.prototype.startsWith = function(s) {
    s = String(s);
    return this.substring(0, s.length) === s;
  };
}
function cfCheck(html, targetUrl){ return String(html==null?'':html); }
1
''');
      if (init.isError) {
        if (kDebugMode) {
          debugPrint('[JsEngine] init error: ${init.stringResult}');
        }
      }
      return _rt;
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[JsEngine] runtime unavailable: $e');
      }
      _failed = true;
      return null;
    }
  }

  /// Install Legado `jsLib` helpers for the active source (idempotent per text).
  void ensureJsLib(String jsLib) {
    final lib = jsLib.trim();
    if (lib.isEmpty || lib == _loadedJsLib) return;
    final rt = _runtime;
    if (rt == null) return;
    try {
      rt.evaluate(lib);
      _loadedJsLib = lib;
      if (kDebugMode) {
        debugPrint('[JsEngine] jsLib loaded (${lib.length} chars)');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[JsEngine] jsLib failed: $e');
      }
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
    String jsLib = '',
  }) {
    if (jsLib.isNotEmpty) ensureJsLib(jsLib);
    final rt = _runtime;
    if (rt == null || code.isEmpty) return result;
    try {
      // Escape via JSON so quotes/newlines are safe.
      final prelude = '''
var result = ${jsonEncode(result)};
var baseUrl = ${jsonEncode(baseUrl)};
var src = ${jsonEncode(src.isEmpty ? result : src)};
var java = java || {
  getString: function(x){ return String(x==null?'':x); },
  ajax: function(){ return ''; },
  longToast: function(){},
  startBrowserAwait: function(url, title){
    return { body: function(){ return ''; }, url: String(url||'') };
  }
};
if (typeof getArguments !== 'function') {
  function getArguments(vars, key) {
    if (vars == null || key == null) return '';
    var s = String(vars);
    var k = String(key);
    try {
      var o = JSON.parse(s);
      if (o && o[k] != null) return String(o[k]);
    } catch (e) {}
    var re = new RegExp('(?:^|[,;&\\\\s])' + k.replace(/[.*+?^\${}()|[\\]\\\\]/g, '\\\\\$&') + '=([^,;&\\\\s]*)');
    var m = s.match(re);
    if (m) {
      try { return decodeURIComponent(m[1]); } catch (e2) { return m[1]; }
    }
    return '';
  }
}
var source = {
  getVariable: function(){ return ''; },
  getKey: function(){ return baseUrl; },
  bookSourceUrl: baseUrl
};
if (typeof cfCheck !== 'function') {
  function cfCheck(html, targetUrl){ return String(html==null?'':html); }
}
''';
      // Bare expressions (Legado `@js: baseUrl.endsWith(...) ? …`) need `return (…)`.
      // Single expression-statements (`cfCheck(result, baseUrl);`) also need return.
      // Multi-statement scripts run as-is (should assign `result` if they need output).
      final trimmedCode = code.trim();
      final singleExprStmt = RegExp(r'^([^;{}\n]+);\s*$').firstMatch(trimmedCode);
      final looksExpr = !trimmedCode.contains(';') &&
          !trimmedCode.contains('{') &&
          !RegExp(
            r'\b(var|let|const|function|return|if|for|while|class)\b',
          ).hasMatch(trimmedCode);
      final String wrapped;
      if (looksExpr) {
        wrapped = '''
(function(){
$prelude
return ($trimmedCode);
})()
''';
      } else if (singleExprStmt != null) {
        final expr = singleExprStmt.group(1)!.trim();
        wrapped = '''
(function(){
$prelude
return ($expr);
})()
''';
      } else {
        wrapped = '''
(function(){
$prelude
$trimmedCode
return (typeof result === 'undefined' || result === null) ? '' : result;
})()
''';
      }
      final jsResult = rt.evaluate(wrapped);
      if (jsResult.isError) {
        if (kDebugMode) {
          debugPrint(
            '[JsEngine] eval error: ${jsResult.stringResult} '
            'code=${code.length > 80 ? '${code.substring(0, 80)}…' : code}',
          );
        }
        return result;
      }
      return _stringify(jsResult.stringResult, jsResult.rawResult);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[JsEngine] eval exception: $e');
      }
      return result;
    }
  }

  /// If [rule] is JS, run it against [input]; otherwise return null (caller handles).
  String? tryEvalRule(
    String rule, {
    required String input,
    required String baseUrl,
    String jsLib = '',
  }) {
    if (!needsJs(rule)) return null;
    final code = extractCode(rule);
    if (code == null || code.isEmpty) return null;
    return eval(
      code,
      result: input,
      baseUrl: baseUrl,
      src: input,
      jsLib: jsLib,
    );
  }

  /// Parse JS list output into List (of Map or String).
  List<dynamic> evalList(
    String code, {
    String result = '',
    String baseUrl = '',
    String src = '',
    String jsLib = '',
  }) {
    final out = eval(
      code,
      result: result,
      baseUrl: baseUrl,
      src: src,
      jsLib: jsLib,
    );
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
    _loadedJsLib = '';
  }
}
