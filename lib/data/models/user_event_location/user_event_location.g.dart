// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_event_location.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UserEventLocation _$UserEventLocationFromJson(Map<String, dynamic> json) =>
    _UserEventLocation(
      paddedTimestamp: json['paddedTimestamp'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
    );

Map<String, dynamic> _$UserEventLocationToJson(_UserEventLocation instance) =>
    <String, dynamic>{
      'paddedTimestamp': instance.paddedTimestamp,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
    };
