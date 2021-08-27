// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'kennels_service.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

KennelsModel _$KennelsModelFromJson(Map<String, dynamic> json) {
  return KennelsModel(
    kennelId: json['kennelId'] as String,
    cityId: json['cityId'] as String,
    regionId: json['regionId'] as String,
    countryId: json['countryId'] as String,
    kennelName: json['kennelName'] as String,
    kennelShortName: json['kennelShortName'] as String,
    kennelDescription: json['kennelDescription'] as String,
    kennelLogo: json['kennelLogo'] as String,
    kennelPinColor: json['kennelPinColor'] as int,
    kennelCoverPhoto: json['kennelCoverPhoto'] as String,
    kennelWebsiteUrl: json['kennelWebsiteUrl'] as String,
    defaultEventCurrencyType: json['defaultEventCurrencyType'] as String,
    kennelStatus: json['kennelStatus'] as int,
    canEditRunAttendence: json['canEditRunAttendence'] as int,
    allowNegativeCredit: json['allowNegativeCredit'] as int,
    allowSelfPayment: json['allowSelfPayment'] as int,
    kennelLatitude: json['kennelLatitude'] as num,
    kennelLongitude: json['kennelLongitude'] as num,
    defaultPriceForMembers: json['defaultPriceForMembers'] as num,
    defaultPriceForNonMembers: json['defaultPriceForNonMembers'] as num,
    membershipDurationInMonths: json['membershipDurationInMonths'] as int,
    defaultRunStartTime: json['defaultRunStartTime'] == null
        ? null
        : DateTime.parse(json['defaultRunStartTime'] as String),
    currencyCode: json['currencyCode'] as String,
    primaryCultureCode: json['primaryCultureCode'] as String,
    currencySymbol: json['currencySymbol'] as String,
    digitsAfterDecimal: json['digitsAfterDecimal'] as num,
    bankScheme: json['bankScheme'] as String,
    bankAccountNumber: json['bankAccountNumber'] as String,
    bankBic: json['bankBic'] as String,
    bankBeneficiary: json['bankBeneficiary'] as String,
    kennelPaymentScheme: json['kennelPaymentScheme'] as String,
    kennelPaymentUrl: json['kennelPaymentUrl'] as String,
    kennelPaymentUrlExpires: json['kennelPaymentUrlExpires'] == null
        ? null
        : DateTime.parse(json['kennelPaymentUrlExpires'] as String),
    kennelPaymentMemberSurcharge: json['kennelPaymentMemberSurcharge'] as num,
    kennelPaymentNonMemberSurcharge:
        json['kennelPaymentNonMemberSurcharge'] as num,
    kennelPaymentScheme2: json['kennelPaymentScheme2'] as String,
    kennelPaymentUrl2: json['kennelPaymentUrl2'] as String,
    kennelPaymentUrlExpires2: json['kennelPaymentUrlExpires2'] == null
        ? null
        : DateTime.parse(json['kennelPaymentUrlExpires2'] as String),
    kennelPaymentMemberSurcharge2: json['kennelPaymentMemberSurcharge2'] as num,
    kennelPaymentNonMemberSurcharge2:
        json['kennelPaymentNonMemberSurcharge2'] as num,
    kennelPaymentScheme3: json['kennelPaymentScheme3'] as String,
    kennelPaymentUrl3: json['kennelPaymentUrl3'] as String,
    kennelPaymentUrlExpires3: json['kennelPaymentUrlExpires3'] == null
        ? null
        : DateTime.parse(json['kennelPaymentUrlExpires3'] as String),
    kennelPaymentMemberSurcharge3: json['kennelPaymentMemberSurcharge3'] as num,
    kennelPaymentNonMemberSurcharge3:
        json['kennelPaymentNonMemberSurcharge3'] as num,
    runCountStartDate: json['runCountStartDate'] == null
        ? null
        : DateTime.parse(json['runCountStartDate'] as String),
    kennelMismanagementTeam: json['kennelMismanagementTeam'] as String,
    distancePreference: json['distancePreference'] as int,
    updatedAt: json['updatedAt'] == null
        ? null
        : DateTime.parse(json['updatedAt'] as String),
    removed: json['removed'] as int,
  );
}

