import 'dart:convert';

import 'package:book/source/analyzer/css_analyzer.dart';
import 'package:book/source/analyzer/json_analyzer.dart';
import 'package:book/source/analyzer/js_analyzer.dart';
import 'package:book/source/analyzer/regex_analyzer.dart';
import 'package:book/source/util/text_clean.dart';
import 'package:html/dom.dart';

/// Dispatches a Legado-style rule string against HTML or JSON content.
class AnalyzeRule {
  final String content;
  final String baseUrl;
  final bool isJson;
  Document? _doc;
  dynamic _json;

  AnalyzeRule({
    required this.content,
    required this.baseUrl,
    bool? isJson,
  }) : isJson = isJson ?? _detectJson(content);

  static bool _detectJson(String c) {
    final t = c.trimLeft();
    return t.startsWith('{') || t.startsWith('[');
  }

  Document get doc => _doc ??= CssAnalyzer.parse(content);

  dynamic get jsonRoot {
    _json ??= () {
      try {
        return jsonDecode(content);
      } catch (_) {
        return null;
      }
    }();
    return _json;
  }

  /// Get a list of elements/nodes for list rules (bookList / chapterList).
  /// Supports `||` alternatives: first non-empty wins.
  List<dynamic> getList(String rule) {
    if (rule.isEmpty) return const [];

    for (final alt in _splitAlternatives(rule)) {
      final list = _getListSingle(alt);
      if (list.isNotEmpty) return list;
    }
    return const [];
  }

  List<dynamic> _getListSingle(String rule) {
    if (rule.isEmpty) return const [];

    // Pure JS list rule
    if (JsEngine.needsJs(rule)) {
      final code = JsEngine.extractCode(rule);
      if (code != null && code.isNotEmpty) {
        return JsEngine.instance.evalList(
          code,
          result: content,
          baseUrl: baseUrl,
          src: content,
        );
      }
    }

    final parsed = _parseRule(rule);
    if (parsed.kind == _RuleKind.js) {
      return JsEngine.instance.evalList(
        parsed.selector,
        result: content,
        baseUrl: baseUrl,
        src: content,
      );
    }
    if (parsed.kind == _RuleKind.json || isJson) {
      return JsonAnalyzer.getList(jsonRoot, parsed.selector);
    }
    if (parsed.kind == _RuleKind.regex) {
      return RegexAnalyzer.getList(content, parsed.selector);
    }
    // CSS / Jsoup-normalized default
    return CssAnalyzer.getElements(doc, parsed.selector);
  }

  /// Extract a single string from [scope] (Element, Map, String, or full content).
  /// Supports `||` alternatives: first non-empty wins.
  String getString(String rule, {dynamic scope}) {
    if (rule.isEmpty) return '';

    for (final alt in _splitAlternatives(rule)) {
      final v = _getStringSingle(alt, scope: scope);
      if (v.isNotEmpty) return v;
    }
    return '';
  }

