// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hashers_model_ns.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$HashersModelImpl _$$HashersModelImplFromJson(Map<String, dynamic> json) =>
    _$HashersModelImpl(
      hasherId: json['hasherId'] as String,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      dispName: json['dispName'] as String,
      hashName: json['hashName'] as String?,
      photo: json['photo'] as String?,
      dispPref: json['dispPref'] as int,
      includeInGlobalHashDirectory: json['includeInGlobalHashDirectory'] as int,
      removed: json['removed'] as int?,
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$HashersModelImplToJson(_$HashersModelImpl instance) =>
    <String, dynamic>{
      'hasherId': instance.hasherId,
      'firstName': instance.firstName,
      'lastName': instance.lastName,
      'dispName': instance.dispName,
      'hashName': instance.hashName,
      'photo': instance.photo,
      'dispPref': instance.dispPref,
      'includeInGlobalHashDirectory': instance.includeInGlobalHashDirectory,
      'removed': instance.removed,
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };
