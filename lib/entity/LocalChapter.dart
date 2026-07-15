/// Local chapter with absolute URL (replaces ChapterProto on the book path).
class LocalChapter {
  String chapterId;
  String chapterName;
  String url;
  String hasContent; // "2" = cached
  int index;

  LocalChapter({
    this.chapterId = '',
    this.chapterName = '',
    this.url = '',
    this.hasContent = '0',
    this.index = 0,
  });
}
