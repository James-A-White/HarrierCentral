// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'usage_data_new_events.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UdNewEventsModel _$UdNewEventsModelFromJson(Map<String, dynamic> json) =>
    _UdNewEventsModel(
      kennelName: json['kennelName'] as String,
      kennelShortName: json['kennelShortName'] as String,
      kennelLogo: json['kennelLogo'] as String,
      eventName: json['eventName'] as String,
      minutesAgoUpdated: (json['minutesAgoUpdated'] as num).toInt(),
      minutesAgoCreated: (json['minutesAgoCreated'] as num).toInt(),
      minutesUntilRun: (json['minutesUntilRun'] as num).toInt(),
      activityLastDay: (json['activityLastDay'] as num).toInt(),
      publicEventId: json['publicEventId'] as String,
    );

Map<String, dynamic> _$UdNewEventsModelToJson(_UdNewEventsModel instance) =>
    <String, dynamic>{
      'kennelName': instance.kennelName,
      'kennelShortName': instance.kennelShortName,
      'kennelLogo': instance.kennelLogo,
      'eventName': instance.eventName,
      'minutesAgoUpdated': instance.minutesAgoUpdated,
      'minutesAgoCreated': instance.minutesAgoCreated,
      'minutesUntilRun': instance.minutesUntilRun,
      'activityLastDay': instance.activityLastDay,
      'publicEventId': instance.publicEventId,
    };
