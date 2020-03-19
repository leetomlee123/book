import 'package:json_annotation/json_annotation.dart';
part 'BookVotec.g.dart';
@JsonSerializable()
class BookVotec {
  int BookId;
  double Score;
  int TotalScore;
  int VoterCount;

  BookVotec(this.BookId, this.Score, this.TotalScore, this.VoterCount);

  factory BookVotec.fromJson(Map<String, dynamic> json) => _$BookVotecFromJson(json);

  Map<String, dynamic> toJson() => _$BookVotecToJson(this);
}
