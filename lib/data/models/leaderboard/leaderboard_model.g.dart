// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'leaderboard_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$LeaderboardModelImpl _$$LeaderboardModelImplFromJson(
        Map<String, dynamic> json) =>
    _$LeaderboardModelImpl(
      displayName: json['displayName'] as String,
      totalRunCount: json['totalRunCount'] as int,
      totalHaringCount: json['totalHaringCount'] as int,
      ytdTotalRunCount: json['ytdTotalRunCount'] as int,
      ytdHaringCount: json['ytdHaringCount'] as int,
      rollingYearTotalRunCount: json['rollingYearTotalRunCount'] as int,
      rollingYearHaringCount: json['rollingYearHaringCount'] as int,
      kennelId: json['kennelId'] as String,
      homeKennelId: json['homeKennelId'] as String?,
      hasherId: json['hasherId'] as String,
      kennelCountTotal: json['kennelCountTotal'] as int,
      kennelCountYtd: json['kennelCountYtd'] as int,
      kennelCountRollingYear: json['kennelCountRollingYear'] as int,
      searchText: json['searchText'] as String?,
    );

Map<String, dynamic> _$$LeaderboardModelImplToJson(
        _$LeaderboardModelImpl instance) =>
    <String, dynamic>{
      'displayName': instance.displayName,
      'totalRunCount': instance.totalRunCount,
      'totalHaringCount': instance.totalHaringCount,
      'ytdTotalRunCount': instance.ytdTotalRunCount,
      'ytdHaringCount': instance.ytdHaringCount,
      'rollingYearTotalRunCount': instance.rollingYearTotalRunCount,
      'rollingYearHaringCount': instance.rollingYearHaringCount,
      'kennelId': instance.kennelId,
      'homeKennelId': instance.homeKennelId,
      'hasherId': instance.hasherId,
      'kennelCountTotal': instance.kennelCountTotal,
      'kennelCountYtd': instance.kennelCountYtd,
      'kennelCountRollingYear': instance.kennelCountRollingYear,
      'searchText': instance.searchText,
    };
