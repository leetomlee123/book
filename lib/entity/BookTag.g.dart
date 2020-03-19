// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'BookTag.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BookTag _$BookTagFromJson(Map<String, dynamic> json) {
  return BookTag(
      json['cur'] as int,
      json['index'] as int,
      json['bookName'] as String,
      (json['chapters'] as List)
          ?.map((e) =>
              e == null ? null : Chapter.fromJson(e as Map<String, dynamic>))
          ?.toList());
}

Map<String, dynamic> _$BookTagToJson(BookTag instance) => <String, dynamic>{
      'cur': instance.cur,
      'index': instance.index,
      'bookName': instance.bookName,
      'chapters': instance.chapters
    };
