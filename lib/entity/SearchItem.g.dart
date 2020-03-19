// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'SearchItem.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SearchItem _$SearchItemFromJson(Map<String, dynamic> json) {
  return SearchItem(
      json['Id'] as String,
      json['Name'] as String,
      json['Author'] as String,
      json['Img'] as String,
      json['Desc'] as String,
      json['BookStatus'] as String,
      json['LastChapterId'] as String,
      json['LastChapter'] as String,
      json['CName'] as String,
      json['UpdateTime'] as String);
}

Map<String, dynamic> _$SearchItemToJson(SearchItem instance) =>
    <String, dynamic>{
      'Id': instance.Id,
      'Name': instance.Name,
      'Author': instance.Author,
      'Img': instance.Img,
      'Desc': instance.Desc,
      'BookStatus': instance.BookStatus,
      'LastChapterId': instance.LastChapterId,
      'LastChapter': instance.LastChapter,
      'CName': instance.CName,
      'UpdateTime': instance.UpdateTime
    };
