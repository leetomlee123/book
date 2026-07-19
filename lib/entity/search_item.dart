import 'package:json_annotation/json_annotation.dart';

part 'search_item.g.dart';

/// Search / explore list row (local book-source hit).
@JsonSerializable()
class SearchItem {
  String id;
  String name;
  String author;
  String coverUrl;
  String description;
  String status;
  String latestChapter;
  String category;
  String updatedAt;

  @JsonKey(defaultValue: '')
  String sourceUrl;
  @JsonKey(defaultValue: '')
  String bookUrl;
  @JsonKey(defaultValue: '')
  String sourceName;

  SearchItem({
    this.id = '',
    this.name = '',
    this.author = '',
    this.coverUrl = '',
    this.description = '',
    this.status = '',
    this.latestChapter = '',
    this.category = '',
    this.updatedAt = '',
    this.sourceUrl = '',
    this.bookUrl = '',
    this.sourceName = '',
  });

  factory SearchItem.fromJson(Map<String, dynamic> json) =>
      _$SearchItemFromJson(json);

  Map<String, dynamic> toJson() => _$SearchItemToJson(this);
}
