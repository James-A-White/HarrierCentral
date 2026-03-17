// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'new_hasher_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_NewHasherModel _$NewHasherModelFromJson(Map<String, dynamic> json) =>
    _NewHasherModel(
      publicHasherId: json['publicHasherId'] as String?,
      publicKennelId: json['publicKennelId'] as String?,
      hashName: json['hashName'] as String?,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      eMail: json['eMail'] as String?,
      addHasherStatus: json['addHasherStatus'] as String?,
      historicTotalRuns: (json['historicTotalRuns'] as num?)?.toInt() ?? 0,
      historicHaring: (json['historicHaring'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$NewHasherModelToJson(_NewHasherModel instance) =>
    <String, dynamic>{
      'publicHasherId': instance.publicHasherId,
      'publicKennelId': instance.publicKennelId,
      'hashName': instance.hashName,
      'firstName': instance.firstName,
      'lastName': instance.lastName,
      'eMail': instance.eMail,
      'addHasherStatus': instance.addHasherStatus,
      'historicTotalRuns': instance.historicTotalRuns,
      'historicHaring': instance.historicHaring,
    };
