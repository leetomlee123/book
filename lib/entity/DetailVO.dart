import 'package:json_annotation/json_annotation.dart';

part 'DetailVO.g.dart';

@JsonSerializable()
class DetailVO {
  String link;
  String name;
  DetailVO(this.link, this.name);
  factory DetailVO.fromJson(Map<String, dynamic> json) =>
      _$DetailVOFromJson(json);

  Map<String, dynamic> toJson() => _$DetailVOToJson(this);
}
