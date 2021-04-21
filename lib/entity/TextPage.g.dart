// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'TextPage.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TextPage _$TextPageFromJson(Map<String, dynamic> json) {
  return TextPage(
      (json['lines'] as List)
          ?.map((e) =>
              e == null ? null : TextLine.fromJson(e as Map<String, dynamic>))
          ?.toList(),
      json['height'] as double);
}

Map<String, dynamic> _$TextPageToJson(TextPage instance) => <String, dynamic>{
      'lines': instance.lines,
      'height': instance.height,
    };
