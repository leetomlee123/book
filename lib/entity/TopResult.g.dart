// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'TopResult.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TopResult _$TopResultFromJson(Map<String, dynamic> json) {
  return TopResult(
      (json['BookList'] as List)
          ?.map((e) =>
              e == null ? null : TopBooks.fromJson(e as Map<String, dynamic>))
          ?.toList(),
      json['Page'] as int,
      json['HasNext'] as bool);
}

Map<String, dynamic> _$TopResultToJson(TopResult instance) => <String, dynamic>{
      'BookList': instance.BookList,
      'Page': instance.Page,
      'HasNext': instance.HasNext
    };
