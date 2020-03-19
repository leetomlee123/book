import 'package:json_annotation/json_annotation.dart';

part 'Book.g.dart';

@JsonSerializable()
class Book {
  String ChapterId;
  String ChapterName;
  int NewChapterCount;
  String Id;
  String Name;
  String Author;
  String Img;
  String LastChapterId;
  String LastChapter;
  String UTime;

  factory Book.fromJson(Map<String, dynamic> json) => _$BookFromJson(json);

  Map<String, dynamic> toJson() => _$BookToJson(this);

  Book.Id(this.Id);

  Book(
      this.ChapterId,
      this.ChapterName,
      this.NewChapterCount,
      this.Id,
      this.Name,
      this.Author,
      this.Img,
      this.LastChapterId,
      this.LastChapter,
      this.UTime);
}
