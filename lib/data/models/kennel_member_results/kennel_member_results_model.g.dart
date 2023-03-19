// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kennel_member_results_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$_KennelMemberResultsModel _$$_KennelMemberResultsModelFromJson(
        Map<String, dynamic> json) =>
    _$_KennelMemberResultsModel(
      hasherId: json['hasherId'] as String,
      dispName: json['dispName'] as String?,
      nameForSort: json['nameForSort'] as String?,
      photo: json['photo'] as String?,
      following: json['following'] as int,
      kennelId: json['kennelId'] as String,
      dateOfLastRun: json['dateOfLastRun'] == null
          ? null
          : DateTime.parse(json['dateOfLastRun'] as String),
      hcTotalRunCount: json['hcTotalRunCount'] as int,
      hcHaringCount: json['hcHaringCount'] as int,
      historicalTotalRunCount: json['historicalTotalRunCount'] as int,
      historicalHaringCount: json['historicalHaringCount'] as int,
      kennelEmailAlertPreference: json['kennelEmailAlertPreference'] as int?,
      membershipExpirationDate:
          DateTime.parse(json['membershipExpirationDate'] as String),
      memberSince: DateTime.parse(json['memberSince'] as String),
      membershipDurationInMonths: json['membershipDurationInMonths'] as int,
      appAccessFlags: json['appAccessFlags'] as int?,
      mismanagementRoles: json['mismanagementRoles'] as int?,
      kennelShortName: json['kennelShortName'] as String?,
      kennelCredit: json['kennelCredit'] as num?,
      memberFollowingStatus: json['memberFollowingStatus'] as int?,
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
          instance.membershipExpirationDate.toIso8601String(),
      'memberSince': instance.memberSince.toIso8601String(),
      'membershipDurationInMonths': instance.membershipDurationInMonths,
      'appAccessFlags': instance.appAccessFlags,
      'mismanagementRoles': instance.mismanagementRoles,
      'kennelShortName': instance.kennelShortName,
      'kennelCredit': instance.kennelCredit,
      'memberFollowingStatus': instance.memberFollowingStatus,
    };
