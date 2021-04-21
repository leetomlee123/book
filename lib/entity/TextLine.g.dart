// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'TextLine.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TextLine _$TextLineFromJson(Map<String, dynamic> json) {
  return TextLine(
      json['text'] as String,
      json['dx'] ,
      json['dy'] ,
      json['letterSpacing'] as double);

}

Map<String, dynamic> _$TextLineToJson(TextLine instance) =>
    <String, dynamic>{
      'text': instance.text,
      'dx': instance.dx,
      'dy': instance.dy,
      'letterSpacing': instance.letterSpacing,

    };
