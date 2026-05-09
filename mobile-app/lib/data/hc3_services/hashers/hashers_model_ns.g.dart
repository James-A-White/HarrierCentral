// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hashers_model_ns.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_HashersModel _$HashersModelFromJson(Map<String, dynamic> json) =>
    _HashersModel(
      hasherId: json['hasherId'] as String,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      dispName: json['dispName'] as String,
      hashName: json['hashName'] as String?,
      photo: json['photo'] as String?,
      dispPref: (json['dispPref'] as num).toInt(),
      includeInGlobalHashDirectory:
          (json['includeInGlobalHashDirectory'] as num).toInt(),
      removed: (json['removed'] as num?)?.toInt(),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
      homeKennelId: json['homeKennelId'] as String?,
    );

Map<String, dynamic> _$HashersModelToJson(_HashersModel instance) =>
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
      'homeKennelId': instance.homeKennelId,
    };
