import 'package:json_annotation/json_annotation.dart';

import 'Book.dart';

part 'BookInfo.g.dart';

@JsonSerializable()
class BookInfo {
  String Author;
  String BookStatus;
  String CId;
  String CName;
  String Id;
  String Name = "";
  String Img;
  double Rate;
  int Count;
  String Desc;
  String LastChapterId;
  String LastChapter;
  String FirstChapterId;
  String LastTime;
  List<Book> SameAuthorBooks;

  factory BookInfo.fromJson(Map<String, dynamic> json) =>
      _$BookInfoFromJson(json);

  Map<String, dynamic> toJson() => _$BookInfoToJson(this);

  BookInfo.id(this.Id, this.Name, this.Img);

  BookInfo.name(this.CId, this.Name);

  BookInfo(
      this.Count,
      this.Author,
      this.BookStatus,
      this.CId,
      this.CName,
      this.Id,
      this.Name,
      this.Img,
      this.Rate,
      this.Desc,
      this.LastChapterId,
      this.LastChapter,
      this.FirstChapterId,
      this.LastTime,
      this.SameAuthorBooks);
}
