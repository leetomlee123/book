// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'GBook.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

GBook _$GBookFromJson(Map<String, dynamic> json) {
  return GBook(
    json['cover'] as String,
    json['name'] as String,
    json['author'] as String,
    json['id'] as String,
  );
}

Map<String, dynamic> _$GBookToJson(GBook instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'author': instance.author,
      'cover': instance.cover,
    };
