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
    mismanagementRoleFlags: json['mismanagementRoleFlags'] as int,
    userRoleFlags: json['userRoleFlags'] as int,
    appAccessFlags: json['appAccessFlags'] as int,
    currentPackRunCount: json['currentPackRunCount'] as int,
    currentHaringCount: json['currentHaringCount'] as int,
    historicalPackRunCount: json['historicalPackRunCount'] as int,
    historicalHaringCount: json['historicalHaringCount'] as int,
    historicalCountIsEstimate: json['historicalCountIsEstimate'] as int,
    dateOfLastRun: DateTime.parse(json['dateOfLastRun'] as String),
    membershipExpirationDate:
        DateTime.parse(json['membershipExpirationDate'] as String),
    memberSince: DateTime.parse(json['memberSince'] as String),
    isKennelFollowing: json['isKennelFollowing'] as int,
    mismanagementRoles: json['mismanagementRoles'] as int,
    removed: json['removed'] as int,
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );
}

Map<String, dynamic> _$HasherKennelMapModelToJson(
        HasherKennelMapModel instance) =>
    <String, dynamic>{
      'hkmId': instance.hkmId,
      'userId': instance.userId,
      'kennelId': instance.kennelId,
      'following': instance.following,
      'isMember': instance.isMember,
      'isHomeKennel': instance.isHomeKennel,
      'kennelNotificationPreference': instance.kennelNotificationPreference,
      'kennelEmailAlertPreference': instance.kennelEmailAlertPreference,
      'mismanagementRoleFlags': instance.mismanagementRoleFlags,
      'userRoleFlags': instance.userRoleFlags,
      'appAccessFlags': instance.appAccessFlags,
      'currentPackRunCount': instance.currentPackRunCount,
      'currentHaringCount': instance.currentHaringCount,
      'historicalPackRunCount': instance.historicalPackRunCount,
      'historicalHaringCount': instance.historicalHaringCount,
      'historicalCountIsEstimate': instance.historicalCountIsEstimate,
      'dateOfLastRun': instance.dateOfLastRun.toIso8601String(),
      'membershipExpirationDate':
          instance.membershipExpirationDate.toIso8601String(),
      'memberSince': instance.memberSince.toIso8601String(),
      'isKennelFollowing': instance.isKennelFollowing,
      'mismanagementRoles': instance.mismanagementRoles,
      'updatedAt': instance.updatedAt.toIso8601String(),
      'removed': instance.removed,
    };
