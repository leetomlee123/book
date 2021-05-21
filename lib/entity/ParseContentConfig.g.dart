// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ParseContentConfig.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ParseContentConfig _$ParseContentConfigFromJson(Map<String, dynamic> json) {
  return ParseContentConfig(json['domain'] as String, json['encode'] as String,
      json['documentId'] as String);
}

Map<String, dynamic> _$ParseContentConfigToJson(ParseContentConfig instance) => <String, dynamic>{
      'domain': instance.domain,
      'encode': instance.encode,
      'documentId': instance.documentId
    };
