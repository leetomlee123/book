class RegexAnalyzer {
  static List<dynamic> getList(String content, String pattern) {
    if (pattern.isEmpty || content.isEmpty) return const [];
    try {
      final re = RegExp(pattern, multiLine: true, dotAll: true);
      return re.allMatches(content).map((m) {
        if (m.groupCount >= 1) return m.group(1) ?? m.group(0) ?? '';
        return m.group(0) ?? '';
      }).toList();
    } catch (_) {
      return const [];
    }
  }

  static String getString(String content, String pattern) {
    if (pattern.isEmpty || content.isEmpty) return '';
    try {
      final re = RegExp(pattern, multiLine: true, dotAll: true);
      final m = re.firstMatch(content);
      if (m == null) return '';
      if (m.groupCount >= 1) return m.group(1) ?? '';
      return m.group(0) ?? '';
    } catch (_) {
      return '';
    }
  }
}
