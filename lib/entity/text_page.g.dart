// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'text_page.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TextPage _$TextPageFromJson(Map<String, dynamic> json) {
  return TextPage(
      (json['lines'] as List<dynamic>?)
              ?.map((e) => TextLine.fromJson(e as Map<String, dynamic>))
              .toList() ??
          <TextLine>[],
      (json['height'] as num?)?.toDouble() ?? 0);
}

Map<String, dynamic> _$TextPageToJson(TextPage instance) => <String, dynamic>{
      'lines': instance.lines,
      'height': instance.height,
    };
