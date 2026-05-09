// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_event_location.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UserEventLocation _$UserEventLocationFromJson(Map<String, dynamic> json) =>
    _UserEventLocation(
      ts: json['ts'] as String,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      acc: (json['acc'] as num).toDouble(),
      alt: (json['alt'] as num).toDouble(),
    );

Map<String, dynamic> _$UserEventLocationToJson(_UserEventLocation instance) =>
    <String, dynamic>{
      'ts': instance.ts,
      'lat': instance.lat,
      'lng': instance.lng,
      'acc': instance.acc,
      'alt': instance.alt,
    };
