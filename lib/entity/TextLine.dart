import 'package:json_annotation/json_annotation.dart';

part 'TextLine.g.dart';

@JsonSerializable()
class TextLine {
  final String text;
  double dx;
  double dy;

  double letterSpacing;

  TextLine(this.text, this.dx, this.dy, this.letterSpacing );

  factory TextLine.fromJson(Map<String, dynamic> json) =>
      _$TextLineFromJson(json);

  Map<String, dynamic> toJson() => _$TextLineToJson(this);

  justifyDy(double offsetDy) {
    dy += offsetDy;
  }
}
