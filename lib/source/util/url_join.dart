/// Join a possibly-relative [path] against [base].
///
/// Never throws on illegal relative paths (e.g. leftover JS snippets).
String urlJoin(String base, String path) {
  final p = path.trim();
  if (p.isEmpty) return base;
  if (p.startsWith('http://') || p.startsWith('https://')) return p;
  if (p.startsWith('//')) {
    final scheme = Uri.tryParse(base)?.scheme ?? 'http';
    return '$scheme:$p';
  }
  // Reject code / prose that is clearly not a URL path segment.
  if (_looksLikeCode(p)) return p;
  final baseUri = Uri.tryParse(base);
  if (baseUri == null || !baseUri.hasScheme) return p;
  if (p.startsWith('/')) {
    return Uri(
      scheme: baseUri.scheme,
      userInfo: baseUri.userInfo,
      host: baseUri.host,
      port: baseUri.hasPort ? baseUri.port : null,
      path: p,
    ).toString();
  }
  try {
    return baseUri.resolve(p).toString();
  } catch (_) {
    // Uri.resolve throws FormatException for e.g. `let foo=…` (illegal scheme).
    return p;
  }
}

String hostOf(String url) {
  final u = Uri.tryParse(url);
  if (u == null || u.host.isEmpty) return url;
  return '${u.scheme}://${u.host}${u.hasPort ? ':${u.port}' : ''}';
}

/// True when [s] looks like source JS / statements rather than a path.
bool _looksLikeCode(String s) {
  if (s.contains('\n') || s.contains(';')) return true;
  if (s.contains('(') && s.contains(')')) {
    // `getArgs(...)` or `let x = f()` — not a relative path.
    if (RegExp(r'\b(let|var|const|function|return|if|for|while)\b')
        .hasMatch(s)) {
      return true;
    }
  }
  if (RegExp(r'^\s*(let|var|const|function)\b').hasMatch(s)) return true;
  // Spaces are rare in real relative paths; common in JS statements.
  if (s.contains(' ') && !s.startsWith('./') && !s.startsWith('../')) {
    return true;
  }
  return false;
}
