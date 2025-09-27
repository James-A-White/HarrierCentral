// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'run_query_extensions_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_RunQueryExtensionsModel _$RunQueryExtensionsModelFromJson(
  Map<String, dynamic> json,
) => _RunQueryExtensionsModel(
  nowJulian: json['nowJulian'] as num? ?? 0,
  eventJulian: json['eventJulian'] as num? ?? 0,
  appAccessFlags: (json['appAccessFlags'] as num?)?.toInt() ?? 0,
  digitsAfterDecimal: (json['digitsAfterDecimal'] as num?)?.toInt() ?? 2,
  currencySymbol: json['currencySymbol'] as String? ?? r'$^',
  rsvpState: (json['rsvpState'] as num?)?.toInt() ?? 0,
  attendenceState: (json['attendenceState'] as num?)?.toInt() ?? 0,
  isPaid: (json['isPaid'] as num?)?.toInt() ?? 0,
  isHare: (json['isHare'] as num?)?.toInt() ?? 0,
  isMember: (json['isMember'] as num?)?.toInt() ?? 0,
  following: (json['following'] as num?)?.toInt() ?? 0,
  notificationPreference:
      (json['notificationPreference'] as num?)?.toInt() ?? 0,
  emailAlertPreference: (json['emailAlertPreference'] as num?)?.toInt() ?? 0,
  distanceUnitsPref: (json['distanceUnitsPref'] as num?)?.toInt() ?? 0,
  searchRunsText: json['searchRunsText'] as String? ?? '',
  latitude: (json['latitude'] as num?)?.toDouble(),
  longitude: (json['longitude'] as num?)?.toDouble(),
  evtLat: (json['evtLat'] as num?)?.toDouble(),
  evtLon: (json['evtLon'] as num?)?.toDouble(),
  distToEvent: (json['distToEvent'] as num?)?.toDouble(),
  isMapAndDistanceValid: (json['isMapAndDistanceValid'] as num?)?.toInt() ?? 0,
  runClassification: (json['runClassification'] as num?)?.toInt() ?? 3,
  userFriendlyLocation: json['userFriendlyLocation'] as String?,
);

Map<String, dynamic> _$RunQueryExtensionsModelToJson(
  _RunQueryExtensionsModel instance,
) => <String, dynamic>{
  'nowJulian': instance.nowJulian,
  'eventJulian': instance.eventJulian,
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
  'evtLat': instance.evtLat,
  'evtLon': instance.evtLon,
  'distToEvent': instance.distToEvent,
  'isMapAndDistanceValid': instance.isMapAndDistanceValid,
  'runClassification': instance.runClassification,
  'userFriendlyLocation': instance.userFriendlyLocation,
};
