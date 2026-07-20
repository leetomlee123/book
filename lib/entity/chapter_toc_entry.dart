/// TOC entry for a book chapter (local catalog row).
class ChapterTocEntry {
  String id;
  String title;
  String url;

  /// True when chapter body is cached in reader.db.
  bool hasBody;
  int ord;

  ChapterTocEntry({
    this.id = '',
    this.title = '',
    this.url = '',
    this.hasBody = false,
    this.ord = 0,
  });
}
