import 'package:book/entity/text_page.dart';
import 'package:json_annotation/json_annotation.dart';

part 'read_page.g.dart';

@JsonSerializable()
class ReadPage {
  int get pageOffsets => pages.length;
  List<TextPage> pages;
  String chapterContent;
  double height;
  String chapterName;

  ReadPage.kong()
      : pages = const [],
        chapterContent = '',
        height = 0,
        chapterName = '';

  ReadPage(this.chapterContent, this.chapterName, this.height, this.pages);

  factory ReadPage.fromJson(Map<String, dynamic> json) =>
      _$ReadPageFromJson(json);

  Map<String, dynamic> toJson() => _$ReadPageToJson(this);
}
