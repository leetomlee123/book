// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'HotBook.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HotBook _$HotBookFromJson(Map<String, dynamic> json) {
  return HotBook(json['Id'] as String? ?? '', json['Name'] as String? ?? '',
      json['Hot'] as int? ?? 0);
}

Map<String, dynamic> _$HotBookToJson(HotBook instance) => <String, dynamic>{
      'Id': instance.Id,
      'Name': instance.Name,
      'Hot': instance.Hot
    };
