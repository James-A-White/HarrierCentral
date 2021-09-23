// @dart=2.11
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'countries_service.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CountriesModel _$CountriesModelFromJson(Map<String, dynamic> json) {
  return CountriesModel(
    countryId: json['countryId'] as String,
    countryCode: json['countryCode'] as String,
    latitude: json['latitude'] as num,
    longitude: json['longitude'] as num,
    countryName: json['countryName'] as String,
    continentCode: json['continentCode'] as String,
    flagFile: json['flagFile'] as String,
    currencyCode: json['currencyCode'] as String,
    primaryCultureCode: json['primaryCultureCode'] as String,
    showRegion: json['showRegion'] as int,
    currencySymbol: json['currencySymbol'] as String,
    digitsAfterDecimal: json['digitsAfterDecimal'] as int,
    distancePreference: json['distancePreference'] as int,
    removed: json['removed'] as int,
    updatedAt: json['updatedAt'] == null ? null : DateTime.parse(json['updatedAt'] as String),
  );
}

Map<String, dynamic> _$CountriesModelToJson(CountriesModel instance) => <String, dynamic>{
      'countryId': instance.countryId,
      'countryCode': instance.countryCode,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'countryName': instance.countryName,
      'continentCode': instance.continentCode,
      'flagFile': instance.flagFile,
      'currencyCode': instance.currencyCode,
      'primaryCultureCode': instance.primaryCultureCode,
      'showRegion': instance.showRegion,
      'currencySymbol': instance.currencySymbol,
      'digitsAfterDecimal': instance.digitsAfterDecimal,
      'distancePreference': instance.distancePreference,
      'removed': instance.removed,
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };
