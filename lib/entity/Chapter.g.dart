// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'Chapter.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Chapter _$ChapterFromJson(Map<String, dynamic> json) {
  return Chapter(
      json['hasContent'] as int? ?? 1,
      json['id'] as String? ?? '',
      json['name'] as String? ?? '',
      link: json['link'] as String? ?? '');
}

Map<String, dynamic> _$ChapterToJson(Chapter instance) => <String, dynamic>{
      'hasContent': instance.hasContent,
      'id': instance.id,
      'name': instance.name,
      'link': instance.link
    };
