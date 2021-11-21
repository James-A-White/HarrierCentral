// @dart=2.11
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hasher_kennel_map_service.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HasherKennelMapModel _$HasherKennelMapModelFromJson(Map<String, dynamic> json) {
  return HasherKennelMapModel(
    hkmId: json['hkmId'] as String,
    userId: json['userId'] as String,
    kennelId: json['kennelId'] as String,
    following: json['following'] as int,
    isMember: json['isMember'] as int,
    isHomeKennel: json['isHomeKennel'] as int,
    kennelNotificationPreference: json['kennelNotificationPreference'] as int,
    kennelEmailAlertPreference: json['kennelEmailAlertPreference'] as int,
    authorizedDeviceList: json['authorizedDeviceList'] as String,
    authorizedDeviceCount: json['authorizedDeviceCount'] as int,
    userRoleFlags: json['userRoleFlags'] as int,
    appAccessFlags: json['appAccessFlags'] as int,
    hcTotalRunCount: json['hcTotalRunCount'] as int,
    hcHaringCount: json['hcHaringCount'] as int,
    historicalTotalRunCount: json['historicalTotalRunCount'] as int,
    historicalHaringCount: json['historicalHaringCount'] as int,
    historicalCountIsEstimate: json['historicalCountIsEstimate'] as int,
    dateOfLastRun: json['dateOfLastRun'] == null ? null : DateTime.parse(json['dateOfLastRun'] as String),
    membershipExpirationDate: json['membershipExpirationDate'] == null ? null : DateTime.parse(json['membershipExpirationDate'] as String),
    memberSince: json['memberSince'] == null ? null : DateTime.parse(json['memberSince'] as String),
    isKennelFollowing: json['isKennelFollowing'] as int,
    mismanagementRoles: json['mismanagementRoles'] as int,
    removed: json['removed'] as int,
    updatedAt: json['updatedAt'] == null ? null : DateTime.parse(json['updatedAt'] as String),
  );
}

Map<String, dynamic> _$HasherKennelMapModelToJson(HasherKennelMapModel instance) => <String, dynamic>{
      'hkmId': instance.hkmId,
      'userId': instance.userId,
      'kennelId': instance.kennelId,
      'following': instance.following,
      'isMember': instance.isMember,
      'isHomeKennel': instance.isHomeKennel,
      'kennelNotificationPreference': instance.kennelNotificationPreference,
      'kennelEmailAlertPreference': instance.kennelEmailAlertPreference,
      'authorizedDeviceList': instance.authorizedDeviceList,
      'authorizedDeviceCount': instance.authorizedDeviceCount,
      'userRoleFlags': instance.userRoleFlags,
      'appAccessFlags': instance.appAccessFlags,
      'hcTotalRunCount': instance.hcTotalRunCount,
      'hcHaringCount': instance.hcHaringCount,
      'historicalTotalRunCount': instance.historicalTotalRunCount,
      'historicalHaringCount': instance.historicalHaringCount,
      'historicalCountIsEstimate': instance.historicalCountIsEstimate,
      'dateOfLastRun': instance.dateOfLastRun?.toIso8601String(),
      'membershipExpirationDate': instance.membershipExpirationDate?.toIso8601String(),
      'memberSince': instance.memberSince?.toIso8601String(),
      'isKennelFollowing': instance.isKennelFollowing,
      'mismanagementRoles': instance.mismanagementRoles,
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'removed': instance.removed,
    };
