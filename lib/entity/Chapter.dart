import 'package:json_annotation/json_annotation.dart';

part 'Chapter.g.dart';

@JsonSerializable()
class Chapter {
  int hasContent = 1;
  String id;
  String name;

  factory Chapter.fromJson(Map<String, dynamic> json) =>
      _$ChapterFromJson(json);

  Map<String, dynamic> toJson() => _$ChapterToJson(this);

  Chapter(this.hasContent, this.id, this.name);
}
