// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'regions_model_ns.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$RegionsModelImpl _$$RegionsModelImplFromJson(Map<String, dynamic> json) =>
    _$RegionsModelImpl(
      regionId: json['regionId'] as String,
      regionName: json['regionName'] as String,
      regionSearchTags: json['regionSearchTags'] as String?,
      regionAbbreviation: json['regionAbbreviation'] as String?,
      countryId: json['countryId'] as String,
      flagFile: json['flagFile'] as String?,
      removed: (json['removed'] as num?)?.toInt(),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$RegionsModelImplToJson(_$RegionsModelImpl instance) =>
    <String, dynamic>{
      'regionId': instance.regionId,
      'regionName': instance.regionName,
      'regionSearchTags': instance.regionSearchTags,
      'regionAbbreviation': instance.regionAbbreviation,
      'countryId': instance.countryId,
      'flagFile': instance.flagFile,
      'removed': instance.removed,
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };
