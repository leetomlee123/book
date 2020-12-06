import 'package:book/entity/VoiceOV.dart';
import 'package:json_annotation/json_annotation.dart';

part 'VoiceIdx.g.dart';

@JsonSerializable()
class VoiceIdx {
  String cate;
  String link;
  List<VoiceOV> voices;
  VoiceIdx(this.cate, this.link, this.voices);
  factory VoiceIdx.fromJson(Map<String, dynamic> json) =>
      _$VoiceIdxFromJson(json);

  Map<String, dynamic> toJson() => _$VoiceIdxToJson(this);
}
