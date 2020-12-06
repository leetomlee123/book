import 'package:book/entity/DetailVO.dart';
import 'package:json_annotation/json_annotation.dart';

part 'VoiceDetail.g.dart';

@JsonSerializable()
class VoiceDetail {
  String author;
  String bookDesc;
  String cover;
  List<DetailVO> chapters;
  String title;
  VoiceDetail(
      this.author, this.bookDesc, this.chapters, this.title, this.cover);
  factory VoiceDetail.fromJson(Map<String, dynamic> json) =>
      _$VoiceDetailFromJson(json);

  Map<String, dynamic> toJson() => _$VoiceDetailToJson(this);

}
