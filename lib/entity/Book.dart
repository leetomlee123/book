import 'package:json_annotation/json_annotation.dart';

part 'Book.g.dart';

/// Local shelf / reading-session book row.
@JsonSerializable()
class Book {
  String id;
  String name;
  String author;
  String coverUrl;
  String category;
  String description;

  /// Chapter currently being read (display title).
  String readingChapter;

  /// Newest chapter title known for the book.
  String latestChapter;

  int chapterIndex;
  int pageIndex;
  double scrollOffset;
  int sortTime;

  /// Non-zero means shelf shows update badge.
  int hasUpdate;

  String updatedAt;

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

  Book({
    this.id = '',
    this.name = '',
    this.author = '',
    this.coverUrl = '',
    this.category = '',
    this.description = '',
    this.readingChapter = '',
    this.latestChapter = '',
    this.chapterIndex = 0,
    this.pageIndex = 0,
    this.scrollOffset = 0,
    this.sortTime = 0,
    this.hasUpdate = 0,
    this.updatedAt = '',
    this.sourceUrl = '',
    this.bookUrl = '',
    this.originName = '',
    this.tocUrl = '',
  });

  Book.id(this.id)
      : name = '',
        author = '',
        coverUrl = '',
        category = '',
        description = '',
        readingChapter = '',
        latestChapter = '',
        chapterIndex = 0,
        pageIndex = 0,
        scrollOffset = 0,
        sortTime = 0,
        hasUpdate = 0,
        updatedAt = '',
        sourceUrl = '',
        bookUrl = '',
        originName = '',
        tocUrl = '';

  Book.cover(this.coverUrl)
      : id = '',
        name = '',
        author = '',
        category = '',
        description = '',
        readingChapter = '',
        latestChapter = '',
        chapterIndex = 0,
        pageIndex = 0,
        scrollOffset = 0,
        sortTime = 0,
        hasUpdate = 0,
        updatedAt = '',
        sourceUrl = '',
        bookUrl = '',
        originName = '',
        tocUrl = '';
}
