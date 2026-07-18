import 'package:json_annotation/json_annotation.dart';

part 'Book.g.dart';

@JsonSerializable()
class Book {
  String ChapterId;
  String ChapterName;
  int NewChapterCount;
  String Id;
  String CId;
  int cur;
  int sortTime;
  int index;
  double position;
  String CName;
  String Name;
  String Author;
  String Img;
  String Desc;

  String LastChapterId;
  String LastChapter;
  String UTime;

  /// Active book source url (Legado bookSourceUrl).
  @JsonKey(defaultValue: '')
  String sourceUrl;

  /// Book detail / info page url on the source site.
  @JsonKey(defaultValue: '')
  String bookUrl;

  /// Cached display name of the source.
  @JsonKey(defaultValue: '')
  String originName;

  /// Optional toc url override.
  @JsonKey(defaultValue: '')
  String tocUrl;

  factory Book.fromJson(Map<String, dynamic> json) => _$BookFromJson(json);

  Map<String, dynamic> toJson() => _$BookToJson(this);

  Book.Id(this.Id)
      : ChapterId = '',
        ChapterName = '',
        NewChapterCount = 0,
        CId = '',
        cur = 0,
        sortTime = 0,
        index = 0,
        position = 0,
        CName = '',
        Name = '',
        Author = '',
        Img = '',
        Desc = '',
        LastChapterId = '',
        LastChapter = '',
        UTime = '',
        sourceUrl = '',
        bookUrl = '',
        originName = '',
        tocUrl = '';

  Book.Image(this.Img)
      : ChapterId = '',
        ChapterName = '',
        NewChapterCount = 0,
        Id = '',
        CId = '',
        cur = 0,
        sortTime = 0,
        index = 0,
        position = 0,
        CName = '',
        Name = '',
        Author = '',
        Desc = '',
        LastChapterId = '',
        LastChapter = '',
        UTime = '',
        sourceUrl = '',
        bookUrl = '',
        originName = '',
        tocUrl = '';

  Book.fromSql(
      this.Id,
      this.Name,
      this.CName,
      this.Author,
      this.UTime,
      this.Img,
      this.Desc,
      this.cur,
      this.sortTime,
      this.index,
      this.position,
      this.NewChapterCount,
      this.LastChapter,
      {this.sourceUrl = '',
      this.bookUrl = '',
      this.originName = '',
      this.tocUrl = ''})
      : ChapterId = '',
        // Shelf progress label uses ChapterName first; fall back to LastChapter
        // when reading progress hasn't written ChapterName yet.
        ChapterName = LastChapter,
        CId = '',
        LastChapterId = '';

  Book(
      this.cur,
      this.sortTime,
      this.index,
      this.position,
      this.ChapterId,
      this.ChapterName,
      this.NewChapterCount,
      this.Id,
      this.CId,
      this.Name,
      this.CName,
      this.Author,
      this.Img,
      this.Desc,
      this.LastChapterId,
      this.LastChapter,
      this.UTime,
      {this.sourceUrl = '',
      this.bookUrl = '',
      this.originName = '',
      this.tocUrl = ''});
}
