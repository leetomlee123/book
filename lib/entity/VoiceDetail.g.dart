// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'VoiceDetail.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

VoiceDetail _$VoiceDetailFromJson(Map<String, dynamic> json) {
  return VoiceDetail(
      json['author'] as String,
      json['bookDesc'] as String,
      (json['chapters'] as List)
          ?.map((e) =>
              e == null ? null : DetailVO.fromJson(e as Map<String, dynamic>))
          ?.toList(),
      json['title'] as String,
      json['cover'] as String);
}

Map<String, dynamic> _$VoiceDetailToJson(VoiceDetail instance) =>
    <String, dynamic>{
      'author': instance.author,
      'bookDesc': instance.bookDesc,
      'cover': instance.cover,
      'chapters': instance.chapters,
      'title': instance.title
    };
