import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;

/// CSS / Jsoup-ish selector engine used by [AnalyzeRule].
///
/// Supports Legado/Jsoup extras that `package:html` does not:
/// - `class.x` / `id.x` / `tag.a`
/// - `a.0` / `label.1` element index (→ `:eq(n)`)
/// - `@` child chains (`class.list@tag.a` → `.list a`)
/// - `:eq(n)` / `:gt(n)` / `:lt(n)` / `:contains(text)` (applied after match)
/// - trailing list range `a[-1:0]` (reverse) / `a[0:3]`
class CssAnalyzer {
  static Document parse(String content) => html_parser.parse(content);

  /// Convert Legado/Jsoup-ish selectors to CSS + preserve pseudo filters.
  ///
  /// Prefer [getElements] / [getString] which apply `:eq` / `:contains` correctly.
  /// This returns only the CSS portion (pseudos stripped) for callers that
  /// still use raw `querySelectorAll`.
  static String normalizeSelector(String selector) {
    return _compile(selector).css;
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

    // Jsoup index: a.0 / h3.1 / label.2  → tag:eq(n)
    // Must run before class./id. so "a.0" is not treated as class "0".
    final idx = RegExp(
      r'^([a-zA-Z][\w-]*)\.(\d+)(.*)$',
    ).firstMatch(t);
    if (idx != null) {
      final tag = idx.group(1)!;
      final n = idx.group(2)!;
      final rest = idx.group(3) ?? '';
      // Avoid rewriting class.0 / id.0 / tag.0 which are Jsoup type prefixes.
      if (tag != 'class' && tag != 'id' && tag != 'tag') {
        return '$tag:eq($n)$rest';
      }
    }

    // class.xxx / id.xxx / tag.xxx — leave :pseudo on the token for later.
    final m = RegExp(
      r'^(class|id|tag)\.([^:]+)',
      caseSensitive: false,
    ).firstMatch(t);
    if (m != null) {
      final kind = m.group(1)!.toLowerCase();
      final name = m.group(2)!;
      final rest = t.substring(m.end); // e.g. :eq(0)
      String base;
      switch (kind) {
        case 'class':
          base = '.${name.replaceAll(RegExp(r'\s+'), '.')}';
        case 'id':
          base = '#$name';
        case 'tag':
          base = name;
        default:
          base = t;
      }
      return '$base$rest';
    }
    return t;
  }

  /// Optional trailing list range: `selector[-1:0]` or `selector[0:3]`.
  static final _rangeRe = RegExp(r'^(.*?)\[(-?\d+):(-?\d+)\]\s*$');

  static ({String selector, int? start, int? end}) _splitRange(String raw) {
    final m = _rangeRe.firstMatch(raw.trim());
    if (m == null) {
      return (selector: raw.trim(), start: null, end: null);
    }
    return (
      selector: (m.group(1) ?? '').trim(),
      start: int.tryParse(m.group(2) ?? ''),
      end: int.tryParse(m.group(3) ?? ''),
    );
  }

  /// Apply Legado-style list slice. `[-1:0]` reverses the whole list.
  static List<Element> applyRange(List<Element> els, int? start, int? end) {
    if (start == null || end == null || els.isEmpty) return els;
    // Full reverse (common toc: newest-first → oldest-first).
    if (start == -1 && end == 0) {
      return els.reversed.toList(growable: false);
    }
    var s = start;
    var e = end;
    if (s < 0) s = els.length + s;
    if (e < 0) e = els.length + e;
    if (s < 0) s = 0;
    if (e < 0) e = 0;
    if (s >= els.length) return const [];
    // Inclusive end when e >= s; exclusive-style when using positive python-like.
    if (e >= s) {
      final endEx = (e + 1).clamp(0, els.length);
      return els.sublist(s, endEx);
    }
    // Reverse sub-range.
    final slice = els.sublist(e, s + 1);
    return slice.reversed.toList(growable: false);
  }

  /// Compile selector → CSS string + ordered pseudo filters for the last
  /// space-separated segment (see progressive [getElements]).
  static _CompiledSelector _compile(String selector) {
    var s = selector.trim();
    if (s.isEmpty) return const _CompiledSelector('', []);

    if (s.toLowerCase().startsWith('@css:')) {
      s = s.substring(5).trim();
    }

    // Strip trailing @attr if present (AnalyzeRule usually does this first).
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
      s = s
          .split(RegExp(r'\s+'))
          .map(_convertJsoupToken)
          .where((e) => e.isNotEmpty)
          .join(' ');
    }

