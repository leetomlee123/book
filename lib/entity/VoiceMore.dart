import 'package:json_annotation/json_annotation.dart';

part 'VoiceMore.g.dart';

@JsonSerializable()
class VoiceMore {
  String date;
  String href;
  String title;
  VoiceMore(this.date, this.href,this.title);
  factory VoiceMore.fromJson(Map<String, dynamic> json) =>
      _$VoiceMoreFromJson(json);

  Map<String, dynamic> toJson() => _$VoiceMoreToJson(this);
}