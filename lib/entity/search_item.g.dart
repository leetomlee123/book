// GENERATED CODE - DO NOT MODIFY BY HAND
// Hand-maintained camelCase fields (no legacy key compat).

part of 'search_item.dart';

SearchItem _$SearchItemFromJson(Map<String, dynamic> json) {
  return SearchItem(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    author: json['author'] as String? ?? '',
    coverUrl: json['coverUrl'] as String? ?? '',
    description: json['description'] as String? ?? '',
    status: json['status'] as String? ?? '',
    latestChapter: json['latestChapter'] as String? ?? '',
    category: json['category'] as String? ?? '',
    updatedAt: json['updatedAt'] as String? ?? '',
    sourceUrl: json['sourceUrl'] as String? ?? '',
    bookUrl: json['bookUrl'] as String? ?? '',
    sourceName: json['sourceName'] as String? ?? '',
  );
}

Map<String, dynamic> _$SearchItemToJson(SearchItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'author': instance.author,
      'coverUrl': instance.coverUrl,
      'description': instance.description,
      'status': instance.status,
      'latestChapter': instance.latestChapter,
      'category': instance.category,
      'updatedAt': instance.updatedAt,
      'sourceUrl': instance.sourceUrl,
      'bookUrl': instance.bookUrl,
      'sourceName': instance.sourceName,
    };
