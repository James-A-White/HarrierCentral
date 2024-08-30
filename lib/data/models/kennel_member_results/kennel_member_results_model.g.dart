// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kennel_member_results_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$KennelMemberResultsModelImpl _$$KennelMemberResultsModelImplFromJson(
        Map<String, dynamic> json) =>
    _$KennelMemberResultsModelImpl(
      hasherId: json['hasherId'] as String,
      dispName: json['dispName'] as String,
      nameForSort: json['nameForSort'] as String,
      photo: json['photo'] as String?,
      following: (json['following'] as num?)?.toInt() ?? 0,
      kennelId: json['kennelId'] as String,
      dateOfLastRun: json['dateOfLastRun'] == null
          ? null
          : DateTime.parse(json['dateOfLastRun'] as String),
      hcTotalRunCount: (json['hcTotalRunCount'] as num?)?.toInt() ?? 0,
      hcHaringCount: (json['hcHaringCount'] as num?)?.toInt() ?? 0,
      historicalTotalRunCount:
          (json['historicalTotalRunCount'] as num?)?.toInt() ?? 0,
      historicalHaringCount:
          (json['historicalHaringCount'] as num?)?.toInt() ?? 0,
      kennelEmailAlertPreference:
          (json['kennelEmailAlertPreference'] as num?)?.toInt() ?? 0,
      membershipExpirationDate: json['membershipExpirationDate'] == null
          ? null
          : DateTime.parse(json['membershipExpirationDate'] as String),
      memberSince: json['memberSince'] == null
          ? null
          : DateTime.parse(json['memberSince'] as String),
      membershipDurationInMonths:
          (json['membershipDurationInMonths'] as num?)?.toInt() ?? 6,
      appAccessFlags: (json['appAccessFlags'] as num?)?.toInt() ?? 0,
      mismanagementRoles: (json['mismanagementRoles'] as num?)?.toInt() ?? 0,
      kennelShortName: json['kennelShortName'] as String?,
      kennelCredit: (json['kennelCredit'] as num?)?.toDouble() ?? 0.0,
      memberFollowingStatus:
          (json['memberFollowingStatus'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$$KennelMemberResultsModelImplToJson(
        _$KennelMemberResultsModelImpl instance) =>
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
