// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'BookInfo.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************
double td(String s) {
  if (!s.contains('.')) {
    s = s + '.0';
  }
  return double.parse(s);
}

BookInfo _$BookInfoFromJson(Map<String, dynamic> json) {
  return BookInfo(
      json['Count'] as int,
      json['Author'] as String,
      json['BookStatus'] as String,
      json['CId'] as String,
      json['CName'] as String,
      json['Id'] as String,
      json['Name'] as String,
      json['Img'] as String,
      td(json['Rate'].toString()) as double,
      json['Desc'] as String,
      json['LastChapterId'] as String,
      json['LastChapter'] as String,
      json['FirstChapterId'] as String,
      json['LastTime'] as String,
      (json['SameAuthorBooks'] as List)
          ?.map((e) =>
              e == null ? null : Book.fromJson(e as Map<String, dynamic>))
          ?.toList());
}

Map<String, dynamic> _$BookInfoToJson(BookInfo instance) => <String, dynamic>{
      'Count': instance.Count,
      'Author': instance.Author,
      'BookStatus': instance.BookStatus,
      'CId': instance.CId,
      'CName': instance.CName,
      'Id': instance.Id,
      'Name': instance.Name,
      'Rate': instance.Rate,
      'Img': instance.Img,
      'Desc': instance.Desc,
      'LastChapterId': instance.LastChapterId,
      'LastChapter': instance.LastChapter,
      'FirstChapterId': instance.FirstChapterId,
      'LastTime': instance.LastTime,
      'SameAuthorBooks': instance.SameAuthorBooks
    };
