// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'run_list_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RunListModel _$RunListModelFromJson(Map<String, dynamic> json) =>
    _RunListModel(
      publicEventId: json['publicEventId'] as String,
      eventStartDatetime: DateTime.parse(json['eventStartDatetime'] as String),
      publicKennelId: json['publicKennelId'] as String,
      isVisible: (json['isVisible'] as num).toInt(),
      isCountedRun: (json['isCountedRun'] as num).toInt(),
      eventGeographicScope: (json['eventGeographicScope'] as num).toInt(),
      eventNumber: (json['eventNumber'] as num).toInt(),
      eventName: json['eventName'] as String,
      kennelShortName: json['kennelShortName'] as String,
      kennelLogo: json['kennelLogo'] as String,
      daysUntilEvent: (json['daysUntilEvent'] as num).toInt(),
      searchText: json['searchText'] as String,
      kennelName: json['kennelName'] as String,
      eventCityAndCountry: json['eventCityAndCountry'] as String,
      resolvableLocation: json['resolvableLocation'] as String,
      eventChatMessageCount: (json['eventChatMessageCount'] as num).toInt(),
      locationOneLineDesc: json['locationOneLineDesc'] as String?,
      hares: json['hares'] as String?,
      syncLat: (json['syncLat'] as num?)?.toDouble(),
      syncLong: (json['syncLong'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$RunListModelToJson(_RunListModel instance) =>
    <String, dynamic>{
      'publicEventId': instance.publicEventId,
      'eventStartDatetime': instance.eventStartDatetime.toIso8601String(),
      'publicKennelId': instance.publicKennelId,
      'isVisible': instance.isVisible,
      'isCountedRun': instance.isCountedRun,
      'eventGeographicScope': instance.eventGeographicScope,
      'eventNumber': instance.eventNumber,
      'eventName': instance.eventName,
      'kennelShortName': instance.kennelShortName,
      'kennelLogo': instance.kennelLogo,
      'daysUntilEvent': instance.daysUntilEvent,
      'searchText': instance.searchText,
      'kennelName': instance.kennelName,
      'eventCityAndCountry': instance.eventCityAndCountry,
      'resolvableLocation': instance.resolvableLocation,
      'eventChatMessageCount': instance.eventChatMessageCount,
      'locationOneLineDesc': instance.locationOneLineDesc,
      'hares': instance.hares,
      'syncLat': instance.syncLat,
      'syncLong': instance.syncLong,
    };
