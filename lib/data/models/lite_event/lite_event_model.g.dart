// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lite_event_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LiteEventModel _$LiteEventModelFromJson(Map<String, dynamic> json) =>
    _LiteEventModel(
      eventId: json['eventId'] as String,
      isVisible: (json['isVisible'] as num?)?.toInt() ?? 1,
      isCountedRun: (json['isCountedRun'] as num?)?.toInt() ?? 1,
      absoluteEventNumber: (json['absoluteEventNumber'] as num?)?.toInt(),
      externalIntegrationId: json['externalIntegrationId'] as String?,
      eventName: json['eventName'] as String,
      eventNumber: (json['eventNumber'] as num).toInt(),
      eventStartDatetime: DateTime.parse(json['eventStartDatetime'] as String),
      eventInboundIntegrationId: (json['eventInboundIntegrationId'] as num?)
          ?.toInt(),
      appAccessFlags: (json['appAccessFlags'] as num?)?.toInt() ?? 0,
      canEditRunAttendance:
          (json['canEditRunAttendance'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$LiteEventModelToJson(_LiteEventModel instance) =>
    <String, dynamic>{
      'eventId': instance.eventId,
      'isVisible': instance.isVisible,
      'isCountedRun': instance.isCountedRun,
      'absoluteEventNumber': instance.absoluteEventNumber,
      'externalIntegrationId': instance.externalIntegrationId,
      'eventName': instance.eventName,
      'eventNumber': instance.eventNumber,
      'eventStartDatetime': instance.eventStartDatetime.toIso8601String(),
      'eventInboundIntegrationId': instance.eventInboundIntegrationId,
      'appAccessFlags': instance.appAccessFlags,
      'canEditRunAttendance': instance.canEditRunAttendance,
    };
