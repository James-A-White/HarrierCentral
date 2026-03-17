// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'usage_data_login_history.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UdLoginHistoryModel _$UdLoginHistoryModelFromJson(Map<String, dynamic> json) =>
    _UdLoginHistoryModel(
      loginDate: DateTime.parse(json['loginDate'] as String),
      hcVersion: json['hcVersion'] as String,
      systemVersion: json['systemVersion'] as String,
      isIphone: (json['isIphone'] as num).toInt(),
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      locationName: json['locationName'] as String? ?? '',
    );

Map<String, dynamic> _$UdLoginHistoryModelToJson(
        _UdLoginHistoryModel instance) =>
    <String, dynamic>{
      'loginDate': instance.loginDate.toIso8601String(),
      'hcVersion': instance.hcVersion,
      'systemVersion': instance.systemVersion,
      'isIphone': instance.isIphone,
      'latitude': instance.latitude,
      'longitude': instance.longitude,
      'locationName': instance.locationName,
    };
