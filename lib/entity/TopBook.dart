import 'package:json_annotation/json_annotation.dart';

part 'TopBook.g.dart';

@JsonSerializable()
class TopBooks {
  int Id;
  String Name;
  String Author;
  String Img;
  String Desc;
  String CName;
  double Score;

  TopBooks(this.Id, this.Name, this.Author, this.Img, this.Desc, this.CName,
      this.Score);
  factory TopBooks.fromJson(Map<String, dynamic> json) =>
      _$TopBooksFromJson(json);

  Map<String, dynamic> toJson() => _$TopBooksToJson(this);
}
