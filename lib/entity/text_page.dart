import 'package:book/entity/text_line.dart';
import 'package:json_annotation/json_annotation.dart';

part 'text_page.g.dart';

@JsonSerializable()
class TextPage {
  final List<TextLine> lines;
  final double height;

  const TextPage(this.lines, this.height);
  factory TextPage.fromJson(Map<String, dynamic> json) =>
      _$TextPageFromJson(json);

  Map<String, dynamic> toJson() => _$TextPageToJson(this);
}