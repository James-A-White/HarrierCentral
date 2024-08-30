// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hasher_event_map_model_ns.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$HasherEventMapModelImpl _$$HasherEventMapModelImplFromJson(
        Map<String, dynamic> json) =>
    _$HasherEventMapModelImpl(
      hemId: json['hemId'] as String,
      userId: json['userId'] as String,
      eventId: json['eventId'] as String,
      hasherOwnEventId: json['hasherOwnEventId'] as String?,
      userStartEvent: json['userStartEvent'] as String?,
      userEndEvent: json['userEndEvent'] as String?,
      rsvpState: (json['rsvpState'] as num).toInt(),
      attendenceState: (json['attendenceState'] as num).toInt(),
      isHare: (json['isHare'] as num).toInt(),
      eventNotificationPreference:
          (json['eventNotificationPreference'] as num?)?.toInt(),
      eventEmailAlertPreference:
          (json['eventEmailAlertPreference'] as num?)?.toInt(),
      totalHaring: (json['totalHaring'] as num?)?.toInt(),
      totalHaringThisKennel: (json['totalHaringThisKennel'] as num?)?.toInt(),
      totalRuns: (json['totalRuns'] as num?)?.toInt(),
      totalRunsThisKennel: (json['totalRunsThisKennel'] as num?)?.toInt(),
      eventCountOverride: (json['eventCountOverride'] as num?)?.toInt(),
      virginVisitorType: (json['virginVisitorType'] as num).toInt(),
      displayName: json['displayName'] as String?,
      email: json['email'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      hemEventName: json['hemEventName'] as String?,
      hemEventNumber: (json['hemEventNumber'] as num?)?.toInt(),
      hemEventStartDatetime:
          DateTime.parse(json['hemEventStartDatetime'] as String),
      hemCanEditRunAttendence:
          (json['hemCanEditRunAttendence'] as num?)?.toInt(),
      hemEventKennelId: json['hemEventKennelId'] as String?,
      hemEventIsCountedAndVisible:
          (json['hemEventIsCountedAndVisible'] as num?)?.toInt(),
      hemKennelUserPhoto: json['hemKennelUserPhoto'] as String?,
      hemKennelHashName: json['hemKennelHashName'] as String?,
      removed: (json['removed'] as num?)?.toInt(),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$HasherEventMapModelImplToJson(
        _$HasherEventMapModelImpl instance) =>
    <String, dynamic>{
      'hemId': instance.hemId,
      'userId': instance.userId,
      'eventId': instance.eventId,
      'hasherOwnEventId': instance.hasherOwnEventId,
      'userStartEvent': instance.userStartEvent,
      'userEndEvent': instance.userEndEvent,
      'rsvpState': instance.rsvpState,
      'attendenceState': instance.attendenceState,
      'isHare': instance.isHare,
      'eventNotificationPreference': instance.eventNotificationPreference,
      'eventEmailAlertPreference': instance.eventEmailAlertPreference,
      'totalHaring': instance.totalHaring,
      'totalHaringThisKennel': instance.totalHaringThisKennel,
      'totalRuns': instance.totalRuns,
      'totalRunsThisKennel': instance.totalRunsThisKennel,
      'eventCountOverride': instance.eventCountOverride,
      'virginVisitorType': instance.virginVisitorType,
      'displayName': instance.displayName,
      'email': instance.email,
      'phoneNumber': instance.phoneNumber,
      'hemEventName': instance.hemEventName,
      'hemEventNumber': instance.hemEventNumber,
      'hemEventStartDatetime': instance.hemEventStartDatetime.toIso8601String(),
      'hemCanEditRunAttendence': instance.hemCanEditRunAttendence,
      'hemEventKennelId': instance.hemEventKennelId,
      'hemEventIsCountedAndVisible': instance.hemEventIsCountedAndVisible,
      'hemKennelUserPhoto': instance.hemKennelUserPhoto,
      'hemKennelHashName': instance.hemKennelHashName,
      'removed': instance.removed,
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };
