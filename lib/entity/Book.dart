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

  @override
  String toString() {
    return 'Book{ChapterId: $ChapterId, ChapterName: $ChapterName, NewChapterCount: $NewChapterCount, Id: $Id, CId: $CId, cur: $cur, index: $index, CName: $CName, Name: $Name, Author: $Author, Img: $Img, LastChapterId: $LastChapterId, LastChapter: $LastChapter, UTime: $UTime}';
  }

  Book.fromSql(this.Id, this.Name, this.CName, this.Author, this.UTime,
      this.Img, this.cur, this.index, this.NewChapterCount, this.LastChapter);

  Book(
      this.ChapterId,
      this.ChapterName,
      this.NewChapterCount,
      this.Id,
      this.CId,
      this.Name,
      this.CName,
      this.Author,
      this.Img,
      this.LastChapterId,
      this.LastChapter,
      this.UTime);
}
