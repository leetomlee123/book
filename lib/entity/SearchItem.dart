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

  @JsonKey(defaultValue: '')
  String sourceUrl;
  @JsonKey(defaultValue: '')
  String bookUrl;
  @JsonKey(defaultValue: '')
  String sourceName;

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
    this.UpdateTime, {
    this.sourceUrl = '',
    this.bookUrl = '',
    this.sourceName = '',
  });

  factory SearchItem.fromJson(Map<String, dynamic> json) =>
      _$SearchItemFromJson(json);

  Map<String, dynamic> toJson() => _$SearchItemToJson(this);
}
