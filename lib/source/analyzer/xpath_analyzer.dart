import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;

/// Minimal XPath subset used by many Chinese novel sources.
///
/// Supported forms:
/// - `//meta[@property='og:image']/@content`
/// - `//meta[@property="og:novel:author"]/@content`
/// - `//meta[@property='a' or @property='b']/@content`
/// - `//tag[@attr='value']` → element text
/// - `//tag/@attr`
///
/// Unsupported XPath returns empty (never throws).
class XpathAnalyzer {
  static Document parse(String content) => html_parser.parse(content);

  static List<dynamic> getList(Document doc, String xpath) {
    final hits = _query(doc, xpath);
    return hits.map((e) => e.value).where((v) => v.isNotEmpty).toList();
  }

  static String getString(Document doc, String xpath) {
    final hits = _query(doc, xpath);
    if (hits.isEmpty) return '';
    // Multiple matches (e.g. kind with or-properties) → join unique non-empty.
    final parts = <String>[];
    final seen = <String>{};
    for (final h in hits) {
      final v = h.value.trim();
      if (v.isEmpty || !seen.add(v)) continue;
      parts.add(v);
    }
    return parts.join(',');
  }

  static List<_Hit> _query(Document doc, String xpath) {
    var x = xpath.trim();
    if (x.isEmpty) return const [];
    if (x.startsWith('@xpath:')) x = x.substring(7).trim();

    // //tag[@attr='v' or @attr='w']/@out
    // //tag/@attr
    // //tag
    final m = RegExp(
      r"^//([a-zA-Z_][\w-]*)"
      r"(?:\[@([a-zA-Z_:][\w:.-]*)\s*=\s*([^\]]+)\])?"
      r"(?:/@([a-zA-Z_:][\w:.-]*)|$)",
    ).firstMatch(x);
    if (m == null) return const [];

    final tag = m.group(1)!.toLowerCase();
    final attrName = m.group(2);
    final attrExpr = m.group(3);
    final outAttr = m.group(4);

    final values = <String>[];
    if (attrName != null && attrExpr != null) {
      // Support: 'a' or @property='b' or @property="c"
      final raw = attrExpr.trim();
      final parts = raw.split(RegExp(r'\s+or\s+', caseSensitive: false));
      for (final p in parts) {
        final piece = p.trim();
        final extracted = _extractQuoted(piece);
        if (extracted != null) values.add(extracted);
      }
    }

    final els = doc.getElementsByTagName(tag);
    final hits = <_Hit>[];
    for (final el in els) {
      if (attrName != null) {
        final actual = el.attributes[attrName] ?? '';
        if (values.isNotEmpty && !values.contains(actual)) continue;
      }
      if (outAttr != null && outAttr.isNotEmpty) {
        hits.add(_Hit(el.attributes[outAttr] ?? ''));
      } else {
        hits.add(_Hit(el.text.trim()));
      }
    }
    return hits;
  }

  /// Pull the quoted value out of `@attr='v'`, `@attr="v"`, or bare `'v'`.
  static String? _extractQuoted(String piece) {
    // ...='value' or ...="value"
    final withAttr = RegExp(
      r'''(?:@[a-zA-Z_:][\w:.-]*\s*=\s*)?(['"])(.*?)\1$''',
    ).firstMatch(piece);
    if (withAttr != null) return withAttr.group(2);
    return null;
  }
}

class _Hit {
  final String value;
  const _Hit(this.value);
}
