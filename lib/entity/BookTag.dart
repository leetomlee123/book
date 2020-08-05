import 'package:book/entity/Chapter.dart';
import 'package:json_annotation/json_annotation.dart';

part 'BookTag.g.dart';

@JsonSerializable()
class BookTag {
  int cur;
  int index;
  String bookName;


  factory BookTag.fromJson(Map<String, dynamic> json) =>
      _$BookTagFromJson(json);

  Map<String, dynamic> toJson() => _$BookTagToJson(this);

  BookTag(this.cur, this.index,  this.bookName);


}
