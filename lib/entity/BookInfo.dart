import 'package:json_annotation/json_annotation.dart';

import 'Book.dart';

part 'BookInfo.g.dart';

/// Detail-page / search-hit book metadata.
@JsonSerializable()
class BookInfo {
  String id;
  String name;
  String author;
  String coverUrl;
  String category;
  String description;
  String status;
  String latestChapter;
  String updatedAt;
  double rating;
  int ratingCount;
  List<Book> relatedBooks;

  @JsonKey(defaultValue: '')
  String sourceUrl;
  @JsonKey(defaultValue: '')
  String bookUrl;
  @JsonKey(defaultValue: '')
  String originName;
  @JsonKey(defaultValue: '')
  String tocUrl;

  factory BookInfo.fromJson(Map<String, dynamic> json) =>
      _$BookInfoFromJson(json);

  Map<String, dynamic> toJson() => _$BookInfoToJson(this);

  BookInfo({
    this.id = '',
    this.name = '',
    this.author = '',
    this.coverUrl = '',
    this.category = '',
    this.description = '',
    this.status = '',
    this.latestChapter = '',
    this.updatedAt = '',
    this.rating = 0,
    this.ratingCount = 0,
    this.relatedBooks = const [],
    this.sourceUrl = '',
    this.bookUrl = '',
    this.originName = '',
    this.tocUrl = '',
  });

  BookInfo.id(this.id, this.name, this.coverUrl)
      : author = '',
        category = '',
        description = '',
        status = '',
        latestChapter = '',
        updatedAt = '',
        rating = 0,
        ratingCount = 0,
        relatedBooks = const [],
        sourceUrl = '',
        bookUrl = '',
        originName = '',
        tocUrl = '';

  Book toBook() {
    return Book(
      id: id,
      name: name,
      author: author,
      coverUrl: coverUrl,
      category: category,
      description: description,
      latestChapter: latestChapter,
      updatedAt: updatedAt,
      sourceUrl: sourceUrl,
      bookUrl: bookUrl,
      originName: originName,
      tocUrl: tocUrl,
    );
  }
}
