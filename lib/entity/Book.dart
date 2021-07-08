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

  factory Book.fromJson(Map<String, dynamic> json) => _$BookFromJson(json);

  Map<String, dynamic> toJson() => _$BookToJson(this);

  Book.Id(this.Id);
  Book.Image(this.Img);



  Book.fromSql(this.Id, this.Name, this.CName, this.Author, this.UTime,
      this.Img,this.Desc, this.cur, this.sortTime,this.index,this.position, this.NewChapterCount, this.LastChapter);

  Book(
    this.cur,this.sortTime,this.index,this.position,
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
      this.UTime);
}
