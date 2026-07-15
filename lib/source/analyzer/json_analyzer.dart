/// Minimal JSONPath-ish accessor for Legado `@json:` rules.
/// Supports: `$`, `$.a.b`, `$..name` (recursive), `$.list[*]`, `$.list[0]`.
class JsonAnalyzer {
  static List<dynamic> getList(dynamic root, String path) {
    if (root == null) return const [];
    final p = _normalize(path);
    if (p.isEmpty || p == '\$') {
      if (root is List) return root;
      return const [];
    }
    final v = _query(root, p, collectList: true);
    if (v is List) return v;
    if (v == null) return const [];
    return [v];
  }

  static String getString(dynamic root, String path) {
    if (root == null) return '';
    final p = _normalize(path);
    if (p.isEmpty || p == '\$') return root?.toString() ?? '';
    final v = _query(root, p, collectList: false);
    if (v == null) return '';
    if (v is List) {
      return v.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).join('\n');
    }
    return v.toString();
  }

  static String _normalize(String path) {
    var p = path.trim();
    if (p.startsWith('@json:')) p = p.substring(6).trim();
    return p;
  }

  static dynamic _query(dynamic root, String path, {required bool collectList}) {
    // Recursive descent $..key
    if (path.startsWith('\$..')) {
      final key = path.substring(3);
      final found = <dynamic>[];
      _walk(root, (k, v) {
        if (k == key) found.add(v);
      });
      if (collectList) {
        // If values are objects, return them; if lists, flatten
        final out = <dynamic>[];
        for (final f in found) {
          if (f is List) {
            out.addAll(f);
          } else {
            out.add(f);
          }
        }
        return out;
      }
      return found.isEmpty ? null : found.first;
    }

    var cur = root;
    var p = path;
    if (p.startsWith('\$.')) p = p.substring(2);
    if (p.startsWith('\$')) p = p.substring(1);
    if (p.startsWith('.')) p = p.substring(1);

    final tokens = _tokenize(p);
    for (var i = 0; i < tokens.length; i++) {
      final t = tokens[i];
      if (cur == null) return null;
      if (t == '*') {
        if (cur is List) {
          // continue with list as-is for next? usually [*] then done for list
          continue;
        }
        if (cur is Map) {
          cur = cur.values.toList();
        }
        continue;
      }
      final idx = int.tryParse(t);
      if (idx != null && cur is List) {
        if (idx < 0 || idx >= cur.length) return null;
        cur = cur[idx];
        continue;
      }
      if (cur is Map) {
        cur = cur[t];
        continue;
      }
      if (cur is List) {
        // map each
        final next = <dynamic>[];
        for (final item in cur) {
          if (item is Map && item.containsKey(t)) next.add(item[t]);
        }
        cur = next;
        continue;
      }
      return null;
    }
    return cur;
  }

  static List<String> _tokenize(String p) {
    // a.b[0].c[*].d
    final out = <String>[];
    final re = RegExp(r'([^.\[\]]+)|\[(\*|\d+)\]');
    for (final m in re.allMatches(p)) {
      out.add(m.group(1) ?? m.group(2)!);
    }
    return out;
  }

  static void _walk(dynamic node, void Function(String? key, dynamic value) visit,
      [String? key]) {
    visit(key, node);
    if (node is Map) {
      node.forEach((k, v) => _walk(v, visit, k.toString()));
    } else if (node is List) {
      for (final v in node) {
        _walk(v, visit, key);
      }
    }
  }
}
