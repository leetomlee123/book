// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'BookVotec.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BookVotec _$BookVotecFromJson(Map<String, dynamic> json) {
  return BookVotec(
      json['BookId'] as int? ?? 0,
      (json['Score'] as num?)?.toDouble() ?? 0,
      json['TotalScore'] as int? ?? 0,
      json['VoterCount'] as int? ?? 0);
}

Map<String, dynamic> _$BookVotecToJson(BookVotec instance) => <String, dynamic>{
      'BookId': instance.BookId,
      'Score': instance.Score,
      'TotalScore': instance.TotalScore,
      'VoterCount': instance.VoterCount
    };
