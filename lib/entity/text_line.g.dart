// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'text_line.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TextLine _$TextLineFromJson(Map<String, dynamic> json) {
  return TextLine(
      json['text'] as String? ?? '',
      (json['dx'] as num?)?.toDouble() ?? 0,
      (json['dy'] as num?)?.toDouble() ?? 0,
      (json['letterSpacing'] as num?)?.toDouble() ?? 0);
}

Map<String, dynamic> _$TextLineToJson(TextLine instance) => <String, dynamic>{
      'text': instance.text,
      'dx': instance.dx,
      'dy': instance.dy,
      'letterSpacing': instance.letterSpacing,
    };