    return _CompiledSelector(s, const []);
  }

  /// Split a full selector into progressive steps, each with base CSS + filters.
  ///
  /// Pure CSS segments (no :eq/:contains) are accumulated so combinators like
  /// `div > a:eq(0)` stay one query. Intermediate pseudos (e.g. `li:eq(1) a`)
  /// flush a step so later segments query within the filtered set.
  static List<_SelectorStep> _steps(String selector) {
    final compiled = _compile(selector);
    final raw = compiled.css.trim();
    if (raw.isEmpty) return const [];

    final tokens = _splitCssTokens(raw);
    if (tokens.isEmpty) return const [];

    final steps = <_SelectorStep>[];
    final cssAcc = StringBuffer();

    void flushPure() {
      final s = cssAcc.toString().trim();
      cssAcc.clear();
      if (s.isNotEmpty) {
        steps.add(_SelectorStep(base: s, filters: const []));
      }
    }

    for (final token in tokens) {
      if (token == '>' || token == '+' || token == '~' || token == ',') {
        if (cssAcc.isEmpty) {
          cssAcc.write(token);
        } else {
          cssAcc.write(' $token');
        }
        continue;
      }
      final step = _parseStep(token);
      if (step.filters.isEmpty) {
        if (cssAcc.isNotEmpty) cssAcc.write(' ');
        cssAcc.write(step.base);
      } else {
        final prefix = cssAcc.toString().trim();
        cssAcc.clear();
        final base = prefix.isEmpty ? step.base : '$prefix ${step.base}';
        steps.add(_SelectorStep(base: base.trim(), filters: step.filters));
      }
    }
    flushPure();
    return steps;
  }

  /// Split on whitespace not inside parentheses.
  static List<String> _splitCssTokens(String s) {
    final out = <String>[];
    final buf = StringBuffer();
    var depth = 0;
    for (var i = 0; i < s.length; i++) {
      final ch = s[i];
      if (ch == '(') {
        depth++;
        buf.write(ch);
      } else if (ch == ')') {
        depth = depth > 0 ? depth - 1 : 0;
        buf.write(ch);
      } else if (depth == 0 && (ch == ' ' || ch == '\t' || ch == '\n')) {
        final t = buf.toString().trim();
        if (t.isNotEmpty) out.add(t);
        buf.clear();
      } else {
        buf.write(ch);
      }
    }
    final t = buf.toString().trim();
    if (t.isNotEmpty) out.add(t);
    return out;
  }

  static final _pseudoRe = RegExp(
    r':(eq|gt|lt)\((-?\d+)\)|:contains\(([^)]*)\)',
    caseSensitive: false,
  );

  static _SelectorStep _parseStep(String token) {
    final filters = <_PseudoFilter>[];
    var base = token;
    // Extract all pseudos left-to-right, remove from base.
    final matches = _pseudoRe.allMatches(token).toList();
    if (matches.isEmpty) {
      return _SelectorStep(base: token, filters: const []);
    }
    for (final m in matches) {
      final kind = (m.group(1) ?? 'contains').toLowerCase();
      if (kind == 'contains' || m.group(1) == null) {
        final text = (m.group(3) ?? '').trim();
        // Strip optional quotes around contains text.
        final unquoted = _unquote(text);
        filters.add(_PseudoFilter.contains(unquoted));
      } else {
        final n = int.tryParse(m.group(2) ?? '') ?? 0;
        filters.add(_PseudoFilter.index(kind, n));
      }
    }
    base = token.replaceAll(_pseudoRe, '').trim();
    // Empty base after strip → match all elements under parent (`*`).
    if (base.isEmpty) base = '*';
    return _SelectorStep(base: base, filters: filters);
  }

  static String _unquote(String s) {
    if (s.length >= 2) {
      final a = s[0];
      final b = s[s.length - 1];
      if ((a == "'" && b == "'") || (a == '"' && b == '"')) {
        return s.substring(1, s.length - 1);
      }
    }
    return s;
  }

  static List<Element> _applyFilters(
    List<Element> els,
    List<_PseudoFilter> filters,
  ) {
    var cur = els;
    for (final f in filters) {
      if (cur.isEmpty) return const [];
      switch (f.kind) {
        case _PseudoKind.eq:
          final i = f.index;
          if (i < 0 || i >= cur.length) return const [];
          cur = [cur[i]];
        case _PseudoKind.gt:
          final i = f.index;
          if (i + 1 >= cur.length) return const [];
          cur = cur.sublist(i + 1);
        case _PseudoKind.lt:
          final i = f.index;
          if (i <= 0) return const [];
          final end = i > cur.length ? cur.length : i;
          cur = cur.sublist(0, end);
        case _PseudoKind.contains:
          final needle = f.text;
          cur = cur
              .where((e) => e.text.contains(needle))
              .toList(growable: false);
      }
    }
    return cur;
  }

  static List<Element> _queryAll(dynamic root, String selector) {
    if (selector.isEmpty) return const [];
    final ranged = _splitRange(selector);
    final steps = _steps(ranged.selector);
    if (steps.isEmpty) return const [];

    final hasPseudo = steps.any((s) => s.filters.isNotEmpty);
    List<Element> result;
    // Fast path: no :eq/:contains — single querySelectorAll (keeps >, +, ~).
    if (!hasPseudo) {
      final css = steps.map((s) => s.base).join(' ').trim();
      if (css.isEmpty) return const [];
      try {
        if (root is Document) {
          result = root.querySelectorAll(css);
        } else if (root is Element) {
          result = root.querySelectorAll(css);
        } else {
          return const [];
        }
      } catch (_) {
        return const [];
      }
    } else if (root is Document) {
      var current = _queryStepOnDoc(root, steps.first);
      for (var i = 1; i < steps.length; i++) {
        current = _queryStepOnElements(current, steps[i]);
        if (current.isEmpty) return const [];
      }
      result = current;
    } else if (root is Element) {
      // First step: query within element (not treating root as match set).
      var current = _queryStepOnElements([root], steps.first);
      for (var i = 1; i < steps.length; i++) {
        current = _queryStepOnElements(current, steps[i]);
        if (current.isEmpty) return const [];
      }
      result = current;
    } else {
      return const [];
    }
    return applyRange(result, ranged.start, ranged.end);
  }

  static List<Element> _queryStepOnDoc(Document doc, _SelectorStep step) {
    try {
      final found = doc.querySelectorAll(step.base);
      return _applyFilters(found, step.filters);
    } catch (_) {
      return const [];
    }
  }

  static List<Element> _queryStepOnElements(
    List<Element> roots,
    _SelectorStep step,
  ) {
    final next = <Element>[];
    for (final root in roots) {
      try {
        List<Element> found;
        if (step.base == '*') {
          found = root.querySelectorAll('*');
        } else {
          found = root.querySelectorAll(step.base);
        }
        next.addAll(_applyFilters(found, step.filters));
      } catch (_) {
        // ignore bad CSS fragment
      }
    }
    return next;
  }

  static List<Element> getElements(Document doc, String selector) {
    if (selector.isEmpty) return const [];
    try {
      return _queryAll(doc, selector);
    } catch (_) {
      return const [];
    }
  }

  static List<Element> getElementsFrom(Element root, String selector) {
    if (selector.isEmpty) return [root];
    try {
      return _queryAll(root, selector);
    } catch (_) {
      return const [];
    }
  }

  static String getString(Element el, String selector, String attr) {
    if (selector.isEmpty) {
      return _attr(el, attr);
    }
    try {
      final found = _queryAll(el, selector);
      if (found.isEmpty) return '';
      return _attr(found.first, attr);
    } catch (_) {
      return '';
    }
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

class _CompiledSelector {
  final String css;
  final List<_PseudoFilter> filters;
  const _CompiledSelector(this.css, this.filters);
}

class _SelectorStep {
  final String base;
  final List<_PseudoFilter> filters;
  const _SelectorStep({required this.base, required this.filters});
}

enum _PseudoKind { eq, gt, lt, contains }

class _PseudoFilter {
  final _PseudoKind kind;
  final int index;
  final String text;

  const _PseudoFilter._(this.kind, this.index, this.text);

  factory _PseudoFilter.index(String kind, int n) {
    switch (kind) {
      case 'gt':
        return _PseudoFilter._(_PseudoKind.gt, n, '');
      case 'lt':
        return _PseudoFilter._(_PseudoKind.lt, n, '');
      case 'eq':
      default:
        return _PseudoFilter._(_PseudoKind.eq, n, '');
    }
  }

  factory _PseudoFilter.contains(String text) =>
      _PseudoFilter._(_PseudoKind.contains, 0, text);
}
