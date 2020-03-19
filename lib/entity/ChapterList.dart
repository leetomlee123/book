import 'package:book/entity/Chapter.dart';
import 'package:json_annotation/json_annotation.dart';

part 'ChapterList.g.dart';

@JsonSerializable()
class ChapterList {
  String name;
  List<Chapter> list;

  ChapterList(this.name, this.list);

  factory ChapterList.fromJson(Map<String, dynamic> json) =>
      _$ChapterListFromJson(json);

  Map<String, dynamic> toJson() => _$ChapterListToJson(this);
}
