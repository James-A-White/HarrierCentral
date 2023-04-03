// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kennel_member_results_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$_KennelMemberResultsModel _$$_KennelMemberResultsModelFromJson(
        Map<String, dynamic> json) =>
    _$_KennelMemberResultsModel(
      hasherId: json['hasherId'] as String,
      dispName: json['dispName'] as String,
      nameForSort: json['nameForSort'] as String,
      photo: json['photo'] as String?,
      following: json['following'] as int? ?? 0,
      kennelId: json['kennelId'] as String,
      dateOfLastRun: json['dateOfLastRun'] == null
          ? null
          : DateTime.parse(json['dateOfLastRun'] as String),
      hcTotalRunCount: json['hcTotalRunCount'] as int? ?? 0,
      hcHaringCount: json['hcHaringCount'] as int? ?? 0,
      historicalTotalRunCount: json['historicalTotalRunCount'] as int? ?? 0,
      historicalHaringCount: json['historicalHaringCount'] as int? ?? 0,
      kennelEmailAlertPreference:
          json['kennelEmailAlertPreference'] as int? ?? 0,
      membershipExpirationDate: json['membershipExpirationDate'] == null
          ? null
          : DateTime.parse(json['membershipExpirationDate'] as String),
      memberSince: json['memberSince'] == null
          ? null
          : DateTime.parse(json['memberSince'] as String),
      membershipDurationInMonths:
          json['membershipDurationInMonths'] as int? ?? 6,
      appAccessFlags: json['appAccessFlags'] as int? ?? 0,
      mismanagementRoles: json['mismanagementRoles'] as int? ?? 0,
      kennelShortName: json['kennelShortName'] as String?,
      kennelCredit: (json['kennelCredit'] as num?)?.toDouble() ?? 0.0,
      memberFollowingStatus: json['memberFollowingStatus'] as int? ?? 0,
    );

Map<String, dynamic> _$$_KennelMemberResultsModelToJson(
        _$_KennelMemberResultsModel instance) =>
    <String, dynamic>{
      'hasherId': instance.hasherId,
      'dispName': instance.dispName,
      'nameForSort': instance.nameForSort,
      'photo': instance.photo,
      'following': instance.following,
      'kennelId': instance.kennelId,
      'dateOfLastRun': instance.dateOfLastRun?.toIso8601String(),
      'hcTotalRunCount': instance.hcTotalRunCount,
      'hcHaringCount': instance.hcHaringCount,
      'historicalTotalRunCount': instance.historicalTotalRunCount,
      'historicalHaringCount': instance.historicalHaringCount,
      'kennelEmailAlertPreference': instance.kennelEmailAlertPreference,
      'membershipExpirationDate':
          instance.membershipExpirationDate?.toIso8601String(),
      'memberSince': instance.memberSince?.toIso8601String(),
      'membershipDurationInMonths': instance.membershipDurationInMonths,
      'appAccessFlags': instance.appAccessFlags,
      'mismanagementRoles': instance.mismanagementRoles,
      'kennelShortName': instance.kennelShortName,
      'kennelCredit': instance.kennelCredit,
      'memberFollowingStatus': instance.memberFollowingStatus,
    };
