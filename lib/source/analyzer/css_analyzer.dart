import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;

class CssAnalyzer {
  static Document parse(String content) => html_parser.parse(content);

  /// Convert Legado/Jsoup-ish selectors to CSS that `package:html` understands.
  ///
  /// Examples:
  /// - `class.chapter_list` → `.chapter_list`
  /// - `id.list` → `#list`
  /// - `tag.a` / `a` → `a`
  /// - `class.list@tag.a` → `.list a`  (Jsoup child chain via `@`)
  /// - strips unsupported `:eq(n)` / `:contains(...)` lightly
  static String normalizeSelector(String selector) {
    var s = selector.trim();
    if (s.isEmpty) return s;

    // Drop leading @css: if still present.
    if (s.toLowerCase().startsWith('@css:')) {
      s = s.substring(5).trim();
    }

    // Strip a trailing @attr if present (AnalyzeRule usually does this first).
    if (s.contains('@')) {
      final at = s.lastIndexOf('@');
      final tail = s.substring(at + 1).trim();
      if (_isAttrToken(tail)) {
        s = s.substring(0, at).trim();
      }
    }

    // Jsoup-style child chain: class.foo@tag.a  → .foo a
    if (s.contains('@')) {
      final parts =
          s.split('@').map((e) => e.trim()).where((e) => e.isNotEmpty);
      final converted = <String>[];
      for (final p in parts) {
        if (_isAttrToken(p)) continue;
        final c = _convertJsoupToken(p);
        if (c.isNotEmpty) converted.add(c);
      }
      s = converted.join(' ');
    } else {
      // Space-separated tokens may still use class./id./tag.
      s = s
          .split(RegExp(r'\s+'))
          .map(_convertJsoupToken)
          .where((e) => e.isNotEmpty)
          .join(' ');
    }

    // package:html does not support :eq(n) / :gt / :lt / :contains
    s = s.replaceAll(RegExp(r':eq\(\d+\)'), '');
    s = s.replaceAll(RegExp(r':gt\(\d+\)'), '');
    s = s.replaceAll(RegExp(r':lt\(\d+\)'), '');
    s = s.replaceAll(RegExp(r':contains\((?:[^)]|\\.)*\)'), '');
    return s.trim();
  }

  static bool _isAttrToken(String p) {
    const attrs = {
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
    return attrs.contains(p) || p.startsWith('data-');
  }

  static String _convertJsoupToken(String token) {
    var t = token.trim();
    if (t.isEmpty) return '';
    // class.xxx / id.xxx / tag.xxx
    final m = RegExp(r'^(class|id|tag)\.(.+)$', caseSensitive: false).firstMatch(t);
    if (m != null) {
      final kind = m.group(1)!.toLowerCase();
      final name = m.group(2)!;
      switch (kind) {
        case 'class':
          return '.${name.replaceAll(RegExp(r'\s+'), '.')}';
        case 'id':
          return '#$name';
        case 'tag':
          return name;
      }
    }
    return t;
  }

  static List<Element> getElements(Document doc, String selector) {
    if (selector.isEmpty) return const [];
    try {
      final sel = normalizeSelector(selector);
      if (sel.isEmpty) return const [];
      return doc.querySelectorAll(sel);
    } catch (_) {
      return const [];
    }
  }

  static List<Element> getElementsFrom(Element root, String selector) {
    if (selector.isEmpty) return [root];
    try {
      final sel = normalizeSelector(selector);
      if (sel.isEmpty) return [root];
      return root.querySelectorAll(sel);
    } catch (_) {
      return const [];
    }
  }

  static String getString(Element el, String selector, String attr) {
    Element target = el;
    if (selector.isNotEmpty) {
      try {
        final sel = normalizeSelector(selector);
        final found = el.querySelector(sel);
        if (found != null) {
          target = found;
        } else {
          return '';
        }
      } catch (_) {
        return '';
      }
    }
    return _attr(target, attr);
  }

  static String _attr(Element el, String attr) {
    switch (attr) {
      case '':
      case 'text':
        return el.text;
      case 'textNodes':
        // Legado: direct text-node children joined by newlines.
        return el.nodes
            .whereType<Text>()
            .map((n) => n.text.trim())
            .where((s) => s.isNotEmpty)
            .join('\n');
      case 'ownText':
        // Direct text only — exclude descendant element text.
        return el.nodes.whereType<Text>().map((n) => n.text).join().trim();
      case 'html':
        return el.innerHtml;
      case 'href':
        return el.attributes['href'] ?? '';
      case 'src':
        // Lazy-load covers: real URL often in data-src / data-original.
        return _imageUrl(el);
      case 'value':
      case 'alt':
      case 'title':
      case 'id':
      case 'class':
      case 'content':
        return el.attributes[attr] ?? '';
      default:
        // data-src etc. may be requested explicitly by rules.
        if (attr.startsWith('data-')) {
          return el.attributes[attr] ?? '';
        }
        return el.attributes[attr] ?? el.text;
    }
  }

  /// Prefer real cover URL over lazy-load placeholders.
  static String _imageUrl(Element el) {
    const lazyKeys = [
      'data-src',
      'data-original',
      'data-lazy-src',
      'data-url',
      'data-echo',
      'data-srcset',
      'srcset',
      'src',
    ];
    for (final k in lazyKeys) {
      var v = (el.attributes[k] ?? '').trim();
      if (v.isEmpty) continue;
      // srcset: "url 1x, url2 2x" → first url
      if (k == 'srcset' || k == 'data-srcset') {
        v = v.split(',').first.trim().split(RegExp(r'\s+')).first;
      }
      if (v.isEmpty) continue;
      if (_looksLikePlaceholder(v) && k == 'src') {
        // keep looking for data-* first; only accept src if nothing better
        continue;
      }
      if (!_looksLikePlaceholder(v)) return v;
      // placeholder still better than empty if no other attr
    }
    // Fall back to raw src even if placeholder
    return (el.attributes['src'] ?? '').trim();
  }

  static bool _looksLikePlaceholder(String url) {
    final u = url.toLowerCase();
    return u.contains('loading') ||
        u.contains('placeholder') ||
        u.contains('lazy') ||
        u.endsWith('/nocover.jpg') ||
        u.endsWith('/nopic.gif') ||
        u.contains('default_cover') ||
        u.contains('noimg') ||
        u.contains('no-cover');
  }
}
