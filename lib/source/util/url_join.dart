/// Join a possibly-relative [path] against [base].
String urlJoin(String base, String path) {
  final p = path.trim();
  if (p.isEmpty) return base;
  if (p.startsWith('http://') || p.startsWith('https://')) return p;
  if (p.startsWith('//')) {
    final scheme = Uri.tryParse(base)?.scheme ?? 'http';
    return '$scheme:$p';
  }
  final baseUri = Uri.tryParse(base);
  if (baseUri == null) return p;
  if (p.startsWith('/')) {
    return Uri(
      scheme: baseUri.scheme,
      userInfo: baseUri.userInfo,
      host: baseUri.host,
      port: baseUri.hasPort ? baseUri.port : null,
      path: p,
    ).toString();
  }
  return baseUri.resolve(p).toString();
}

String hostOf(String url) {
  final u = Uri.tryParse(url);
  if (u == null || u.host.isEmpty) return url;
  return '${u.scheme}://${u.host}${u.hasPort ? ':${u.port}' : ''}';
}
