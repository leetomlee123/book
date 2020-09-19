import 'package:json_annotation/json_annotation.dart';

part 'Book.g.dart';

@JsonSerializable()
class Book {
  String ChapterId;
  String ChapterName;
  int NewChapterCount;
  String Id;
  int cur;
  int index;
  String CName;
  String Name;
  String Author;
  String Img;
  String LastChapterId;
  String LastChapter;
  String UTime;

  factory Book.fromJson(Map<String, dynamic> json) => _$BookFromJson(json);

  Map<String, dynamic> toJson() => _$BookToJson(this);

  Book.Id(this.Id);


  Book.fromSql(this.Id, this.Name, this.CName, this.Author, this.UTime,
      this.Img, this.cur, this.index, this.NewChapterCount, this.LastChapter);

  Book(
      this.ChapterId,
      this.ChapterName,
      this.NewChapterCount,
      this.Id,
      this.Name,
      this.CName,
      this.Author,
      this.Img,
      this.LastChapterId,
      this.LastChapter,
      this.UTime);
}
