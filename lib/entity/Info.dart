import 'package:json_annotation/json_annotation.dart';

part 'Info.g.dart';

@JsonSerializable()
class Info {
  String Title;
  String Date;
  String Content;

  Info(this.Title, this.Date, this.Content);

  factory Info.fromJson(Map<String, dynamic> json) => _$InfoFromJson(json);

  Map<String, dynamic> toJson() => _$InfoToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is Info &&
              runtimeType == other.runtimeType &&
              Title == other.Title &&
              Date == other.Date &&
              Content == other.Content;

  @override
  int get hashCode =>
      Title.hashCode ^
      Date.hashCode ^
      Content.hashCode;


}
