// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'usage_data_recent_user.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UdRecentUserModel _$UdRecentUserModelFromJson(Map<String, dynamic> json) =>
    _UdRecentUserModel(
      userId: json['userId'] as String? ?? '',
      userName: json['userName'] as String,
      realName: json['realName'] as String? ?? '',
      photo: json['photo'] as String,
      lastLoginDate: DateTime.parse(json['lastLoginDate'] as String),
      minutesSinceLastLogin: (json['minutesSinceLastLogin'] as num).toInt(),
      loginCount: (json['loginCount'] as num).toInt(),
      isIphone: (json['isIphone'] as num).toInt(),
      systemVersion: json['systemVersion'] as String,
      kennelName: json['kennelName'] as String,
      kennelShortName: json['kennelShortName'] as String,
      hcVersion: json['hcVersion'] as String,
      highlightPhoneVersion: (json['highlightPhoneVersion'] as num).toInt(),
      highlightHcVersion: (json['highlightHcVersion'] as num).toInt(),
    );

Map<String, dynamic> _$UdRecentUserModelToJson(_UdRecentUserModel instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'userName': instance.userName,
      'realName': instance.realName,
      'photo': instance.photo,
      'lastLoginDate': instance.lastLoginDate.toIso8601String(),
      'minutesSinceLastLogin': instance.minutesSinceLastLogin,
      'loginCount': instance.loginCount,
      'isIphone': instance.isIphone,
      'systemVersion': instance.systemVersion,
      'kennelName': instance.kennelName,
      'kennelShortName': instance.kennelShortName,
      'hcVersion': instance.hcVersion,
      'highlightPhoneVersion': instance.highlightPhoneVersion,
      'highlightHcVersion': instance.highlightHcVersion,
    };
