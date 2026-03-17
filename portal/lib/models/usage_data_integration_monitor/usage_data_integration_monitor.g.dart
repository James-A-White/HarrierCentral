// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'usage_data_integration_monitor.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UdIntegrationMonitorModel _$UdIntegrationMonitorModelFromJson(
        Map<String, dynamic> json) =>
    _UdIntegrationMonitorModel(
      integrationId: (json['integrationId'] as num).toInt(),
      recordsRead: (json['recordsRead'] as num).toInt(),
      recordsWritten: (json['recordsWritten'] as num).toInt(),
      recordsFailedInfo: json['recordsFailedInfo'] as String,
      errorCount: (json['errorCount'] as num).toInt(),
      errorInfo: json['errorInfo'] as String,
      kennelsSucceeded: (json['kennelsSucceeded'] as num).toInt(),
      kennelsSucceededInfo: json['kennelsSucceededInfo'] as String,
      kennelsFailed: (json['kennelsFailed'] as num).toInt(),
      kennelsFailedInfo: json['kennelsFailedInfo'] as String,
      integrationAbbreviation: json['integrationAbbreviation'] as String,
      integrationEnabled: (json['integrationEnabled'] as num).toInt(),
      interval: (json['interval'] as num).toInt(),
      endedAt: DateTime.parse(json['endedAt'] as String),
      minutesAgo: (json['minutesAgo'] as num).toInt(),
      futureRunCount: (json['futureRunCount'] as num).toInt(),
    );

Map<String, dynamic> _$UdIntegrationMonitorModelToJson(
        _UdIntegrationMonitorModel instance) =>
    <String, dynamic>{
      'integrationId': instance.integrationId,
      'recordsRead': instance.recordsRead,
      'recordsWritten': instance.recordsWritten,
      'recordsFailedInfo': instance.recordsFailedInfo,
      'errorCount': instance.errorCount,
      'errorInfo': instance.errorInfo,
      'kennelsSucceeded': instance.kennelsSucceeded,
      'kennelsSucceededInfo': instance.kennelsSucceededInfo,
      'kennelsFailed': instance.kennelsFailed,
      'kennelsFailedInfo': instance.kennelsFailedInfo,
      'integrationAbbreviation': instance.integrationAbbreviation,
      'integrationEnabled': instance.integrationEnabled,
      'interval': instance.interval,
      'endedAt': instance.endedAt.toIso8601String(),
      'minutesAgo': instance.minutesAgo,
      'futureRunCount': instance.futureRunCount,
    };
