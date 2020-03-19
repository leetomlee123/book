import 'package:json_annotation/json_annotation.dart';

part 'SearchItem.g.dart';

@JsonSerializable()
class SearchItem {
  String Id;
  String Name;
  String Author;
  String Img;
  String Desc;
  String BookStatus;
  String LastChapterId;
  String LastChapter;
  String CName;
  String UpdateTime;

  SearchItem(
      this.Id,
      this.Name,
      this.Author,
      this.Img,
      this.Desc,
      this.BookStatus,
      this.LastChapterId,
      this.LastChapter,
      this.CName,
      this.UpdateTime);

  factory SearchItem.fromJson(Map<String, dynamic> json) =>
      _$SearchItemFromJson(json);

  Map<String, dynamic> toJson() => _$SearchItemToJson(this);
}
