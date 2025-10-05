// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cities_model_ns.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CitiesModel _$CitiesModelFromJson(Map<String, dynamic> json) => _CitiesModel(
  cityId: json['cityId'] as String,
  cityName: json['cityName'] as String,
  citySearchTags: json['citySearchTags'] as String?,
  regionId: json['regionId'] as String,
  latitude: (json['latitude'] as num).toDouble(),
  longitude: (json['longitude'] as num).toDouble(),
  cityAscii: json['cityAscii'] as String,
  ianaTimeZone: json['ianaTimeZone'] as String,
  flagFile: json['flagFile'] as String?,
  removed: (json['removed'] as num?)?.toInt(),
  updatedAt:
      json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
);

Map<String, dynamic> _$CitiesModelToJson(_CitiesModel instance) =>
    <String, dynamic>{
      'cityId': instance.cityId,
      'cityName': instance.cityName,
      'citySearchTags': instance.citySearchTags,
      'regionId': instance.regionId,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'cityAscii': instance.cityAscii,
      'ianaTimeZone': instance.ianaTimeZone,
      'flagFile': instance.flagFile,
      'removed': instance.removed,
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };
