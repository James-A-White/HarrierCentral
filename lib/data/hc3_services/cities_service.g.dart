// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cities_service.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CitiesModel _$CitiesModelFromJson(Map<String, dynamic> json) {
  return CitiesModel(
    cityId: json['cityId'] as String,
    cityName: json['cityName'] as String,
    regionId: json['regionId'] as String,
    latitude: json['latitude'] as num,
    longitude: json['longitude'] as num,
    cityAscii: json['cityAscii'] as String,
    flagFile: json['flagFile'] as String,
    removed: json['removed'] as int,
    updatedAt: DateTime.parse(json['updatedAt'] as String),
  );
}

Map<String, dynamic> _$CitiesModelToJson(CitiesModel instance) =>
    <String, dynamic>{
      'cityId': instance.cityId,
      'cityName': instance.cityName,
      'regionId': instance.regionId,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'cityAscii': instance.cityAscii,
      'flagFile': instance.flagFile,
      'removed': instance.removed,
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
