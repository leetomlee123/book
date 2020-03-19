// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'TopBook.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

TopBooks _$TopBooksFromJson(Map<String, dynamic> json) {
  return TopBooks(
      json['Id'] as int,
      json['Name'] as String,
      json['Author'] as String,
      json['Img'] as String,
      json['Desc'] as String,
      json['CName'] as String,
      (json['Score'] as num)?.toDouble());
}

Map<String, dynamic> _$TopBooksToJson(TopBooks instance) => <String, dynamic>{
      'Id': instance.Id,
      'Name': instance.Name,
      'Author': instance.Author,
      'Img': instance.Img,
      'Desc': instance.Desc,
      'CName': instance.CName,
      'Score': instance.Score
    };
