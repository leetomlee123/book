import 'package:json_annotation/json_annotation.dart';

part 'Update.g.dart';

@JsonSerializable()
class Update {
  String version;
  String msg;
  String link;

  factory Update.fromJson(Map<String, dynamic> json) => _$UpdateFromJson(json);

  Map<String, dynamic> toJson() => _$UpdateToJson(this);

  Update(this.version, this.msg, this.link);
}
