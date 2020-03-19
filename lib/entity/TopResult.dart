import 'package:book/entity/TopBook.dart';
import 'package:json_annotation/json_annotation.dart';

part 'TopResult.g.dart';

@JsonSerializable()
class TopResult {
  List<TopBooks> BookList;
  int Page;
  bool HasNext;

  TopResult(this.BookList, this.Page, this.HasNext);

  factory TopResult.fromJson(Map<String, dynamic> json) =>
      _$TopResultFromJson(json);

  Map<String, dynamic> toJson() => _$TopResultToJson(this);
}
