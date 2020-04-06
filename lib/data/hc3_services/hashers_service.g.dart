// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hashers_service.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

HashersModel _$HashersModelFromJson(Map<String, dynamic> json) {
  return HashersModel(
    hasherId: json['hasherId'] as String,
    homeKennelId: json['homeKennelId'] as String,
    firstName: json['firstName'] as String,
    lastName: json['lastName'] as String,
    dispName: json['dispName'] as String,
    hashName: json['hashName'] as String,
    email: json['email'] as String,
    photo: json['photo'] as String,
    dispPref: json['dispPref'] as int,
    resetCode: json['resetCode'] as String,
    qrCode: json['qrCode'] as String,
    includeInGlobalHashDirectory: json['includeInGlobalHashDirectory'] as int,
    preferences: json['preferences'] as int,
    removed: json['removed'] as int,
    updatedAt: json['updatedAt'] == null
        ? null
        : DateTime.parse(json['updatedAt'] as String),
  );
}

Map<String, dynamic> _$HashersModelToJson(HashersModel instance) =>
    <String, dynamic>{
      'hasherId': instance.hasherId,
      'homeKennelId': instance.homeKennelId,
      'firstName': instance.firstName,
      'lastName': instance.lastName,
      'dispName': instance.dispName,
      'hashName': instance.hashName,
      'email': instance.email,
      'photo': instance.photo,
      'dispPref': instance.dispPref,
      'resetCode': instance.resetCode,
      'qrCode': instance.qrCode,
      'includeInGlobalHashDirectory': instance.includeInGlobalHashDirectory,
      'preferences': instance.preferences,
      'removed': instance.removed,
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };
