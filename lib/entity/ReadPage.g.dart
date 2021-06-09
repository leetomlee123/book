// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ReadPage.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReadPage _$ReadPageFromJson(Map<String, dynamic> json) {
  return ReadPage(
      json['chapterContent'] as String,
      json['chapterName'] as String,
      json['height'] as double,
      // json['h'] as double,
      // json['w'] as double,
      (json['pages'] as List)
          ?.map((e) =>
              e == null ? null : TextPage.fromJson(e as Map<String, dynamic>))
          ?.toList());
}

Map<String, dynamic> _$ReadPageToJson(ReadPage instance) => <String, dynamic>{
      'chapterContent': instance.chapterContent,
      'chapterName': instance.chapterName,
      'height': instance.height,
      // 'h': instance.h,
      // 'w': instance.w,
      'pages': instance.pages
    };
