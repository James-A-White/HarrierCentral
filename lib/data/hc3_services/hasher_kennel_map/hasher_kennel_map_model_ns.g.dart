// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hasher_kennel_map_model_ns.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_HasherKennelMapModel _$HasherKennelMapModelFromJson(
  Map<String, dynamic> json,
) => _HasherKennelMapModel(
  hkmId: json['hkmId'] as String,
  userId: json['userId'] as String,
  kennelId: json['kennelId'] as String,
  following: (json['following'] as num).toInt(),
  isMember: (json['isMember'] as num).toInt(),
  isHomeKennel: (json['isHomeKennel'] as num).toInt(),
  kennelNotificationPreference: (json['kennelNotificationPreference'] as num)
      .toInt(),
  kennelEmailAlertPreference: (json['kennelEmailAlertPreference'] as num)
      .toInt(),
  authorizedDeviceList: json['authorizedDeviceList'] as String?,
  authorizedDeviceCount: (json['authorizedDeviceCount'] as num?)?.toInt(),
  userRoleFlags: (json['userRoleFlags'] as num).toInt(),
  appAccessFlags: (json['appAccessFlags'] as num).toInt(),
  hcTotalRunCount: (json['hcTotalRunCount'] as num).toInt(),
  hcHaringCount: (json['hcHaringCount'] as num).toInt(),
  historicalTotalRunCount: (json['historicalTotalRunCount'] as num).toInt(),
  historicalHaringCount: (json['historicalHaringCount'] as num).toInt(),
  historicalCountIsEstimate: (json['historicalCountIsEstimate'] as num).toInt(),
  kennelCredit: (json['kennelCredit'] as num).toDouble(),
  discountAmount: (json['discountAmount'] as num).toDouble(),
  discountPercent: (json['discountPercent'] as num).toInt(),
  discountDescription: json['discountDescription'] as String,
  dateOfLastRun: json['dateOfLastRun'] == null
      ? null
      : DateTime.parse(json['dateOfLastRun'] as String),
  membershipExpirationDate: json['membershipExpirationDate'] == null
      ? null
      : DateTime.parse(json['membershipExpirationDate'] as String),
  memberSince: json['memberSince'] == null
      ? null
      : DateTime.parse(json['memberSince'] as String),
  isKennelFollowing: (json['isKennelFollowing'] as num?)?.toInt(),
  mismanagementRoles: (json['mismanagementRoles'] as num).toInt(),
  kennelUserPhoto: json['kennelUserPhoto'] as String?,
  kennelHashName: json['kennelHashName'] as String?,
  updatedAt: json['updatedAt'] == null
      ? null
      : DateTime.parse(json['updatedAt'] as String),
  removed: (json['removed'] as num?)?.toInt(),
);

Map<String, dynamic> _$HasherKennelMapModelToJson(
  _HasherKennelMapModel instance,
) => <String, dynamic>{
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
  'kennelCredit': instance.kennelCredit,
  'discountAmount': instance.discountAmount,
  'discountPercent': instance.discountPercent,
  'discountDescription': instance.discountDescription,
  'dateOfLastRun': instance.dateOfLastRun?.toIso8601String(),
  'membershipExpirationDate': instance.membershipExpirationDate
      ?.toIso8601String(),
  'memberSince': instance.memberSince?.toIso8601String(),
  'isKennelFollowing': instance.isKennelFollowing,
  'mismanagementRoles': instance.mismanagementRoles,
  'kennelUserPhoto': instance.kennelUserPhoto,
  'kennelHashName': instance.kennelHashName,
  'updatedAt': instance.updatedAt?.toIso8601String(),
  'removed': instance.removed,
};
