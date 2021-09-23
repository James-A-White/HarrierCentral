// @dart=2.11
// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'regions_service.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RegionsModel _$RegionsModelFromJson(Map<String, dynamic> json) {
  return RegionsModel(
    regionId: json['regionId'] as String,
    regionName: json['regionName'] as String,
    countryId: json['countryId'] as String,
    flagFile: json['flagFile'] as String,
    removed: json['removed'] as int,
    updatedAt: json['updatedAt'] == null ? null : DateTime.parse(json['updatedAt'] as String),
  );
}

Map<String, dynamic> _$RegionsModelToJson(RegionsModel instance) => <String, dynamic>{
      'regionId': instance.regionId,
      'regionName': instance.regionName,
      'countryId': instance.countryId,
      'flagFile': instance.flagFile,
      'removed': instance.removed,
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };
