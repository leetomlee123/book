// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'Update.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Update _$UpdateFromJson(Map<String, dynamic> json) {
  return Update(
      json['version'] as String, json['msg'] as String, json['link'] as String);
}

Map<String, dynamic> _$UpdateToJson(Update instance) => <String, dynamic>{
      'version': instance.version,
      'msg': instance.msg,
      'link': instance.link
    };
