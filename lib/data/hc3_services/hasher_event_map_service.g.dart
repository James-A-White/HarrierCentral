// @dart=2.11
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hasher_event_map_service.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HasherEventMapModel _$HasherEventMapModelFromJson(Map<String, dynamic> json) {
  return HasherEventMapModel(
    hemId: json['hemId'] as String,
    userId: json['userId'] as String,
    eventId: json['eventId'] as String,
    hasherOwnEventId: json['hasherOwnEventId'] as String,
    userStartEvent: json['userStartEvent'] as String,
    userEndEvent: json['userEndEvent'] as String,
    rsvpState: json['rsvpState'] as int,
    attendenceState: json['attendenceState'] as int,
    isHare: json['isHare'] as int,
    eventNotificationPreference: json['eventNotificationPreference'] as int,
    eventEmailAlertPreference: json['eventEmailAlertPreference'] as int,
    totalHaring: json['totalHaring'] as int,
    totalHaringThisKennel: json['totalHaringThisKennel'] as int,
    totalRuns: json['totalRuns'] as int,
    totalRunsThisKennel: json['totalRunsThisKennel'] as int,
    eventCountOverride: json['eventCountOverride'] as num,
    virginVisitorType: json['virginVisitorType'] as num,
    displayName: json['displayName'] as String,
    email: json['email'] as String,
    phoneNumber: json['phoneNumber'] as String,
    removed: json['removed'] as int,
    hemEventName: json['hemEventName'] as String,
    hemEventNumber: json['hemEventNumber'] as int,
    hemEventStartDatetime: json['hemEventStartDatetime'] == null ? null : DateTime.parse(json['hemEventStartDatetime'] as String),
    hemEventIsCountedAndVisible: json['hemEventIsCountedAndVisible'] as int,
    hemCanEditRunAttendence: json['hemCanEditRunAttendence'] as num,
    hemEventKennelId: json['hemEventKennelId'] as String,
    updatedAt: json['updatedAt'] == null ? null : DateTime.parse(json['updatedAt'] as String),
  );
}

Map<String, dynamic> _$HasherEventMapModelToJson(HasherEventMapModel instance) => <String, dynamic>{
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
      'totalHaring': instance.totalHaring,
      'totalHaringThisKennel': instance.totalHaringThisKennel,
      'totalRuns': instance.totalRuns,
      'totalRunsThisKennel': instance.totalRunsThisKennel,
      'eventEmailAlertPreference': instance.eventEmailAlertPreference,
      'eventCountOverride': instance.eventCountOverride,
      'virginVisitorType': instance.virginVisitorType,
      'displayName': instance.displayName,
      'email': instance.email,
      'phoneNumber': instance.phoneNumber,
      'hemEventName': instance.hemEventName,
      'hemEventNumber': instance.hemEventNumber,
      'hemEventStartDatetime': instance.hemEventStartDatetime?.toIso8601String(),
      'hemCanEditRunAttendence': instance.hemCanEditRunAttendence,
      'hemEventKennelId': instance.hemEventKennelId,
      'hemEventIsCountedAndVisible': instance.hemEventIsCountedAndVisible,
      'removed': instance.removed,
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };
