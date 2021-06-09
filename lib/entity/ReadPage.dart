import 'package:book/entity/TextPage.dart';
import 'package:json_annotation/json_annotation.dart';

part 'ReadPage.g.dart';

@JsonSerializable()
class ReadPage {
  int get pageOffsets => pages?.length ?? 1;
  List<TextPage> pages;
  String chapterContent;
  double height;
  String chapterName;
  // double h;
  // double w;

  ReadPage.kong();

  ReadPage( this.chapterContent, this.chapterName,this.height, this.pages);

  factory ReadPage.fromJson(Map<String, dynamic> json) =>
      _$ReadPageFromJson(json);

  Map<String, dynamic> toJson() => _$ReadPageToJson(this);

}
