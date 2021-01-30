// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'VoiceModelEntity.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VoiceModelEntity _$VoiceModelEntityFromJson(Map<String, dynamic> json) {
  return VoiceModelEntity(
      json['cover'] as String, json['link'] as String, json['idx'] as int, json['fast'] as double);
}

Map<String, dynamic> _$VoiceModelEntityToJson(VoiceModelEntity instance) =>
    <String, dynamic>{
      'cover': instance.cover,
      'link': instance.link,
      'idx': instance.idx,
      'fast': instance.fast
    };
