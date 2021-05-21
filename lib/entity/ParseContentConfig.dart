import 'package:json_annotation/json_annotation.dart';

part 'ParseContentConfig.g.dart';

@JsonSerializable()
class ParseContentConfig {
  String domain;
  String encode;
  String documentId;
  ParseContentConfig(this.domain, this.encode, this.documentId);

  factory ParseContentConfig.fromJson(Map<String, dynamic> json) => _$ParseContentConfigFromJson(json);

  Map<String, dynamic> toJson() => _$ParseContentConfigToJson(this);
}
