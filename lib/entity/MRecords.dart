import 'package:json_annotation/json_annotation.dart';

part 'MRecords.g.dart';

@JsonSerializable()
class MRecords {
  String cover;
  String name;
  String cid;
  String cname;
  String mcids;

  MRecords(this.cover, this.name, this.cid, this.cname,this.mcids);

  factory MRecords.fromJson(Map<String, dynamic> json) =>
      _$MRecordsFromJson(json);

  Map<String, dynamic> toJson() => _$MRecordsToJson(this);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is MRecords &&
              runtimeType == other.runtimeType &&
              cover == other.cover &&
              name == other.name &&
              cid == other.cid &&
              cname == other.cname &&
              mcids == other.mcids;

  @override
  int get hashCode =>
      cover.hashCode ^
      name.hashCode ^
      cid.hashCode ^
      cname.hashCode ^
      mcids.hashCode;




}
