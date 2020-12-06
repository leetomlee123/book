import 'package:json_annotation/json_annotation.dart';

part 'VoiceOV.g.dart';

@JsonSerializable()
class VoiceOV {
  String date;
  String link;
  String name;
  VoiceOV(this.date, this.link, this.name);
    factory VoiceOV.fromJson(Map<String, dynamic> json) =>
      _$VoiceOVFromJson(json);

  Map<String, dynamic> toJson() => _$VoiceOVToJson(this);
}
