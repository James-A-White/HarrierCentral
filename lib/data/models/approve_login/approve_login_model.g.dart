// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'approve_login_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$_ApproveLoginModel _$$_ApproveLoginModelFromJson(Map<String, dynamic> json) =>
    _$_ApproveLoginModel(
      apiVersion: json['apiVersion'] as String?,
      approvalCode: json['approvalCode'] as int?,
      loginMessage: json['loginMessage'] as String?,
      loginMessageTitle: json['loginMessageTitle'] as String?,
      serverStatusCode: json['serverStatusCode'] as int?,
      messageEndDate: json['messageEndDate'] == null
          ? null
          : DateTime.parse(json['messageEndDate'] as String),
      messageDisplayType: json['messageDisplayType'] as int?,
      iosDownloadLink: json['iosDownloadLink'] as String?,
      androidDownloadLink: json['androidDownloadLink'] as String?,
      imageRootUrl: json['imageRootUrl'] as String?,
      isBetaTester: json['isBetaTester'] as int?,
      email: json['email'] as String?,
      homeKennelId: json['homeKennelId'] as String?,
      thirdPartyForceTokenRefresh: json['thirdPartyForceTokenRefresh'] == null
          ? null
          : DateTime.parse(json['thirdPartyForceTokenRefresh'] as String),
    );

Map<String, dynamic> _$$_ApproveLoginModelToJson(
        _$_ApproveLoginModel instance) =>
    <String, dynamic>{
      'apiVersion': instance.apiVersion,
      'approvalCode': instance.approvalCode,
      'loginMessage': instance.loginMessage,
      'loginMessageTitle': instance.loginMessageTitle,
      'serverStatusCode': instance.serverStatusCode,
      'messageEndDate': instance.messageEndDate?.toIso8601String(),
      'messageDisplayType': instance.messageDisplayType,
      'iosDownloadLink': instance.iosDownloadLink,
      'androidDownloadLink': instance.androidDownloadLink,
      'imageRootUrl': instance.imageRootUrl,
      'isBetaTester': instance.isBetaTester,
      'email': instance.email,
      'homeKennelId': instance.homeKennelId,
      'thirdPartyForceTokenRefresh':
          instance.thirdPartyForceTokenRefresh?.toIso8601String(),
    };
