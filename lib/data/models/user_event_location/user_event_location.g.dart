// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_event_location.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UserEventLocation _$UserEventLocationFromJson(Map<String, dynamic> json) =>
    _UserEventLocation(
      timestamp: json['timestamp'] as String,
      lat: (json['lat'] as num).toDouble(),
      lng: (json['lng'] as num).toDouble(),
      accuracy: (json['accuracy'] as num).toDouble(),
    );

Map<String, dynamic> _$UserEventLocationToJson(_UserEventLocation instance) =>
    <String, dynamic>{
      'timestamp': instance.timestamp,
      'lat': instance.lat,
      'lng': instance.lng,
      'accuracy': instance.accuracy,
    };
