import 'package:json_annotation/json_annotation.dart';

part 'VoiceModelEntity.g.dart';

@JsonSerializable()
class VoiceModelEntity {
  String cover;
  String link;
  int idx;
  double fast;

  VoiceModelEntity(this.cover, this.link, this.idx,this.fast);

  factory VoiceModelEntity.fromJson(Map<String, dynamic> json) =>
      _$VoiceModelEntityFromJson(json);

  Map<String, dynamic> toJson() => _$VoiceModelEntityToJson(this);
}
