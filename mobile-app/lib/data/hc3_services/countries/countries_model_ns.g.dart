// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'countries_model_ns.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CountriesModel _$CountriesModelFromJson(Map<String, dynamic> json) =>
    _CountriesModel(
      countryId: json['countryId'] as String,
      countryCode: json['countryCode'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      countryName: json['countryName'] as String,
      countrySearchTags: json['countrySearchTags'] as String?,
      continentCode: json['continentCode'] as String,
      flagFile: json['flagFile'] as String?,
      currencyCode: json['currencyCode'] as String,
      primaryCultureCode: json['primaryCultureCode'] as String,
      showRegion: (json['showRegion'] as num).toInt(),
      currencySymbol: json['currencySymbol'] as String?,
      digitsAfterDecimal: (json['digitsAfterDecimal'] as num?)?.toInt(),
      distancePreference: (json['distancePreference'] as num?)?.toInt(),
      removed: (json['removed'] as num?)?.toInt(),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$CountriesModelToJson(_CountriesModel instance) =>
    <String, dynamic>{
      'countryId': instance.countryId,
      'countryCode': instance.countryCode,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'countryName': instance.countryName,
      'countrySearchTags': instance.countrySearchTags,
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
