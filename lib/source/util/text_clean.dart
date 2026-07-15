/// Apply Legado-style replaceRegex: `pattern##replacement` (optional `###` all).
String applyReplaceRegex(String input, String replaceRule) {
  if (replaceRule.isEmpty || input.isEmpty) return input;
  var text = input;
  // Multiple rules separated by && (common Legado convention)
  final rules = replaceRule.split('&&');
  for (final rule in rules) {
    final r = rule.trim();
    if (r.isEmpty) continue;
    final parts = r.split('##');
    if (parts.isEmpty || parts.first.isEmpty) continue;
    final pattern = parts[0];
    final replacement = parts.length > 1 ? parts[1] : '';
    try {
      text = text.replaceAll(RegExp(pattern, multiLine: true, dotAll: true), replacement);
    } catch (_) {
      // ignore invalid regex
    }
  }
  return text;
}

/// Strip tags and normalize whitespace for chapter body.
String htmlToPlainText(String html) {
  if (html.isEmpty) return '';
  var t = html
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</p\s*>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</div\s*>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<[^>]+>'), '')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&amp;', '&')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'");
  // Collapse 3+ newlines
  t = t.replaceAll(RegExp(r'\n{3,}'), '\n\n');
  return t.trim();
}

/// Normalize chapter titles for fuzzy matching.
String normalizeChapterTitle(String name) {
  var t = name.trim();
  t = t.replaceAll(RegExp(r'[\s　]+'), '');
  t = t.replaceAll(RegExp(r'[【】\[\]（）()「」『』《》<>·•\-—_：:，,。.!！?？]'), '');
  t = t.replaceAll(RegExp(r'^第([0-9零一二三四五六七八九十百千万两]+)[章节回卷部篇]'), '');
  return t.toLowerCase();
}
