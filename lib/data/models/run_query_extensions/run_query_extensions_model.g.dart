// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'run_query_extensions_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$_RunQueryExtensionsModel _$$_RunQueryExtensionsModelFromJson(
        Map<String, dynamic> json) =>
    _$_RunQueryExtensionsModel(
      daysUntilEvent: json['daysUntilEvent'] as int? ?? 0,
      appAccessFlags: json['appAccessFlags'] as int? ?? 0,
      digitsAfterDecimal: json['digitsAfterDecimal'] as int? ?? 2,
      currencySymbol: json['currencySymbol'] as String? ?? r'$^',
      rsvpState: json['rsvpState'] as int? ?? 0,
      attendenceState: json['attendenceState'] as int? ?? 0,
      isPaid: json['isPaid'] as int? ?? 0,
      isHare: json['isHare'] as int? ?? 0,
      isMember: json['isMember'] as int? ?? 0,
      following: json['following'] as int? ?? 0,
      notificationPreference: json['notificationPreference'] as int? ?? 0,
      emailAlertPreference: json['emailAlertPreference'] as int? ?? 0,
      distanceUnitsPref: json['distanceUnitsPref'] as int? ?? 0,
      searchRunsText: json['searchRunsText'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      distToEvent: (json['distToEvent'] as num?)?.toDouble(),
      isMapAndDistanceValid: json['isMapAndDistanceValid'] as int? ?? 0,
      runClassification: json['runClassification'] as int? ?? 3,
    );

Map<String, dynamic> _$$_RunQueryExtensionsModelToJson(
        _$_RunQueryExtensionsModel instance) =>
    <String, dynamic>{
      'daysUntilEvent': instance.daysUntilEvent,
      'appAccessFlags': instance.appAccessFlags,
      'digitsAfterDecimal': instance.digitsAfterDecimal,
      'currencySymbol': instance.currencySymbol,
      'rsvpState': instance.rsvpState,
      'attendenceState': instance.attendenceState,
      'isPaid': instance.isPaid,
      'isHare': instance.isHare,
      'isMember': instance.isMember,
      'following': instance.following,
      'notificationPreference': instance.notificationPreference,
      'emailAlertPreference': instance.emailAlertPreference,
      'distanceUnitsPref': instance.distanceUnitsPref,
      'searchRunsText': instance.searchRunsText,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'distToEvent': instance.distToEvent,
      'isMapAndDistanceValid': instance.isMapAndDistanceValid,
      'runClassification': instance.runClassification,
    };
