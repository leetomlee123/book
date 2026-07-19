// GENERATED CODE - DO NOT MODIFY BY HAND
// Hand-maintained camelCase fields (no legacy key compat).

part of 'Book.dart';

Book _$BookFromJson(Map<String, dynamic> json) {
  return Book(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    author: json['author'] as String? ?? '',
    coverUrl: json['coverUrl'] as String? ?? '',
    category: json['category'] as String? ?? '',
    description: json['description'] as String? ?? '',
    readingChapter: json['readingChapter'] as String? ?? '',
    latestChapter: json['latestChapter'] as String? ?? '',
    chapterIndex: json['chapterIndex'] as int? ?? 0,
    pageIndex: json['pageIndex'] as int? ?? 0,
    scrollOffset: (json['scrollOffset'] as num?)?.toDouble() ?? 0,
    sortTime: json['sortTime'] as int? ?? 0,
    hasUpdate: json['hasUpdate'] as int? ?? 0,
    updatedAt: json['updatedAt'] as String? ?? '',
    sourceUrl: json['sourceUrl'] as String? ?? '',
    bookUrl: json['bookUrl'] as String? ?? '',
    originName: json['originName'] as String? ?? '',
    tocUrl: json['tocUrl'] as String? ?? '',
  );
}

Map<String, dynamic> _$BookToJson(Book instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'author': instance.author,
      'coverUrl': instance.coverUrl,
      'category': instance.category,
      'description': instance.description,
      'readingChapter': instance.readingChapter,
      'latestChapter': instance.latestChapter,
      'chapterIndex': instance.chapterIndex,
      'pageIndex': instance.pageIndex,
      'scrollOffset': instance.scrollOffset,
      'sortTime': instance.sortTime,
      'hasUpdate': instance.hasUpdate,
      'updatedAt': instance.updatedAt,
      'sourceUrl': instance.sourceUrl,
      'bookUrl': instance.bookUrl,
      'originName': instance.originName,
      'tocUrl': instance.tocUrl,
    };
