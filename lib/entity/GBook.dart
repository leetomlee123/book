import 'package:json_annotation/json_annotation.dart';

part 'GBook.g.dart';

@JsonSerializable()
class GBook {
  String cover;
  String name;
  String id;


  GBook(this.cover, this.name, this.id);

  factory GBook.fromJson(Map<String, dynamic> json) =>
      _$GBookFromJson(json);

  Map<String, dynamic> toJson() => _$GBookToJson(this);
}