Map<String, dynamic> _$KennelsModelToJson(KennelsModel instance) =>
    <String, dynamic>{
      'kennelId': instance.kennelId,
      'cityId': instance.cityId,
      'regionId': instance.regionId,
      'countryId': instance.countryId,
      'kennelName': instance.kennelName,
      'kennelShortName': instance.kennelShortName,
      'kennelDescription': instance.kennelDescription,
      'kennelLogo': instance.kennelLogo,
      'kennelPinColor': instance.kennelPinColor,
      'kennelCoverPhoto': instance.kennelCoverPhoto,
      'kennelWebsiteUrl': instance.kennelWebsiteUrl,
      'defaultEventCurrencyType': instance.defaultEventCurrencyType,
      'kennelStatus': instance.kennelStatus,
      'canEditRunAttendence': instance.canEditRunAttendence,
      'allowNegativeCredit': instance.allowNegativeCredit,
      'allowSelfPayment': instance.allowSelfPayment,
      'kennelLatitude': instance.kennelLatitude,
      'kennelLongitude': instance.kennelLongitude,
      'defaultPriceForMembers': instance.defaultPriceForMembers,
      'defaultPriceForNonMembers': instance.defaultPriceForNonMembers,
      'membershipDurationInMonths': instance.membershipDurationInMonths,
      'defaultRunStartTime': instance.defaultRunStartTime?.toIso8601String(),
      'currencyCode': instance.currencyCode,
      'primaryCultureCode': instance.primaryCultureCode,
      'currencySymbol': instance.currencySymbol,
      'digitsAfterDecimal': instance.digitsAfterDecimal,
      'bankScheme': instance.bankScheme,
      'bankAccountNumber': instance.bankAccountNumber,
      'bankBic': instance.bankBic,
      'bankBeneficiary': instance.bankBeneficiary,
      'kennelPaymentScheme': instance.kennelPaymentScheme,
      'kennelPaymentUrl': instance.kennelPaymentUrl,
      'kennelPaymentUrlExpires':
          instance.kennelPaymentUrlExpires?.toIso8601String(),
      'kennelPaymentMemberSurcharge': instance.kennelPaymentMemberSurcharge,
      'kennelPaymentNonMemberSurcharge':
          instance.kennelPaymentNonMemberSurcharge,
      'kennelPaymentScheme2': instance.kennelPaymentScheme2,
      'kennelPaymentUrl2': instance.kennelPaymentUrl2,
      'kennelPaymentUrlExpires2':
          instance.kennelPaymentUrlExpires2?.toIso8601String(),
      'kennelPaymentMemberSurcharge2': instance.kennelPaymentMemberSurcharge2,
      'kennelPaymentNonMemberSurcharge2':
          instance.kennelPaymentNonMemberSurcharge2,
      'kennelPaymentScheme3': instance.kennelPaymentScheme3,
      'kennelPaymentUrl3': instance.kennelPaymentUrl3,
      'kennelPaymentUrlExpires3':
          instance.kennelPaymentUrlExpires3?.toIso8601String(),
      'kennelPaymentMemberSurcharge3': instance.kennelPaymentMemberSurcharge3,
      'kennelPaymentNonMemberSurcharge3':
          instance.kennelPaymentNonMemberSurcharge3,
      'runCountStartDate': instance.runCountStartDate?.toIso8601String(),
      'kennelMismanagementTeam': instance.kennelMismanagementTeam,
      'distancePreference': instance.distancePreference,
      'updatedAt': instance.updatedAt?.toIso8601String(),
      'removed': instance.removed,
    };
