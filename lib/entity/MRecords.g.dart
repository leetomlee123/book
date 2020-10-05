// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'MRecords.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

MRecords _$MRecordsFromJson(Map<String, dynamic> json) {
  return MRecords(json['cover'] as String, json['name'] as String,
      json['cid'] as String, json['cname'] as String, json['mcids'] as String);
}

Map<String, dynamic> _$MRecordsToJson(MRecords instance) => <String, dynamic>{
      'cover': instance.cover,
      'name': instance.name,
      'cid': instance.cid,
      'cname': instance.cname,
      'mcids': instance.mcids
    };
