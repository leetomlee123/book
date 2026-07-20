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
  var t = html;
  // Drop non-content nodes before stripping tags.
  t = t
      .replaceAll(
          RegExp(r'<script[\s\S]*?</script>', caseSensitive: false), '')
      .replaceAll(RegExp(r'<style[\s\S]*?</style>', caseSensitive: false), '')
      // Inline chapter comment/count widgets (e.g. banshanren `.z.count_n`).
      .replaceAll(
          RegExp(
            r'<span[^>]*class="[^"]*\bz\b[^"]*"[^>]*>[\s\S]*?</span>',
            caseSensitive: false,
          ),
          '')
      .replaceAll(
          RegExp(r'<button[\s\S]*?</button>', caseSensitive: false), '');
  t = t
      .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</p\s*>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</div\s*>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'</h[1-6]\s*>', caseSensitive: false), '\n')
      .replaceAll(RegExp(r'<[^>]+>'), '')
      .replaceAll('&nbsp;', ' ')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&amp;', '&')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'");
  t = t.replaceAllMapped(RegExp(r'&#(\d+);'), (m) {
    final n = int.tryParse(m.group(1) ?? '');
    if (n == null) return m.group(0) ?? '';
    return String.fromCharCode(n);
  });
  // Drop leftover pure digit lines (comment counters) and collapse blanks.
  final lines = t
      .split(RegExp(r'[\r\n]+'))
      .map((e) => e.replaceAll(RegExp(r'[ \t ]+'), ' ').trim())
      .where((e) => e.isNotEmpty && !RegExp(r'^\d{1,4}$').hasMatch(e))
      .toList();
  return lines.join('\n').trim();
}

/// Normalize chapter titles for fuzzy matching.
String normalizeChapterTitle(String name) {
  var t = name.trim();
  t = t.replaceAll(RegExp(r'[\s　]+'), '');
  t = t.replaceAll(RegExp(r'[【】\[\]（）()「」『』《》<>·•\-—_：:，,。.!！?？]'), '');
  t = t.replaceAll(RegExp(r'^第([0-9零一二三四五六七八九十百千万两]+)[章节回卷部篇]'), '');
  return t.toLowerCase();
}

/// Clean author strings scraped from search / detail pages.
///
/// Common source mess:
/// - label prefix: `作者：张三` / `作者 张三`
/// - whole card text when the author selector missed
/// - trailing metadata glued on one line: `张三 分类：玄幻 状态：连载`
String cleanAuthor(String raw) {
  var t = raw.trim();
  if (t.isEmpty) return '';

  // Prefer the line that actually mentions 作者 when multi-line blob was captured.
  if (t.contains('\n') || t.contains('\r')) {
    final lines = t
        .split(RegExp(r'[\r\n]+'))
        .map((e) => e.replaceAll(RegExp(r'[ \t　]+'), ' ').trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final withLabel = lines.where((e) => e.contains('作者')).toList();
    t = withLabel.isNotEmpty ? withLabel.first : lines.first;
  }

  t = t.replaceAll(RegExp(r'[ \t　]+'), ' ').trim();

  // Explicit "作者：xxx" somewhere in the blob (selector often returns parent).
  final labeled = RegExp(
    r'作者[：:\s　]*([^\s/|｜,，;；>）\)\n\r]{1,30})',
  ).firstMatch(t);
  if (labeled != null) {
    t = (labeled.group(1) ?? '').trim();
  } else {
    // Leading label only.
    t = t.replaceFirst(
      RegExp(r'^(作者名?|作\s*者|原著|编剧|著者|著|编)[：:\s　]*'),
      '',
    );
  }

  // Drop trailing "著" / "作品" markers common on CN novel sites.
  t = t.replaceFirst(RegExp(r'(著|作品|大神|大佬)$'), '').trim();

  // Cut trailing site metadata often concatenated after the name.
  t = t
      .split(RegExp(
        r'\s*(?:分类|类型|类别|状态|更新|字数|连载|完结|最新|简介|标签|点击|人气)[：:\s]',
      ))
      .first
      .trim();

  // Also cut on fullwidth/halfwidth separators after a short name.
  // e.g. "张三/玄幻" "张三|连载"
  final sep = RegExp(r'[/|｜]').firstMatch(t);
  if (sep != null && sep.start >= 1 && sep.start <= 16) {
    t = t.substring(0, sep.start).trim();
  }

  // Strip wrapping brackets / punctuation leftovers.
  t = t.replaceAll(RegExp(r'^[【\[（(「『]+|[】\]）)」』]+$'), '').trim();
  t = t.replaceAll(RegExp(r'^[：:\-—|/／]+|[：:\-—|/／]+$'), '').trim();

  // Reject obvious "whole card" captures (title+author+intro dumped together).
  if (t.length > 32) {
    final short = RegExp(
      r'作者[：:\s　]*([^\s/|｜,，;；]{1,20})',
    ).firstMatch(raw);
    if (short != null) return (short.group(1) ?? '').trim();
    return '';
  }
  // Pure digits / empty labels are not author names.
  if (t.isEmpty || RegExp(r'^\d+$').hasMatch(t) || t == '作者') return '';
  return t;
}