  String _getStringSingle(String rule, {dynamic scope}) {
    if (rule.isEmpty) return '';

    // All-in-one: rule##regex##replace  (but not inside JS code)
    var r = rule;
    String? postRegex;
    String? postReplace;
    if (!JsEngine.needsJs(r) && r.contains('##')) {
      final parts = r.split('##');
      r = parts[0];
      if (parts.length >= 2) postRegex = parts[1];
      if (parts.length >= 3) postReplace = parts[2];
    }

    // JS rule on full content / prior result
    if (JsEngine.needsJs(r)) {
      final input = _scopeToText(scope);
      final code = JsEngine.extractCode(r) ?? '';
      var result = JsEngine.instance.eval(
        code,
        result: input.isEmpty ? content : input,
        baseUrl: baseUrl,
        src: content,
      );
      if (postRegex != null && postRegex.isNotEmpty) {
        try {
          result = result.replaceAll(
            RegExp(postRegex, multiLine: true, dotAll: true),
            postReplace ?? '',
          );
        } catch (_) {}
      }
      return result.trim();
    }

    // Hybrid: CSS/JSON first then trailing <js>
    final jsEmbed =
        RegExp(r'([\s\S]*?)<js>([\s\S]*?)</js>', caseSensitive: false)
            .firstMatch(r);
    if (jsEmbed != null) {
      final head = (jsEmbed.group(1) ?? '').trim();
      final code = (jsEmbed.group(2) ?? '').trim();
      String prior = '';
      if (head.isNotEmpty) {
        prior = getString(head, scope: scope);
      } else {
        prior = _scopeToText(scope);
        if (prior.isEmpty) prior = content;
      }
      return JsEngine.instance
          .eval(code, result: prior, baseUrl: baseUrl, src: content)
          .trim();
    }

    final parsed = _parseRule(r);
    String result = '';

    if (parsed.kind == _RuleKind.js) {
      result = JsEngine.instance.eval(
        parsed.selector,
        result: _scopeToText(scope).isEmpty ? content : _scopeToText(scope),
        baseUrl: baseUrl,
        src: content,
      );
    } else if (scope is Element) {
      result = CssAnalyzer.getString(scope, parsed.selector, parsed.attr);
      // Bare attr on current element already handled (empty selector).
      // If child selector missed, fall back to element itself for text/href.
      if (result.isEmpty && parsed.selector.isNotEmpty) {
        if (parsed.attr == 'href' || parsed.attr == 'src') {
          final a = scope.localName == 'a'
              ? scope
              : scope.querySelector('a');
          if (a != null) {
            result = a.attributes[parsed.attr] ?? '';
          }
        } else if (parsed.attr.isEmpty ||
            parsed.attr == 'text' ||
            parsed.attr == 'textNodes' ||
            parsed.attr == 'ownText') {
          result = scope.text;
        }
      }
    } else if (scope is Map || scope is List || (isJson && scope == null)) {
      final root = scope ?? jsonRoot;
      result = JsonAnalyzer.getString(root, parsed.selector);
    } else if (parsed.kind == _RuleKind.regex) {
      final text = scope is String ? scope : content;
      result = RegexAnalyzer.getString(text, parsed.selector);
    } else if (parsed.kind == _RuleKind.json || isJson) {
      result = JsonAnalyzer.getString(scope ?? jsonRoot, parsed.selector);
    } else {
      // CSS from full doc or sub-element string
      if (scope is String && scope.isNotEmpty) {
        final sub = CssAnalyzer.parse(scope);
        final els = CssAnalyzer.getElements(sub, parsed.selector);
        if (els.isNotEmpty) {
          result = CssAnalyzer.getString(els.first, '', parsed.attr);
        } else {
          result = CssAnalyzer.getString(
              sub.documentElement ?? sub.body!, '', parsed.attr);
        }
      } else {
        final els = CssAnalyzer.getElements(doc, parsed.selector);
        if (els.isNotEmpty) {
          result = CssAnalyzer.getString(els.first, '', parsed.attr);
        }
      }
    }

    if (postRegex != null && postRegex.isNotEmpty) {
      try {
        result = result.replaceAll(
          RegExp(postRegex, multiLine: true, dotAll: true),
          postReplace ?? '',
        );
      } catch (_) {}
    }
    return result.trim();
  }

  /// Content rule often wants HTML then plain text.
  String getHtmlString(String rule, {dynamic scope}) {
    if (rule.isEmpty) return '';
    if (JsEngine.needsJs(rule)) {
      return getString(rule, scope: scope);
    }
    for (final alt in _splitAlternatives(rule)) {
      final parsed = _parseRule(alt);
      if (scope is Element) {
        if (parsed.selector.isEmpty) {
          final v = scope.innerHtml;
          if (v.isNotEmpty) return v;
          continue;
        }
        final els = CssAnalyzer.getElementsFrom(scope, parsed.selector);
        if (els.isEmpty) continue;
        return els.map((e) => e.innerHtml).join('\n');
      }
      final els = CssAnalyzer.getElements(doc, parsed.selector);
      if (els.isEmpty) {
        final v = getString(alt, scope: scope);
        if (v.isNotEmpty) return v;
        continue;
      }
      return els.map((e) => e.innerHtml).join('\n');
    }
    return '';
  }

