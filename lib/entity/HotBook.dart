import 'package:json_annotation/json_annotation.dart';

part 'HotBook.g.dart';

@JsonSerializable()
class HotBook {
  String Id;
  String Name;
  int Hot;

  HotBook(this.Id, this.Name, this.Hot);
  factory HotBook.fromJson(Map<String, dynamic> json) =>
      _$HotBookFromJson(json);

  Map<String, dynamic> toJson() => _$HotBookToJson(this);
}
