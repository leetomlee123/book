// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'Info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Info _$InfoFromJson(Map<String, dynamic> json) {
  return Info(
    json['Title'] as String,
    json['Date'] as String,
    json['Content'] as String,
  );
}

Map<String, dynamic> _$InfoToJson(Info instance) => <String, dynamic>{
      'Date': instance.Date,
      'Title': instance.Title,
      'Content': instance.Content,
    };
