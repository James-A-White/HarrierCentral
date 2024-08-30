// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'leaderboard_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$LeaderboardModelImpl _$$LeaderboardModelImplFromJson(
        Map<String, dynamic> json) =>
    _$LeaderboardModelImpl(
      displayName: json['displayName'] as String,
      totalRunCount: (json['totalRunCount'] as num).toInt(),
      totalHaringCount: (json['totalHaringCount'] as num).toInt(),
      ytdTotalRunCount: (json['ytdTotalRunCount'] as num).toInt(),
      ytdHaringCount: (json['ytdHaringCount'] as num).toInt(),
      rollingYearTotalRunCount:
          (json['rollingYearTotalRunCount'] as num).toInt(),
      rollingYearHaringCount: (json['rollingYearHaringCount'] as num).toInt(),
      kennelId: json['kennelId'] as String,
      homeKennelId: json['homeKennelId'] as String?,
      hasherId: json['hasherId'] as String,
      kennelCountTotal: (json['kennelCountTotal'] as num).toInt(),
      kennelCountYtd: (json['kennelCountYtd'] as num).toInt(),
      kennelCountRollingYear: (json['kennelCountRollingYear'] as num).toInt(),
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
