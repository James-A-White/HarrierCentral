// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'lite_event_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$LiteEventModelImpl _$$LiteEventModelImplFromJson(Map<String, dynamic> json) =>
    _$LiteEventModelImpl(
      eventId: json['eventId'] as String,
      isVisible: json['isVisible'] as int? ?? 1,
      isCountedRun: json['isCountedRun'] as int? ?? 1,
      absoluteEventNumber: json['absoluteEventNumber'] as int?,
      externalIntegrationId: json['externalIntegrationId'] as String?,
      eventName: json['eventName'] as String,
      eventNumber: json['eventNumber'] as int,
      eventStartDatetime: DateTime.parse(json['eventStartDatetime'] as String),
      eventInboundIntegrationId: json['eventInboundIntegrationId'] as int?,
      appAccessFlags: json['appAccessFlags'] as int? ?? 0,
      canEditRunAttendance: json['canEditRunAttendance'] as int? ?? 0,
    );

Map<String, dynamic> _$$LiteEventModelImplToJson(
        _$LiteEventModelImpl instance) =>
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
