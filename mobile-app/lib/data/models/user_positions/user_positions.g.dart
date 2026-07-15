// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_positions.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UserPositionsPayload _$UserPositionsPayloadFromJson(
  Map<String, dynamic> json,
) => _UserPositionsPayload(
  eventId: json['eventId'] as String,
  latestServerTimestampMs: json['latestServerTimestampMs'] as String?,
  trailTypesConfigJson: json['trailTypesConfigJson'] as String?,
  trimStartMs: (json['trimStartMs'] as num?)?.toInt(),
  trimEndMs: (json['trimEndMs'] as num?)?.toInt(),
  users: (json['users'] as List<dynamic>)
      .map((e) => UserTrack.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$UserPositionsPayloadToJson(
  _UserPositionsPayload instance,
) => <String, dynamic>{
  'eventId': instance.eventId,
  'latestServerTimestampMs': instance.latestServerTimestampMs,
  'trailTypesConfigJson': instance.trailTypesConfigJson,
  'trimStartMs': instance.trimStartMs,
  'trimEndMs': instance.trimEndMs,
  'users': instance.users,
};

_UserTrack _$UserTrackFromJson(Map<String, dynamic> json) => _UserTrack(
  id: json['id'] as String,
  positions: (json['positions'] as List<dynamic>)
      .map((e) => TrackPoint.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$UserTrackToJson(_UserTrack instance) =>
    <String, dynamic>{'id': instance.id, 'positions': instance.positions};

_TrackPoint _$TrackPointFromJson(Map<String, dynamic> json) => _TrackPoint(
  lat: (json['lat'] as num).toDouble(),
  lng: (json['lng'] as num).toDouble(),
  acc: (json['acc'] as num).toDouble(),
  alt: (json['alt'] as num?)?.toDouble(),
  timestampMs: (json['timestampMs'] as num).toInt(),
  type: json['type'] as String?,
);

Map<String, dynamic> _$TrackPointToJson(_TrackPoint instance) =>
    <String, dynamic>{
      'lat': instance.lat,
      'lng': instance.lng,
      'acc': instance.acc,
      'alt': instance.alt,
      'timestampMs': instance.timestampMs,
      'type': instance.type,
    };
