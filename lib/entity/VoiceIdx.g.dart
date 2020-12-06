// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'VoiceIdx.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VoiceIdx _$VoiceIdxFromJson(Map<String, dynamic> json) {
  return VoiceIdx(
      json['cate'] as String,
      json['link'] as String,
      (json['voices'] as List)
          ?.map((e) =>
              e == null ? null : VoiceOV.fromJson(e as Map<String, dynamic>))
          ?.toList());
}

Map<String, dynamic> _$VoiceIdxToJson(VoiceIdx instance) => <String, dynamic>{
      'cate': instance.cate,
      'link': instance.link,
      'voices': instance.voices
    };
