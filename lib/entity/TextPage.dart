import 'package:book/entity/TextLine.dart';
import 'package:json_annotation/json_annotation.dart';

part 'TextPage.g.dart';

@JsonSerializable()
class TextPage {
  final List<TextLine> lines;
  final double height;

  const TextPage(this.lines, this.height);
  factory TextPage.fromJson(Map<String, dynamic> json) =>
      _$TextPageFromJson(json);

  Map<String, dynamic> toJson() => _$TextPageToJson(this);
}