// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kennel_hashers_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_KennelHashersModel _$KennelHashersModelFromJson(Map<String, dynamic> json) =>
    _KennelHashersModel(
      publicHasherId: json['publicHasherId'] as String,
      publicKennelId: json['publicKennelId'] as String,
      eMail: json['eMail'] as String,
      photo: json['photo'] as String,
      inviteCode: json['inviteCode'] as String,
      isHomeKennel: json['isHomeKennel'] as String,
      isFollowing: json['isFollowing'] as String,
      isMember: json['isMember'] as String,
      status: json['status'] as String,
      notifications: json['notifications'] as String,
      emailAlerts: json['emailAlerts'] as String,
      historicHaring: (json['historicHaring'] as num).toInt(),
      historicTotalRuns: (json['historicTotalRuns'] as num).toInt(),
      hcHaringCount: (json['hcHaringCount'] as num).toInt(),
      hcTotalRunCount: (json['hcTotalRunCount'] as num).toInt(),
      historicCountsAreEstimates: json['historicCountsAreEstimates'] as String,
      kennelCredit: json['kennelCredit'] as num,
      discountAmount: json['discountAmount'] as num,
      discountPercent: (json['discountPercent'] as num).toInt(),
      hashCredit: json['hashCredit'] as num,
      hashName: json['hashName'] as String?,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      displayName: json['displayName'] as String?,
      lastLoginDateTime: json['lastLoginDateTime'] == null
          ? null
          : DateTime.parse(json['lastLoginDateTime'] as String),
      dateOfLastRun: json['dateOfLastRun'] == null
          ? null
          : DateTime.parse(json['dateOfLastRun'] as String),
      membershipExpirationDate: json['membershipExpirationDate'] == null
          ? null
          : DateTime.parse(json['membershipExpirationDate'] as String),
      discountDescription: json['discountDescription'] as String?,
      atLastEvent: json['atLastEvent'] as String?,
      atSecondToLastEvent: json['atSecondToLastEvent'] as String?,
      lastEventDate: json['lastEventDate'] == null
          ? null
          : DateTime.parse(json['lastEventDate'] as String),
      nextEventDate: json['nextEventDate'] == null
          ? null
          : DateTime.parse(json['nextEventDate'] as String),
      secondToLastEventDate: json['secondToLastEventDate'] == null
          ? null
          : DateTime.parse(json['secondToLastEventDate'] as String),
      nextEventNumber: json['nextEventNumber'] as String?,
    );

Map<String, dynamic> _$KennelHashersModelToJson(_KennelHashersModel instance) =>
    <String, dynamic>{
      'publicHasherId': instance.publicHasherId,
      'publicKennelId': instance.publicKennelId,
      'eMail': instance.eMail,
      'photo': instance.photo,
      'inviteCode': instance.inviteCode,
      'isHomeKennel': instance.isHomeKennel,
      'isFollowing': instance.isFollowing,
      'isMember': instance.isMember,
      'status': instance.status,
      'notifications': instance.notifications,
      'emailAlerts': instance.emailAlerts,
      'historicHaring': instance.historicHaring,
      'historicTotalRuns': instance.historicTotalRuns,
      'hcHaringCount': instance.hcHaringCount,
      'hcTotalRunCount': instance.hcTotalRunCount,
      'historicCountsAreEstimates': instance.historicCountsAreEstimates,
      'kennelCredit': instance.kennelCredit,
      'discountAmount': instance.discountAmount,
      'discountPercent': instance.discountPercent,
      'hashCredit': instance.hashCredit,
      'hashName': instance.hashName,
      'firstName': instance.firstName,
      'lastName': instance.lastName,
      'displayName': instance.displayName,
      'lastLoginDateTime': instance.lastLoginDateTime?.toIso8601String(),
      'dateOfLastRun': instance.dateOfLastRun?.toIso8601String(),
      'membershipExpirationDate':
          instance.membershipExpirationDate?.toIso8601String(),
      'discountDescription': instance.discountDescription,
      'atLastEvent': instance.atLastEvent,
      'atSecondToLastEvent': instance.atSecondToLastEvent,
      'lastEventDate': instance.lastEventDate?.toIso8601String(),
      'nextEventDate': instance.nextEventDate?.toIso8601String(),
      'secondToLastEventDate':
          instance.secondToLastEventDate?.toIso8601String(),
      'nextEventNumber': instance.nextEventNumber,
    };
