// GENERATED CODE - DO NOT MODIFY BY HAND
// Hand-maintained for source fields.

part of 'BookInfo.dart';

BookInfo _$BookInfoFromJson(Map<String, dynamic> json) {
  return BookInfo(
    json['Count'] as int? ?? 0,
    json['Author'] as String? ?? '',
    json['BookStatus'] as String? ?? '',
    json['CId'] as String? ?? '',
    json['CName'] as String? ?? '',
    json['Id'] as String? ?? '',
    json['Name'] as String? ?? '',
    json['Img'] as String? ?? '',
    (json['Rate'] as num?)?.toDouble() ?? 0,
    json['Desc'] as String? ?? '',
    json['LastChapterId'] as String? ?? '',
    json['LastChapter'] as String? ?? '',
    json['FirstChapterId'] as String? ?? '',
    json['LastTime'] as String? ?? '',
    (json['SameAuthorBooks'] as List<dynamic>?)
            ?.map((e) => Book.fromJson(e as Map<String, dynamic>))
            .toList() ??
        <Book>[],
    sourceUrl: json['sourceUrl'] as String? ?? '',
    bookUrl: json['bookUrl'] as String? ?? '',
    originName: json['originName'] as String? ?? '',
    tocUrl: json['tocUrl'] as String? ?? '',
  );
}

Map<String, dynamic> _$BookInfoToJson(BookInfo instance) => <String, dynamic>{
      'Author': instance.Author,
      'BookStatus': instance.BookStatus,
      'CId': instance.CId,
      'CName': instance.CName,
      'Id': instance.Id,
      'Name': instance.Name,
      'Img': instance.Img,
      'Rate': instance.Rate,
      'Count': instance.Count,
      'Desc': instance.Desc,
      'LastChapterId': instance.LastChapterId,
      'LastChapter': instance.LastChapter,
      'FirstChapterId': instance.FirstChapterId,
      'LastTime': instance.LastTime,
      'SameAuthorBooks': instance.SameAuthorBooks,
      'sourceUrl': instance.sourceUrl,
      'bookUrl': instance.bookUrl,
      'originName': instance.originName,
      'tocUrl': instance.tocUrl,
    };
