/// Engine-level search hit from a book source.
class SearchBook {
  String name;
  String author;
  String kind;
  String wordCount;
  String lastChapter;
  String intro;
  String coverUrl;
  String bookUrl;
  String sourceUrl;
  String sourceName;

  SearchBook({
    this.name = '',
    this.author = '',
    this.kind = '',
    this.wordCount = '',
    this.lastChapter = '',
    this.intro = '',
    this.coverUrl = '',
    this.bookUrl = '',
    this.sourceUrl = '',
    this.sourceName = '',
  });
}

/// Engine-level chapter entry with absolute URL.
class SourceChapter {
  String name;
  String url;
  bool isVolume;
  int index;

  SourceChapter({
    this.name = '',
    this.url = '',
    this.isVolume = false,
    this.index = 0,
  });
}
