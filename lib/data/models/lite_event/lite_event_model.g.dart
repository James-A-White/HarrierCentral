// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lite_event_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$_LiteEventModel _$$_LiteEventModelFromJson(Map<String, dynamic> json) =>
    _$_LiteEventModel(
      eventId: json['eventId'] as String,
      isVisible: json['isVisible'] as int,
      isCountedRun: json['isCountedRun'] as int,
      absoluteEventNumber: json['absoluteEventNumber'] as int?,
      externalIntegrationId: json['externalIntegrationId'] as String?,
      eventName: json['eventName'] as String,
      eventNumber: json['eventNumber'] as int,
      eventStartDatetime: json['eventStartDatetime'] == null
          ? null
          : DateTime.parse(json['eventStartDatetime'] as String),
      eventInboundIntegrationId: json['eventInboundIntegrationId'] as int?,
      appAccessFlags: json['appAccessFlags'] as int,
      canEditRunAttendance: json['canEditRunAttendance'] as int,
    );

Map<String, dynamic> _$$_LiteEventModelToJson(_$_LiteEventModel instance) =>
    <String, dynamic>{
      'eventId': instance.eventId,
      'isVisible': instance.isVisible,
      'isCountedRun': instance.isCountedRun,
      'absoluteEventNumber': instance.absoluteEventNumber,
      'externalIntegrationId': instance.externalIntegrationId,
      'eventName': instance.eventName,
      'eventNumber': instance.eventNumber,
      'eventStartDatetime': instance.eventStartDatetime?.toIso8601String(),
      'eventInboundIntegrationId': instance.eventInboundIntegrationId,
      'appAccessFlags': instance.appAccessFlags,
      'canEditRunAttendance': instance.canEditRunAttendance,
    };