  String _scopeToText(dynamic scope) {
    if (scope == null) return '';
    if (scope is String) return scope;
    if (scope is Element) return scope.text;
    if (scope is Map || scope is List) {
      try {
        return jsonEncode(scope);
      } catch (_) {
        return scope.toString();
      }
    }
    return scope.toString();
  }

  /// Split Legado `||` alternatives, ignoring `||` inside JS blocks.
  List<String> _splitAlternatives(String rule) {
    final r = rule.trim();
    if (r.isEmpty) return const [];
    if (JsEngine.needsJs(r) || !r.contains('||')) return [r];
    return r
        .split('||')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  _ParsedRule _parseRule(String rule) {
    var r = rule.trim();
    if (r.startsWith('@js:')) {
      return _ParsedRule(_RuleKind.js, r.substring(4).trim(), '');
    }
    // @css: selector@attr
    if (r.startsWith('@css:')) {
      r = r.substring(5);
      return _splitAttr(r, _RuleKind.css);
    }
    if (r.startsWith('@json:') || r.startsWith('\$.') || r.startsWith('\$[')) {
      if (r.startsWith('@json:')) r = r.substring(6);
      return _ParsedRule(_RuleKind.json, r, '');
    }
    if (r.startsWith('@regex:') || r.startsWith(':')) {
      if (r.startsWith('@regex:')) r = r.substring(7);
      if (r.startsWith(':')) r = r.substring(1);
      return _ParsedRule(_RuleKind.regex, r, '');
    }
    if (r.startsWith('@xpath:') || r.startsWith('//') || r.startsWith('./')) {
      // XPath not implemented — treat as empty
      return _ParsedRule(_RuleKind.css, '', '');
    }
    // Bare attribute on current element: text / href / @text / @href / data-xxx
    final bare = r.startsWith('@') ? r.substring(1) : r;
    if (_knownAttrs.contains(bare) || bare.startsWith('data-')) {
      final attr = (bare == 'text' || bare == 'textNodes' || bare == 'ownText')
          ? 'text'
          : bare;
      return _ParsedRule(isJson ? _RuleKind.json : _RuleKind.css, '', attr);
    }
    // Default CSS; allow trailing @text / @href / @src / @html / @data-xxx
    return _splitAttr(r, isJson ? _RuleKind.json : _RuleKind.css);
  }

  _ParsedRule _splitAttr(String r, _RuleKind kind) {
    // selector@href  or selector@text  (last segment only when it is an attr)
    final at = r.lastIndexOf('@');
    if (at > 0) {
      final attr = r.substring(at + 1).trim();
      // avoid treating email-like / tag.a as attr; common attrs only
      if (_knownAttrs.contains(attr) ||
          attr.startsWith('data-') ||
          attr == 'html') {
        return _ParsedRule(kind, r.substring(0, at).trim(), attr);
      }
    }
    return _ParsedRule(kind, r, '');
  }

  static const _knownAttrs = {
    'text',
    'href',
    'src',
    'html',
    'textNodes',
    'ownText',
    'content',
    'value',
    'alt',
    'title',
    'id',
    'class',
  };
}

enum _RuleKind { css, json, regex, js }

class _ParsedRule {
  final _RuleKind kind;
  final String selector;
  final String attr;
  _ParsedRule(this.kind, this.selector, this.attr);
}

/// Apply content replaceRegex after extraction.
String finalizeContent(String rawHtmlOrText, String replaceRegex) {
  var t = htmlToPlainText(rawHtmlOrText);
  t = applyReplaceRegex(t, replaceRegex);
  return t.trim();
}
