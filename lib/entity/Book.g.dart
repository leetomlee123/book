// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'Book.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Book _$BookFromJson(Map<String, dynamic> json) {
  return Book(
      json['ChapterId'] as String,
      json['ChapterName'] as String,
      json['NewChapterCount'] as int,
      json['Id'] as String,
      json['Name'] as String,
      json['Author'] as String,
      json['Img'] as String,
      json['LastChapterId'] as String,
      json['LastChapter'] as String,
      json['UTime'] as String);
}

Map<String, dynamic> _$BookToJson(Book instance) => <String, dynamic>{
      'ChapterId': instance.ChapterId,
      'ChapterName': instance.ChapterName,
      'NewChapterCount': instance.NewChapterCount,
      'Id': instance.Id,
      'Name': instance.Name,
      'Author': instance.Author,
      'Img': instance.Img,
      'LastChapterId': instance.LastChapterId,
      'LastChapter': instance.LastChapter,
      'UTime': instance.UTime
    };
