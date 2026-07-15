// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'TopResult.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TopResult _$TopResultFromJson(Map<String, dynamic> json) {
  return TopResult(
      (json['BookList'] as List<dynamic>?)
              ?.map((e) => TopBooks.fromJson(e as Map<String, dynamic>))
              .toList() ??
          <TopBooks>[],
      json['Page'] as int? ?? 0,
      json['HasNext'] as bool? ?? false);
}

Map<String, dynamic> _$TopResultToJson(TopResult instance) => <String, dynamic>{
      'BookList': instance.BookList,
      'Page': instance.Page,
      'HasNext': instance.HasNext
    };
