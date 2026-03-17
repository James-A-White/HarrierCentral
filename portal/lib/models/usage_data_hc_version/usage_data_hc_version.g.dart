// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'usage_data_hc_version.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UdHcVersion _$UdHcVersionFromJson(Map<String, dynamic> json) => _UdHcVersion(
      versionNum: json['versionNum'] as String,
      buildNum: json['buildNum'] as String,
      isiPhone: (json['isiPhone'] as num).toInt(),
      isNotiPhone: (json['isNotiPhone'] as num).toInt(),
    );

Map<String, dynamic> _$UdHcVersionToJson(_UdHcVersion instance) =>
    <String, dynamic>{
      'versionNum': instance.versionNum,
      'buildNum': instance.buildNum,
      'isiPhone': instance.isiPhone,
      'isNotiPhone': instance.isNotiPhone,
    };
