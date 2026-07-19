// GENERATED CODE - DO NOT MODIFY BY HAND
// Hand-maintained camelCase fields (no legacy key compat).

part of 'BookInfo.dart';

BookInfo _$BookInfoFromJson(Map<String, dynamic> json) {
  return BookInfo(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    author: json['author'] as String? ?? '',
    coverUrl: json['coverUrl'] as String? ?? '',
    category: json['category'] as String? ?? '',
    description: json['description'] as String? ?? '',
    status: json['status'] as String? ?? '',
    latestChapter: json['latestChapter'] as String? ?? '',
    updatedAt: json['updatedAt'] as String? ?? '',
    rating: (json['rating'] as num?)?.toDouble() ?? 0,
    ratingCount: json['ratingCount'] as int? ?? 0,
    relatedBooks: (json['relatedBooks'] as List<dynamic>?)
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
      'id': instance.id,
      'name': instance.name,
      'author': instance.author,
      'coverUrl': instance.coverUrl,
      'category': instance.category,
      'description': instance.description,
      'status': instance.status,
      'latestChapter': instance.latestChapter,
      'updatedAt': instance.updatedAt,
      'rating': instance.rating,
      'ratingCount': instance.ratingCount,
      'relatedBooks': instance.relatedBooks,
      'sourceUrl': instance.sourceUrl,
      'bookUrl': instance.bookUrl,
      'originName': instance.originName,
      'tocUrl': instance.tocUrl,
    };
