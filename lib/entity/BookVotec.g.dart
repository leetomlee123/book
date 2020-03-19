// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'BookVotec.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BookVotec _$BookVotecFromJson(Map<String, dynamic> json) {
  return BookVotec(json['BookId'] as int, (json['Score'] as num)?.toDouble(),
      json['TotalScore'] as int, json['VoterCount'] as int);
}

Map<String, dynamic> _$BookVotecToJson(BookVotec instance) => <String, dynamic>{
      'BookId': instance.BookId,
      'Score': instance.Score,
      'TotalScore': instance.TotalScore,
      'VoterCount': instance.VoterCount
    };
