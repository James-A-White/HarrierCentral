// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'approve_login_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ApproveLoginModel _$ApproveLoginModelFromJson(Map<String, dynamic> json) =>
    _ApproveLoginModel(
      apiVersion: json['apiVersion'] as String?,
      approvalCode: (json['approvalCode'] as num?)?.toInt(),
      loginMessage: json['loginMessage'] as String?,
      loginMessageTitle: json['loginMessageTitle'] as String?,
      serverStatusCode: (json['serverStatusCode'] as num?)?.toInt(),
      messageEndDate:
          json['messageEndDate'] == null
              ? null
              : DateTime.parse(json['messageEndDate'] as String),
      messageDisplayType: (json['messageDisplayType'] as num?)?.toInt(),
      iosDownloadLink: json['iosDownloadLink'] as String?,
      androidDownloadLink: json['androidDownloadLink'] as String?,
      imageRootUrl: json['imageRootUrl'] as String?,
      isBetaTester: (json['isBetaTester'] as num?)?.toInt(),
      email: json['email'] as String?,
      homeKennelId: json['homeKennelId'] as String?,
      thirdPartyForceTokenRefresh:
          json['thirdPartyForceTokenRefresh'] == null
              ? null
              : DateTime.parse(json['thirdPartyForceTokenRefresh'] as String),
      splashSequenceRootName: json['splashSequenceRootName'] as String?,
    );

Map<String, dynamic> _$ApproveLoginModelToJson(_ApproveLoginModel instance) =>
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
      'splashSequenceRootName': instance.splashSequenceRootName,
    };
