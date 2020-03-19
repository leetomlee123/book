// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ChapterList.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ChapterList _$ChapterListFromJson(Map<String, dynamic> json) {
  return ChapterList(
      json['name'] as String,
      (json['list'] as List)
          ?.map((e) =>
              e == null ? null : Chapter.fromJson(e as Map<String, dynamic>))
          ?.toList());
}

Map<String, dynamic> _$ChapterListToJson(ChapterList instance) =>
    <String, dynamic>{'name': instance.name, 'list': instance.list};
