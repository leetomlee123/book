// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ReadPage.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ReadPage _$ReadPageFromJson(Map<String, dynamic> json) {
  return ReadPage(
      json['chapterContent'] as String? ?? '',
      json['chapterName'] as String? ?? '',
      (json['height'] as num?)?.toDouble() ?? 0,
      (json['pages'] as List<dynamic>?)
              ?.map((e) => TextPage.fromJson(e as Map<String, dynamic>))
              .toList() ??
          <TextPage>[]);
}

Map<String, dynamic> _$ReadPageToJson(ReadPage instance) => <String, dynamic>{
      'chapterContent': instance.chapterContent,
      'chapterName': instance.chapterName,
      'height': instance.height,
      'pages': instance.pages
    };
