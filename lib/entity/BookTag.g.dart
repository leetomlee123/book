// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'BookTag.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BookTag _$BookTagFromJson(Map<String, dynamic> json) {
  return BookTag(
      json['cur'] as int? ?? 0,
      json['index'] as int? ?? 0,
      json['bookName'] as String? ?? '',
      (json['offset'] as num?)?.toDouble() ?? 0);
}

Map<String, dynamic> _$BookTagToJson(BookTag instance) => <String, dynamic>{
      'cur': instance.cur,
      'index': instance.index,
      'bookName': instance.bookName,
      'offset': instance.offset
    };
