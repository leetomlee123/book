import 'dart:convert';

/// Short stable id from sourceUrl + bookUrl.
String makeBookKey(String sourceUrl, String bookUrl) {
  return _shortHash('$sourceUrl\n$bookUrl');
}

String makeChapterId(String bookKey, String chapterUrl) {
  return _shortHash('$bookKey\n$chapterUrl');
}

/// FNV-1a 64-bit hex, good enough for local keys without extra deps.
String _shortHash(String input) {
  const int fnvOffset = 0xcbf29ce484222325;
  const int fnvPrime = 0x100000001b3;
  var hash = fnvOffset;
  for (final b in utf8.encode(input)) {
    hash ^= b;
    hash = (hash * fnvPrime) & 0xFFFFFFFFFFFFFFFF;
  }
  return hash.toRadixString(16).padLeft(16, '0');
}
